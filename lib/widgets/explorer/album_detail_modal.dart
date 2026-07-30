import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../utils/artist_name.dart';
import '../cover_viewer_modal.dart';

import '../cover_image.dart';
import '../../providers/explorer_provider.dart';
import '../../utils/discogs_notes.dart';

/// Accent used for anything "selected" or "active" across the modal — keeps
/// the dark glass palette from feeling flat.
const Color _kAccent = Color(0xFFE3B673);

/// Mirrors ResultCard's `_formatValue`: Discogs sometimes returns `label`
/// as a List<String> rather than a single string — join those with " • "
/// instead of showing a raw Dart list.
String _stripDisambiguationNumbers(String value) {
  return value.replaceAll(RegExp(r'\s?\(\d+\)'), '').trim();
}

String? _validReleased(dynamic value) {
  if (value == null) return null;
  final str = value.toString().trim();
  if (str.isEmpty) return null;
  if (RegExp(r'^[0-]+$').hasMatch(str)) return null;
  return str;
}

String? _formatLabelValue(dynamic value) {
  if (value == null) return null;
  final raw = value is List
      ? (value.isEmpty ? null : value.join(' • '))
      : value.toString();
  if (raw == null || raw.isEmpty) return null;
  final cleaned = _stripDisambiguationNumbers(raw);
  return cleaned.isEmpty ? null : cleaned;
}

/// Discogs renvoie parfois `year: 0` quand la date est inconnue — dans ce
/// cas on veut n'afficher aucune année plutôt qu'un "0" qui ne veut rien
/// dire pour l'utilisateur.
String? _validYear(dynamic value) {
  if (value == null) return null;
  final str = value.toString().trim();
  if (str.isEmpty || str == '0') return null;
  return str;
}

Future<void> showAlbumDetailModal(
  BuildContext context, {
  required Map<String, dynamic> result,
}) {
  final masterId = result['id'] as int;
  final provider = context.read<ExplorerProvider>();

  provider.loadMasterDetail(masterId);
  provider.loadMasterVersions(masterId);
  provider.checkCollectionStatus(masterId);
  // Hides the search bar / navbar for as long as this modal is up (see
  // ExplorerScreen and MainNavigationScreen, which watch this flag).
  provider.setDetailModalOpen(true);

  const transitionDuration = Duration(milliseconds: 260);

  return showGeneralDialog(
    context: context,
    useRootNavigator: false,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.transparent,
    transitionDuration: transitionDuration,
    pageBuilder: (context, anim1, anim2) =>
        AlbumDetailModal(initialResult: result),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return AnimatedBuilder(
        animation: curved,
        child: child,
        builder: (context, child) => BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: 20 * curved.value,
            sigmaY: 20 * curved.value,
          ),
          child: Container(
            color: Colors.black.withValues(alpha: .5 * curved.value),
            child: FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween(begin: .95, end: 1.0).animate(curved),
                child: child,
              ),
            ),
          ),
        ),
      );
    },
  ).whenComplete(() {
    // `whenComplete` fires as soon as the route is popped, which is BEFORE
    // the reverse (closing) transition has finished playing — the route
    // stays in the tree animating out for `transitionDuration` more.
    // Clearing the provider's detail right away made the still-visible
    // modal rebuild with everything wiped (no tracklist/notes/versions),
    // so it visibly snapped down to a tiny stub right as it faded out.
    // Waiting for the transition to actually finish avoids that flash.
    Future.delayed(transitionDuration, () {
      if (context.mounted) {
        final p = context.read<ExplorerProvider>();
        p.clearMasterDetail();
        p.setDetailModalOpen(false);
      }
    });
  });
}

class AlbumDetailModal extends StatefulWidget {
  final Map<String, dynamic> initialResult;

  const AlbumDetailModal({super.key, required this.initialResult});

  @override
  State<AlbumDetailModal> createState() => _AlbumDetailModalState();
}

class _AlbumDetailModalState extends State<AlbumDetailModal> {
  static const double _radius = 28;

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

  bool _isSameVersion(Map? a, Map b) {
    if (a == null) return false;
    final aid = a['id'];
    final bid = b['id'];
    if (aid != null && bid != null) return aid == bid;
    return identical(a, b);
  }

