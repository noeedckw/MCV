import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../utils/artist_name.dart';
import '../../providers/explorer_provider.dart';
import '../../utils/discogs_notes.dart';
import '../cover/cover_viewer_modal.dart';
import '../cover/cover_image.dart';
import '../shared/album_modal/discogs_format_utils.dart';
import '../shared/album_modal/edition_labels.dart';
import '../shared/album_modal/glass_modal_kit.dart';
import '../shared/album_modal/tracklist_section.dart';

Future<void> showExplorerAlbumDetailModal(
  BuildContext context, {
  required Map<String, dynamic> result,
}) {
  final provider = context.read<ExplorerProvider>();

  // loadDetailForResult résout à lui seul le bon id (master direct, ou
  // master_id extrait d'une release, ou fallback sur l'id de la release)
  // et lance checkCollectionStatus dessus une fois résolu — plus besoin
  // d'appeler loadMasterDetail/loadMasterVersions/checkCollectionStatus
  // séparément ici, ni de connaître à l'avance si `result` est un master
  // ou une release.
  provider.loadDetailForResult(result);
  // Hides the search bar / navbar for as long as this modal is up (see
  // ExplorerScreen and MainNavigationScreen, which watch this flag).
  provider.setDetailModalOpen(true);

  return showGlassModal(
    context: context,
    pageBuilder: (context) => ExplorerAlbumDetailModal(initialResult: result),
  ).whenComplete(() {
    // `whenComplete` fires as soon as the route is popped, which is BEFORE
    // the reverse (closing) transition has finished playing — the route
    // stays in the tree animating out for `kGlassModalTransitionDuration`
    // more. Clearing the provider's detail right away made the still-visible
    // modal rebuild with everything wiped (no tracklist/notes/versions), so
    // it visibly snapped down to a tiny stub right as it faded out. Waiting
    // for the transition to actually finish avoids that flash.
    Future.delayed(kGlassModalTransitionDuration, () {
      if (context.mounted) {
        final p = context.read<ExplorerProvider>();
        p.clearMasterDetail();
        p.setDetailModalOpen(false);
      }
    });
  });
}

class ExplorerAlbumDetailModal extends StatefulWidget {
  final Map<String, dynamic> initialResult;

  const ExplorerAlbumDetailModal({super.key, required this.initialResult});

  @override
  State<ExplorerAlbumDetailModal> createState() => _ExplorerAlbumDetailModalState();
}

class _ExplorerAlbumDetailModalState extends State<ExplorerAlbumDetailModal> {
  Map? _selectedVersion;
  bool _versionsExpanded = false;

  String get _artist {
    final title = widget.initialResult['title'] as String? ?? '';
    final raw = title.contains(' - ') ? title.split(' - ').first : title;
    return cleanArtistName(raw);
  }

  String get _album {
    final title = widget.initialResult['title'] as String? ?? '';
    return title.contains(' - ')
        ? title.split(' - ').sublist(1).join(' - ')
        : title;
  }

  /// L'id à utiliser pour toute opération de collection/wishlist : celui
  /// résolu par loadDetailForResult (master direct, ou master_id extrait
  /// d'une release). Tant qu'il n'est pas encore résolu (fenêtre très
  /// courte au tout premier frame), on retombe sur l'id brut du résultat —
  /// en pratique les actions de collection ne sont accessibles qu'une fois
  /// le detail chargé, donc ce fallback ne devrait jamais être exercé.
  int get _effectiveId {
    final resolved = context.read<ExplorerProvider>().effectiveMasterId;
    return resolved ?? widget.initialResult['id'] as int;
  }

  /// `widget.initialResult` avec `id` remplacé par l'id résolu — c'est ce
  /// map qu'il faut passer à toggleCollection/toggleWishlist/
  /// addToCollection, qui utilisent `result['id']` tel quel comme clé de
  /// dédup, sans jamais le re-résoudre elles-mêmes.
  Map<String, dynamic> get _normalizedResult => {
        ...widget.initialResult,
        'id': _effectiveId,
      };

