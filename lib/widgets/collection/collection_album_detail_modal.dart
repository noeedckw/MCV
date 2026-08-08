// collection_album_detail_modal.dart
import 'package:flutter/material.dart';

import '../../storage/vinyl_entry.dart';
import '../../utils/artist_name.dart';
import '../cover/cover_viewer_modal.dart';
import '../shared/album_modal/discogs_format_utils.dart';
import '../shared/album_modal/edition_labels.dart';
import '../shared/album_modal/glass_modal_kit.dart';
import '../shared/album_modal/tracklist_section.dart';

Future<void> showCollectionAlbumDetail(
  BuildContext context, {
  required VinylEntry entry,
  required Widget cover,
  VoidCallback? onRemove,
  VoidCallback? onToggleList,
  VoidCallback? onToggleFavorite,
}) {
  return showGlassModal(
    context: context,
    pageBuilder: (context) => _CollectionAlbumDetailModal(
      entry: entry,
      cover: cover,
      onRemove: onRemove,
      onToggleList: onToggleList,
      onToggleFavorite: onToggleFavorite,
    ),
  );
}

class _CollectionAlbumDetailModal extends StatefulWidget {
  final VinylEntry entry;
  final Widget cover;
  final VoidCallback? onRemove;
  final VoidCallback? onToggleList;
  final VoidCallback? onToggleFavorite;

  const _CollectionAlbumDetailModal({
    required this.entry,
    required this.cover,
    required this.onRemove,
    required this.onToggleList,
    required this.onToggleFavorite,
  });

  @override
  State<_CollectionAlbumDetailModal> createState() =>
      _CollectionAlbumDetailModalState();
}

class _CollectionAlbumDetailModalState
    extends State<_CollectionAlbumDetailModal> {
  // Optimistic local mirror of the favorite state so the heart flips
  // instantly on tap instead of waiting on the parent's list refresh /
  // storage round-trip. The modal itself is short-lived (closed on
  // backdrop tap), so no need to sync back if the parent ends up
  // reverting — that scenario isn't expected here.
  late bool _isFavorite = widget.entry.isFavorite;

  void _handleToggleFavorite() {
    if (widget.onToggleFavorite == null) return;
    setState(() => _isFavorite = !_isFavorite);
    widget.onToggleFavorite!();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    // Edition block is always shown, master included — mirrors the large
    // card's wording: "Master Release" when there's no specific release
    // tied to this entry, otherwise whatever format/country/date is
    // available for the chosen pressing.
    final versionParts = <String>[
      if (entry.format != null && entry.format!.isNotEmpty) entry.format!,
      if (entry.releaseCountry != null && entry.releaseCountry!.isNotEmpty)
        entry.releaseCountry!,
    ];
    final versionLabel = entry.isSpecificEdition
        ? (versionParts.isNotEmpty
            ? versionParts.join(' · ')
            : 'Specific Edition')
        : kGenericEditionLabel;

    // Favorites only make sense for collection items, never wishlist ones.
    final showFavorite = widget.onToggleFavorite != null && !entry.isWishlist;

    return GlassModalScaffold(
      child: _Content(
        entry: entry,
        cover: widget.cover,
        versionLabel: versionLabel,
        isSpecificEdition: entry.isSpecificEdition,
        onRemove: widget.onRemove,
        onToggleList: widget.onToggleList,
        showFavorite: showFavorite,
        isFavorite: _isFavorite,
        onToggleFavorite: _handleToggleFavorite,
      ),
    );
  }
}

/// Bouton carré glass posé à droite du rectangle EDITION. Taille fixe,
/// centré verticalement — pas de dépendance à la hauteur du rectangle
/// voisin, donc rien ne casse si l'édition passe sur deux lignes.
class _EditionFavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onTap;

  const _EditionFavoriteButton({
    required this.isFavorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: .10)),
          ),
          child: Icon(
            isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            size: 15,
            color: Colors.white.withValues(alpha: isFavorite ? .75 : .55),
          ),
        ),
      ),
    );
  }
}

/// Edition row: "EDITION" label + value.
/// - If they fit on one line, the value sits to the right of the label
///   (mirrors the large card's single-line badge).
/// - If not, the value drops to a new line below the label instead of
///   being squeezed / right-aligned against it (which looked broken).
/// - When the entry isn't tied to a specific pressing, a small (i) icon
///   sits right after the value; tapping it explains what "master
///   release" means.
class _EditionSection extends StatelessWidget {
  final String value;
  final bool isSpecific;