  void _toggleWantlist() {
    HapticFeedback.selectionClick();
    context.read<ExplorerProvider>().toggleWantlist(
      widget.initialResult,
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

    // Re-check l'état collection/wantlist pour CETTE édition précisément —
    // sinon les boutons gardaient l'état de l'édition précédente (ou du
    // master générique) jusqu'à la prochaine ouverture de la modal.
    final masterId = widget.initialResult['id'] as int;
    provider.checkCollectionStatus(masterId, selectedVersion: version);
  }

  void _toggleVersions() =>
      setState(() => _versionsExpanded = !_versionsExpanded);

  // Toggles collection status on/off depending on the current state.
  // Doesn't close the modal anymore: the user can chain collection +
  // wantlist actions, or switch edition and toggle again, without having
  // to reopen it.
  void _toggleCollection() {
    HapticFeedback.mediumImpact();
    context.read<ExplorerProvider>().toggleCollection(
      widget.initialResult,
      _selectedVersion,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExplorerProvider>();
    final detail = provider.masterDetail;
    final versions = (provider.masterVersions as List?) ?? const [];
    final isLoading = provider.isLoadingDetail || provider.isLoadingVersions;
    final error = provider.detailErrorMessage ?? provider.versionsErrorMessage;
    final isInCollection = provider.isInCollection;
    final isInWantlist = provider.isInWantlist;

    final masterCover = (detail?['images'] as List?)?.isNotEmpty == true
        ? detail!['images'][0]['uri'] as String?
        : widget.initialResult['cover_image'] as String?;

    // A specific pressing can have different artwork. Once the release detail
    // has loaded, prefer its image; while it's still loading, use the
    // version's own thumbnail from the versions list instead of the master's
    // cover, so it doesn't flash back and then swap again a moment later.
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
        ? _formatLabelValue(_selectedVersion!['label'])
        : _formatLabelValue(widget.initialResult['label']);

    final rawDate = _selectedVersion != null
        ? (provider.releaseDetail?['released']?.toString() ??
              _selectedVersion!['released']?.toString())
        : detail?['released']?.toString();

    final fallbackYear = _selectedVersion != null
        ? (_validYear(provider.releaseDetail?['year']) ??
              _validYear(_selectedVersion!['year']) ??
              _validYear(detail?['year']))
        : _validYear(detail?['year']);

    String? releaseDate;
    if (rawDate != null && rawDate.isNotEmpty) {
      try {
        releaseDate = DateFormat(
          'd MMMM yyyy',
          'en_US',
        ).format(DateTime.parse(rawDate));
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).maybePop(),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final modalWidth = constraints.maxWidth < 680
                ? constraints.maxWidth * 0.92
                : 600.0;
            // Top/bottom breathing margins, set independently. Ceiling
            // only: bounds the space actually available inside the safe
            // area (so never under the system bar / notch / home
            // indicator). The modal grows up to this but shrinks to fit
            // shorter content (e.g. a short tracklist) instead of always
            // reserving the full height and leaving empty space at the
            // bottom.
            const topMargin = 16.0;
            const bottomMargin = 16.0;
            final modalMaxHeight =
                (constraints.maxHeight - topMargin - bottomMargin).clamp(
                  280.0,
                  680.0,
                );

            return Padding(
              padding: const EdgeInsets.only(
                top: topMargin,
                bottom: bottomMargin,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: SizedBox(
                    width: modalWidth,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: 280,
                        maxHeight: modalMaxHeight,
                      ),
                      child: Material(
                        type: MaterialType.transparency,
                        child: _GlassPanel(
                          radius: _radius,
                          child: Stack(
                            children: [
                              if (isLoading)
                                const _LoadingState()
                              else if (error != null)
                                _ErrorState(message: error)
                              else
                                _Content(
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
                                  isInWantlist: isInWantlist,
                                  onToggleWantlist: _toggleWantlist,
                                ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: _CloseButton(
                                  onTap: () => Navigator.of(context).maybePop(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Opaque "glass" panel: frosted-glass effect on the edges (light blur +
/// glowing border + drop shadow) but a near-opaque background -> no
/// distracting transparency that lets you glimpse what's behind it.
class _GlassPanel extends StatelessWidget {
  final double radius;
  final Widget child;

  const _GlassPanel({required this.radius, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF232329).withValues(alpha: .97),
                const Color(0xFF131316).withValues(alpha: .97),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: .14),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .55),
                blurRadius: 50,
                offset: const Offset(0, 24),
              ),
              // Thin glowing rim at the top -> reinforces the "glass" feel.
              BoxShadow(
                color: Colors.white.withValues(alpha: .04),
                blurRadius: 1,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: .35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            Icons.close_rounded,
            size: 19,
            color: Colors.white.withValues(alpha: .8),
          ),
        ),
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
        valueColor: AlwaysStoppedAnimation<Color>(_kAccent),
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

/// Comme _NotesSection mais pour la ligne de label — clampée à 3 lignes
/// par défaut, avec le même toggle "Show more / Show less".
class _LabelSection extends StatefulWidget {
  final String label;
  const _LabelSection({required this.label});

  @override
  State<_LabelSection> createState() => _LabelSectionState();
}

class _LabelSectionState extends State<_LabelSection> {
  static const int _collapsedLines = 2;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 11.5,
      color: Colors.white.withValues(alpha: .45),
    );
    final text = 'Label : ${widget.label}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: _collapsedLines,
          textDirection: ui.TextDirection.ltr,
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topLeft,
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: SizedBox(
                width: double.infinity,
                child: Text(
                  text,
                  maxLines: _collapsedLines,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
              secondChild: SizedBox(
                width: double.infinity,
                child: Text(text, style: style),
              ),
            ),
            if (overflows) ...[
              const SizedBox(height: 4),
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    _expanded ? 'Show less' : 'Show more',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: .65),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Colors.white.withValues(alpha: .40),
      ),
    );
  }
}

/// Small "i" info icon that reveals a short, discreet explanation on tap,
/// and dismisses itself as soon as the user taps anywhere else.
/// Small "i" info icon that reveals a short, discreet explanation on tap,
/// and dismisses itself as soon as the user taps anywhere else.
/// Small "i" info icon that reveals a short, discreet explanation on tap,
/// and dismisses itself as soon as the user taps anywhere else.
class _InfoTooltip extends StatelessWidget {
  final String message;
  const _InfoTooltip({required this.message});

  @override
  Widget build(BuildContext context) {
    // Taille fixe réservée dans le Row (= taille de l'icône) -> ne pousse
    // rien à côté. Le Stack + clipBehavior.none permet au Tooltip (plus
    // large que ça) de déborder visuellement vers la droite sans que ce
    // débordement compte dans la mise en page du Row.
    return SizedBox(
      width: 13,
      height: 13,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Tooltip(
              message: message,
              triggerMode: TooltipTriggerMode.tap,
              showDuration: const Duration(seconds: 5),
              preferBelow: true,
              verticalOffset: 12,
              constraints: const BoxConstraints(maxWidth: 200),
              textStyle: TextStyle(
                fontSize: 11.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: .92),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                color: const Color(0xFF2A2A30).withValues(alpha: .98),
                border: Border.all(color: Colors.white.withValues(alpha: .14)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .40),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              // Zone de référence élargie vers la droite pour décaler la
              // bulle -> l'icône reste collée à gauche dedans.
              child: SizedBox(
                width: 60,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 13,
                    color: Colors.white.withValues(alpha: .40),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Notes are clamped to 5 lines by default, with a "Show more" toggle that
/// reveals the full text — and "Show less" to collapse it back down.
class _NotesSection extends StatefulWidget {
  final String notes;
  const _NotesSection({required this.notes});

  @override
  State<_NotesSection> createState() => _NotesSectionState();
}

class _NotesSectionState extends State<_NotesSection> {
  static const int _collapsedLines = 5;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 12.5,
      height: 1.4,
      color: Colors.white.withValues(alpha: .55),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Measure once whether the text actually overflows 5 lines at this
        // width, so the toggle only shows up when it's actually needed.
        final painter = TextPainter(
          text: TextSpan(text: widget.notes, style: style),
          maxLines: _collapsedLines,
          textDirection: ui.TextDirection.ltr,
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topLeft,
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: SizedBox(
                width: double.infinity,
                child: Text(
                  widget.notes,
                  maxLines: _collapsedLines,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
              secondChild: SizedBox(
                width: double.infinity,
                child: Text(widget.notes, style: style),
              ),
            ),
            if (overflows) ...[
              const SizedBox(height: 6),
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    _expanded ? 'Show less' : 'Show more',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: .85),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white.withValues(alpha: .06),
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: .25,
          color: Colors.white.withValues(alpha: .70),
        ),
      ),
    );
  }
}

/// Sizes the artist + album (+ year) block so it never grows taller than
/// the cover art next to it: starts from slightly bigger "ideal" sizes and,
/// only if the actual text (given its wrapping at the available width)
/// would overflow that height, shrinks both down together — never below a
/// legibility floor — until it fits.
class _FittedTitles extends StatelessWidget {
  final String artist;
  final String album;
  final String? year;

  const _FittedTitles({
    required this.artist,
    required this.album,
    required this.year,
  });

  static const double _maxHeight = 138; // matches the cover's height
  static const double _artistBase = 15.5;
  static const double _artistMin = 12.0;
  static const double _albumBase = 21.0;
  static const double _albumMin = 15.0;

  TextStyle _artistStyle(double size) => TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w600,
    color: Colors.white.withValues(alpha: .78),
  );

  TextStyle _albumStyle(double size) => TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -.3,
  );

  static const TextStyle _yearStyle = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
  );

  double _measure(
    String text,
    TextStyle style,
    double maxWidth,
    TextScaler scaler,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
      textScaler: scaler,
    )..layout(maxWidth: maxWidth);
    return painter.height;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final scaler = MediaQuery.textScalerOf(context);

        final yearHeight = year != null
            ? _measure(year!, _yearStyle, maxWidth, scaler) +
                  6 // + spacing above it
            : 0.0;

        double artistSize = _artistBase;
        double albumSize = _albumBase;

        // Step both sizes down together, in proportion, re-measuring the
        // actual wrapped text each time, until the whole block fits within
        // the cover's height (or we've hit the legibility floor).
        for (double t = 1.0; t >= 0; t -= 0.03) {
          artistSize = (_artistBase * t).clamp(_artistMin, _artistBase);
          albumSize = (_albumBase * t).clamp(_albumMin, _albumBase);
          final artistHeight = _measure(
            artist,
            _artistStyle(artistSize),
            maxWidth,
            scaler,
          );
          final albumHeight = _measure(
            album,
            _albumStyle(albumSize),
            maxWidth,
            scaler,
          );
          final total = artistHeight + 4 + albumHeight + yearHeight;
          if (total <= _maxHeight ||
              (artistSize <= _artistMin && albumSize <= _albumMin))
            break;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(artist, style: _artistStyle(artistSize)),
            const SizedBox(height: 4),
            Text(album, style: _albumStyle(albumSize)),
            if (year != null) ...[
              const SizedBox(height: 6),
              Text(
                year!,
                style: _yearStyle.copyWith(
                  color: Colors.white.withValues(alpha: .45),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Compact glass button, meant to go in pairs (side by side via Expanded).
/// `active` switches between a neutral/dim style and a brighter, "filled"
/// style once the action has been carried out (already in collection /
/// wantlist) — no color, only white opacity/weight changes.
class _GlassActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _GlassActionButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Colors.white.withValues(alpha: active ? .95 : .78);
    return Material(
      color: Colors.white.withValues(alpha: active ? .14 : .06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: active ? .30 : .12),
              width: active ? 1.3 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
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
  final bool isInWantlist;
  final VoidCallback onToggleWantlist;

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
    required this.isInWantlist,
    required this.onToggleWantlist,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Header: cover art + titles (chips moved out of this column) ---
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => showCoverViewer(
                      context,
                      cover: CoverImage(networkUrl: cover),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 138,
                              height: 138,
                              child: CoverImage(networkUrl: cover),
                            ),
                          ),
                        ],
                      ),
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
                      // Chips moved out of here -> no more dependency on
                      // this column's narrow width, so no more forced
                      // wrap inflating the header's height beyond the
                      // cover's. Font sizes flex with _FittedTitles: a
                      // short artist/album gets a bit bigger, a long one
                      // shrinks just enough to stay within the cover's
                      // height instead of overflowing it.
                      child: _FittedTitles(
                        artist: artist,
                        album: album,
                        year: year,
                      ),
                    ),
                  ),
                ],
              ),
              // Chips shown below, across the modal's full width: much more
              // horizontal room, so fewer wrap lines even with a long list
              // of genres/styles, and this block's height no longer affects
              // alignment next to the cover. Label (si dispo) affiché en
              // dernier, dans un style distinct, et jamais plus large que
              // les autres chips.
              if (genres.isNotEmpty || styles.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...genres.map(_Chip.new),
                    ...styles.map(_Chip.new),
                  ],
                ),
              ],
              if (label != null && label!.isNotEmpty) ...[
                const SizedBox(height: 10),
                _LabelSection(label: label!),
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
                Row(
                  children: [
                    const _SectionLabel('TRACKLIST'),
                    if (isTracklistSwitching) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 11,
                        height: 11,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.6,
                          valueColor: AlwaysStoppedAnimation<Color>(_kAccent),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                // AnimatedSwitcher: a small fade/slide transition whenever
                // the edition changes and the tracklist along with it.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, .03),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: isTracklistSwitching
                      ? const SizedBox(key: ValueKey('loading'))
                      : Column(
                          key: ValueKey(selectedVersion?['id'] ?? 'master'),
                          children: tracklist.isEmpty
                              ? [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      'Tracklist unavailable for this edition.',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: Colors.white.withValues(
                                          alpha: .45,
                                        ),
                                      ),
                                    ),
                                  ),
                                ]
                              : tracklist.map((t) {
                                  final track = t as Map;
                                  final position =
                                      track['position'] as String? ?? '';
                                  final trackTitle =
                                      track['title'] as String? ?? '';
                                  final duration =
                                      track['duration'] as String? ?? '';
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 5,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 28,
                                          child: Text(
                                            position,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white.withValues(
                                                alpha: .40,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            trackTitle,
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              color: Colors.white.withValues(
                                                alpha: .82,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (duration.isNotEmpty)
                                          Text(
                                            duration,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white.withValues(
                                                alpha: .40,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                        ),
                ),
                const SizedBox(height: 22),

                if (notes != null && notes!.trim().isNotEmpty) ...[
                  const _SectionLabel('NOTES'),
                  const SizedBox(height: 10),
                  _NotesSection(notes: notes!.trim()),
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

                // Two glass buttons side by side.
                Row(
                  children: [
                    Expanded(
                      child: _GlassActionButton(
                        icon: isInCollection
                            ? Icons.check_rounded
                            : Icons.add_rounded,
                        label: isInCollection
                            ? 'In Collection'
                            : 'Add to Collection',
                        active: isInCollection,
                        // Tapping toggles collection status on/off directly.
                        onTap: onAdd,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _GlassActionButton(
                        icon: isInWantlist
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        label: isInWantlist ? 'In Wantlist' : 'Add to Wantlist',
                        active: isInWantlist,
                        // Toggle: tapping again removes it from the wantlist.
                        onTap: onToggleWantlist,
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

  // Same wording as the collection detail modal's edition badge, so a
  // release that isn't tied to a specific pressing reads the same way in
  // both places.
  static const String _genericLabel = 'Master Release';
  static const String _genericSubtitle = 'No specific pressing';
  static const String _genericSummary = '$_genericLabel';

  // Explains what picking an edition actually does, and what "Master
  // Release" means, instead of just repeating "select an edition".
  static const String _infoMessage =
      "Select the pressing you have, or the one you're after.\n"
      "Not sure which one you got ?\nGo for the Master release, "
      "the general info for the album, not tied to a specific pressing.";

  String _summary() {
    if (selected == null) return _genericSummary;
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
            const _SectionLabel('EDITION'),
            const SizedBox(width: 6),
            _InfoTooltip(message: _infoMessage),
            const SizedBox(width: 6),
            _SectionLabel('(${versions.length + 1})'),
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
                        label: _genericLabel,
                        subtitle: _genericSubtitle,
                        selected: selected == null,
                        onTap: () => onSelect(null),
                      ),
                      ...versions.map((v) {
                        final version = v as Map;
                        final format = version['format'] as String? ?? '—';
                        final versionLabel = _formatLabelValue(version['label']);
                        final subtitle =
                            [
                                  versionLabel,
                                  version['country'] as String?,
                                  _validReleased(version['released']),
                                ]
                                .whereType<String>()
                                .where((s) => s.isNotEmpty)
                                .join(' · ');
                        return _VersionOption(
                          label: format,
                          subtitle: subtitle,
                          selected:
                              selected != null && isSameVersion(selected, version),
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
                ? _kAccent.withValues(alpha: .16)
                : Colors.white.withValues(alpha: .04),
            border: Border.all(
              color: selected
                  ? _kAccent.withValues(alpha: .55)
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
                    ? _kAccent
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