  bool _isSameVersion(Map? a, Map b) {
    if (a == null) return false;
    final aid = a['id'];
    final bid = b['id'];
    if (aid != null && bid != null) return aid == bid;
    return identical(a, b);
  }

  void _toggleWishlist() {
    HapticFeedback.selectionClick();
    context.read<ExplorerProvider>().toggleWishlist(
          _normalizedResult,
          _selectedVersion,
        );
  }

  void _selectVersion(Map? version) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedVersion = version;
      _versionsExpanded = false;
    });

    final provider = context.read<ExplorerProvider>();
    if (version == null) {
      provider.clearReleaseDetail();
    } else {
      final releaseId = version['id'] as int?;
      if (releaseId != null) provider.loadReleaseDetail(releaseId);
    }

    // Re-check l'état collection/wishlist pour CETTE édition précisément —
    // sinon les boutons gardaient l'état de l'édition précédente (ou du
    // master générique) jusqu'à la prochaine ouverture de la modal.
    provider.checkCollectionStatus(_effectiveId, selectedVersion: version);
  }

  void _toggleVersions() =>
      setState(() => _versionsExpanded = !_versionsExpanded);

  // Toggles collection status on/off depending on the current state.
  // Doesn't close the modal anymore: the user can chain collection +
  // wishlist actions, or switch edition and toggle again, without having
  // to reopen it.
  void _toggleCollection() {
    HapticFeedback.mediumImpact();
    context.read<ExplorerProvider>().toggleCollection(
          _normalizedResult,
          _selectedVersion,
        );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExplorerProvider>();
    final detail = provider.masterDetail;
    final versions = (provider.masterVersions as List?) ?? const [];
    final isLoading = provider.isLoadingDetail || provider.isLoadingVersions;
    final error =
        provider.detailErrorMessage ?? provider.versionsErrorMessage;
    final isInCollection = provider.isInCollection;
    final isInWishlist = provider.isInWishlist;

    final masterCover = (detail?['images'] as List?)?.isNotEmpty == true
        ? detail!['images'][0]['uri'] as String?
        : widget.initialResult['cover_image'] as String?;

    // A specific pressing can have different artwork. Once the release
    // detail has loaded, prefer its image; while it's still loading, use
    // the version's own thumbnail from the versions list instead of the
    // master's cover, so it doesn't flash back and then swap again a
    // moment later.
    final releaseCover =
        (provider.releaseDetail?['images'] as List?)?.isNotEmpty == true
            ? provider.releaseDetail!['images'][0]['uri'] as String?
            : null;

    final cover = _selectedVersion != null
        ? (releaseCover ?? _selectedVersion!['thumb'] as String? ?? masterCover)
        : masterCover;

    final genres = (detail?['genres'] as List?)?.cast<String>() ?? const [];
    final styles = (detail?['styles'] as List?)?.cast<String>() ?? const [];

    // Comme la cover/le tracklist : priorité à l'édition précise
    // sélectionnée, sinon celle du résultat initial (recherche).
    final label = _selectedVersion != null
        ? formatLabelValue(_selectedVersion!['label'])
        : formatLabelValue(widget.initialResult['label']);

    final rawDate = _selectedVersion != null
        ? (provider.releaseDetail?['released']?.toString() ??
            _selectedVersion!['released']?.toString())
        : detail?['released']?.toString();

    final fallbackYear = _selectedVersion != null
        ? (validYear(provider.releaseDetail?['year']) ??
            validYear(_selectedVersion!['year']) ??
            validYear(detail?['year']))
        : validYear(detail?['year']);

    String? releaseDate;
    if (rawDate != null && rawDate.isNotEmpty) {
      try {
        releaseDate = DateFormat('d MMMM yyyy', 'en_US').format(
          DateTime.parse(rawDate),
        );
      } catch (_) {
        releaseDate = fallbackYear;
      }
    } else {
      releaseDate = fallbackYear;
    }
    final notes = cleanDiscogsNotes(detail?['notes'] as String?);

    // The tracklist of the chosen release takes priority over the master's,
    // since editions (deluxe, remaster, etc.) often have extra tracks.
    final masterTracklist = (detail?['tracklist'] as List?) ?? const [];
    final releaseTracklist = provider.releaseDetail?['tracklist'] as List?;
    final displayedTracklist = _selectedVersion != null
        ? (releaseTracklist ?? const [])
        : masterTracklist;
    final isTracklistSwitching =
        _selectedVersion != null && provider.isLoadingRelease;

    return GlassModalScaffold(
      child: isLoading
          ? const _LoadingState()
          : error != null
              ? _ErrorState(message: error)
              : _Content(
                  cover: cover,
                  artist: _artist,
                  album: _album,
                  year: releaseDate,
                  genres: genres,
                  styles: styles,
                  label: label,
                  notes: notes,
                  tracklist: displayedTracklist,
                  isTracklistSwitching: isTracklistSwitching,
                  versions: versions,
                  selectedVersion: _selectedVersion,
                  versionsExpanded: _versionsExpanded,
                  isSameVersion: _isSameVersion,
                  onToggleVersions: _toggleVersions,
                  onSelectVersion: _selectVersion,
                  onAdd: _toggleCollection,
                  isInCollection: isInCollection,
                  isInWishlist: isInWishlist,
                  onToggleWishlist: _toggleWishlist,
                ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(kGlassAccent),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .6),
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final String? cover;
  final String artist;
  final String album;
  final String? year;
  final List<String> genres;
  final List<String> styles;
  final String? label;
  final String? notes;
  final List tracklist;
  final bool isTracklistSwitching;
  final List versions;
  final Map? selectedVersion;
  final bool versionsExpanded;
  final bool Function(Map?, Map) isSameVersion;
  final VoidCallback onToggleVersions;
  final ValueChanged<Map?> onSelectVersion;
  final VoidCallback onAdd;
  final bool isInCollection;
  final bool isInWishlist;
  final VoidCallback onToggleWishlist;

  const _Content({
    required this.cover,
    required this.artist,
    required this.album,
    required this.year,
    required this.genres,
    required this.styles,
    required this.label,
    required this.notes,
    required this.tracklist,
    required this.isTracklistSwitching,
    required this.versions,
    required this.selectedVersion,
    required this.versionsExpanded,
    required this.isSameVersion,
    required this.onToggleVersions,
    required this.onSelectVersion,
    required this.onAdd,
    required this.isInCollection,
    required this.isInWishlist,
    required this.onToggleWishlist,
  });

  @override
  Widget build(BuildContext context) {
    final tracks = tracklist
        .map(
          (t) => TrackRowData(
            position: (t as Map)['position'] as String? ?? '',
            title: t['title'] as String? ?? '',
            duration: t['duration'] as String? ?? '',
          ),
        )
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Header: cover art + titles (chips en dessous, pleine largeur) ---
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ModalCoverThumbnail(
                    cover: CoverImage(networkUrl: cover),
                    onTap: () => showCoverViewer(
                      context,
                      cover: CoverImage(networkUrl: cover),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      // Reserves room for the close button (top-right,
                      // ~44px including its margin) so a long artist or
                      // album name wraps before it, instead of running
                      // underneath it.
                      padding: const EdgeInsets.only(right: 34),
                      child: FittedAlbumTitles(
                        artist: artist,
                        album: album,
                        year: year,
                      ),
                    ),
                  ),
                ],
              ),
              if (genres.isNotEmpty || styles.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...genres.map(ModalChip.new),
                    ...styles.map(ModalChip.new),
                  ],
                ),
              ],
              if (label != null && label!.isNotEmpty) ...[
                const SizedBox(height: 10),
                ModalLabelSection(label: label!),
              ],
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Divider(height: 1, color: Colors.white12),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TracklistSection(
                  tracks: tracks,
                  isSwitching: isTracklistSwitching,
                  switchKey: selectedVersion?['id'] ?? 'master',
                  emptyMessage: 'Tracklist unavailable for this edition.',
                ),
                const SizedBox(height: 22),
                if (notes != null && notes!.trim().isNotEmpty) ...[
                  const ModalSectionLabel('NOTES'),
                  const SizedBox(height: 10),
                  ModalNotesSection(notes: notes!.trim()),
                  const SizedBox(height: 22),
                ],
                if (versions.isNotEmpty) ...[
                  _VersionsSection(
                    versions: versions,
                    selected: selectedVersion,
                    expanded: versionsExpanded,
                    isSameVersion: isSameVersion,
                    onToggle: onToggleVersions,
                    onSelect: onSelectVersion,
                  ),
                  const SizedBox(height: 18),
                ],
                Row(
                  children: [
                    Expanded(
                      child: GlassActionButton(
                        icon: isInCollection
                            ? Icons.check_rounded
                            : Icons.add_rounded,
                        label: isInCollection
                            ? 'In Collection'
                            : 'Add to Collection',
                        active: isInCollection,
                        onTap: onAdd,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GlassActionButton(
                        icon: isInWishlist
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        label:
                            isInWishlist ? 'In Wishlist' : 'Add to Wishlist',
                        active: isInWishlist,
                        onTap: onToggleWishlist,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VersionsSection extends StatelessWidget {
  final List versions;
  final Map? selected;
  final bool expanded;
  final bool Function(Map?, Map) isSameVersion;
  final VoidCallback onToggle;
  final ValueChanged<Map?> onSelect;

  const _VersionsSection({
    required this.versions,
    required this.selected,
    required this.expanded,
    required this.isSameVersion,
    required this.onToggle,
    required this.onSelect,
  });

  // Explains what picking an edition actually does, and what "Master
  // Release" means, instead of just repeating "select an edition".
  static const String _infoMessage =
      "Select the pressing you have, or the one you're after.\n"
      "Not sure which one you got ?\nGo for the Master release, "
      "the general info for the album, not tied to a specific pressing.";

  String _summary() {
    if (selected == null) return kGenericEditionLabel;
    final format = selected!['format'] as String? ?? '';
    final country = selected!['country'] as String? ?? '';
    final parts = [format, country].where((s) => s.isNotEmpty).join(' · ');
    return parts.isEmpty ? 'Selected edition' : parts;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const ModalSectionLabel('EDITION'),
            const SizedBox(width: 6),
            const ModalInfoTooltip(message: _infoMessage),
            const SizedBox(width: 6),
            ModalSectionLabel('(${versions.length + 1})'),
          ],
        ),
        const SizedBox(height: 10),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withValues(alpha: .06),
              border: Border.all(color: Colors.white.withValues(alpha: .10)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _summary(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: .85),
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white.withValues(alpha: .5),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !expanded
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    children: [
                      _VersionOption(
                        label: kGenericEditionLabel,
                        subtitle: kGenericEditionSubtitle,
                        selected: selected == null,
                        onTap: () => onSelect(null),
                      ),
                      ...versions.map((v) {
                        final version = v as Map;
                        final format = version['format'] as String? ?? '—';
                        final versionLabel =
                            formatLabelValue(version['label']);
                        final subtitle = [
                          versionLabel,
                          version['country'] as String?,
                          validReleased(version['released']),
                        ]
                            .whereType<String>()
                            .where((s) => s.isNotEmpty)
                            .join(' · ');
                        return _VersionOption(
                          label: format,
                          subtitle: subtitle,
                          selected: selected != null &&
                              isSameVersion(selected, version),
                          onTap: () => onSelect(version),
                        );
                      }),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _VersionOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _VersionOption({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: selected
                ? kGlassAccent.withValues(alpha: .16)
                : Colors.white.withValues(alpha: .04),
            border: Border.all(
              color: selected
                  ? kGlassAccent.withValues(alpha: .55)
                  : Colors.white.withValues(alpha: .07),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 18,
                color: selected
                    ? kGlassAccent
                    : Colors.white.withValues(alpha: .30),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: .85),
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.3,
                          color: Colors.white.withValues(alpha: .45),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}