  const _EditionSection({required this.value, required this.isSpecific});

  static const String _label = 'EDITION';
  static const String _genericTooltip =
      "Generic release info\nNo specific edition selected.";
  static const double _spacing = 8;
  static const double _iconReserve = 20; // icon width + its own left spacing

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.0,
      color: Colors.white.withValues(alpha: .40),
    );
    final valueStyle = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 12.5,
      height: 1.3,
      color: Colors.white.withValues(alpha: .85),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);

        final labelPainter = TextPainter(
          text: TextSpan(text: _label, style: labelStyle),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
        )..layout();
        final valuePainter = TextPainter(
          text: TextSpan(text: value, style: valueStyle),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
        )..layout();

        final needed = labelPainter.width +
            _spacing +
            valuePainter.width +
            (isSpecific ? 0 : _iconReserve);
        final fitsOneLine = needed <= constraints.maxWidth;

        final valueRow = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                value,
                textAlign: fitsOneLine ? TextAlign.right : TextAlign.left,
                style: valueStyle,
              ),
            ),
            if (!isSpecific) ...[
              const SizedBox(width: 4),
              const ModalInfoTooltip(message: _genericTooltip),
            ],
          ],
        );

        if (fitsOneLine) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(_label, style: labelStyle),
              const SizedBox(width: _spacing),
              Expanded(
                child:
                    Align(alignment: Alignment.centerRight, child: valueRow),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_label, style: labelStyle),
            const SizedBox(height: 3),
            valueRow,
          ],
        );
      },
    );
  }
}

class _Content extends StatelessWidget {
  final VinylEntry entry;
  final Widget cover;
  final String versionLabel;
  final bool isSpecificEdition;
  final VoidCallback? onRemove;
  final VoidCallback? onToggleList;
  final bool showFavorite;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const _Content({
    required this.entry,
    required this.cover,
    required this.versionLabel,
    required this.isSpecificEdition,
    required this.onRemove,
    required this.onToggleList,
    required this.showFavorite,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final genres = entry.genres ?? const [];
    final styles = entry.styles ?? const [];
    final tracks = (entry.tracklist ?? const [])
        .map(
          (t) => TrackRowData(
            position: t.position,
            title: t.title,
            duration: t.duration,
          ),
        )
        .toList();
    final label = formatLabelValue(entry.label);

    final toggleIcon =
        entry.isWishlist ? Icons.add_rounded : Icons.bookmark_border_rounded;
    final toggleLabel =
        entry.isWishlist ? 'Add to Collection' : 'Add to Wishlist';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ModalCoverThumbnail(
                    cover: cover,
                    onTap: () => showCoverViewer(context, cover: cover),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 34),
                      child: FittedAlbumTitles(
                        artist: cleanArtistName(entry.artist),
                        album: entry.title,
                        year: entry.year?.toString(),
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
              // Edition block — always shown (generic master included),
              // neutral glass rectangle, no accent color. Value sits next
              // to "EDITION" when it fits on one line, otherwise it drops
              // to the line below. Generic/master entries get a small
              // (i) icon that explains what that means.
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white.withValues(alpha: .06),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .10),
                        ),
                      ),
                      child: _EditionSection(
                        value: versionLabel,
                        isSpecific: isSpecificEdition,
                      ),
                    ),
                  ),
                  if (showFavorite) ...[
                    const SizedBox(width: 8),
                    _EditionFavoriteButton(
                      isFavorite: isFavorite,
                      onTap: onToggleFavorite,
                    ),
                  ],
                ],
              ),
              if (label != null) ...[
                const SizedBox(height: 10),
                ModalLabelSection(label: label),
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
                TracklistSection(tracks: tracks),
                if (entry.notes != null &&
                    entry.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 22),
                  const ModalSectionLabel('NOTES'),
                  const SizedBox(height: 10),
                  ModalNotesSection(notes: entry.notes!.trim()),
                ],
                if (onRemove != null || onToggleList != null) ...[
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      if (onToggleList != null)
                        Expanded(
                          child: GlassActionButton(
                            icon: toggleIcon,
                            label: toggleLabel,
                            onTap: onToggleList,
                          ),
                        ),
                      if (onRemove != null && onToggleList != null)
                        const SizedBox(width: 10),
                      if (onRemove != null)
                        Expanded(
                          child: GlassActionButton(
                            icon: Icons.delete_outline_rounded,
                            label: 'Remove',
                            onTap: onRemove,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}