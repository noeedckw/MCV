import 'package:flutter/material.dart';
import '../../../storage/vinyl_entry.dart';
import '../../cover/cover_image.dart';
import '../../shared/mosaic_card.dart';
import '../../shared/standard_card.dart';
import '../../explorer/explorer_results_grid.dart';
import '../../shared/compact_card.dart';
import 'collection_large_card.dart';
import '../../../utils/artist_name.dart';

/// Routes to the right card for the active column count.
///
/// Large (1 col) and Compact (3 col) get collection-specific cards —
/// [CollectionLargeCard] / [CollectionCompactCard] — since browsing your own
/// collection needs pressing details (format, label, condition, precise
/// version) that a search-result card has no use for. Standard (2 col) and
/// Mosaic (4+ col) stay the exact same widgets used on the Explorer tab:
/// there's no room for that extra info at that size anyway.
class CollectionResultCard extends StatelessWidget {
  final VinylEntry entry;
  final int columns;
  final GridFormatStyle style;
  final VoidCallback onTap;

  /// Favorites are only ever meaningful for owned collection entries, not
  /// wishlist ones — callers building the wishlist grid should simply not
  /// pass this, which hides the heart entirely for that tab.
  final VoidCallback? onToggleFavorite;

  const CollectionResultCard({
    super.key,
    required this.entry,
    required this.columns,
    required this.style,
    required this.onTap,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final Widget cover = CoverImage(
      localPath: entry.localCoverPath,
      bytes: entry.coverBytes,
    );

    final year = entry.year?.toString();
    final hasYear = year != null && year.isNotEmpty && year != "0";
    final artist = cleanArtistName(entry.artist);

    final Widget content = switch (columns) {
      1 => CollectionLargeCard(entry: entry, cover: cover, style: style),
      2 => StandardCard(
        cover: cover,
        artist: artist,
        album: entry.title,
        year: year,
        hasYear: hasYear,
        style: style,
      ),
      3 => CompactCard(
        cover: cover,
        artist: artist,
        album: entry.title,
        style: style,
      ),
      _ => MosaicCard(cover: cover, album: entry.title, style: style),
    };

    // Never on wishlist entries, and never when the caller doesn't wire a
    // handler for it (e.g. explorer-flavoured usages of this same card).
    final showFavorite = onToggleFavorite != null && !entry.isWishlist;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          content,
          if (showFavorite)
            Positioned(
              top: 6,
              right: 6,
              child: _FavoriteBadge(
                isFavorite: entry.isFavorite,
                onTap: onToggleFavorite!,
              ),
            ),
        ],
      ),
    );
  }
}

/// Coeur plein/vide en overlay sur la pochette — tap indépendant du
/// GestureDetector parent (qui ouvre la modal de détail), donc l'InkWell
/// capte le tap en premier sans propager l'ouverture de la modal.
class _FavoriteBadge extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onTap;

  const _FavoriteBadge({required this.isFavorite, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: .40),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 26,
          height: 26,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                key: ValueKey(isFavorite),
                size: 14,
                color: isFavorite
                    ? const Color(0xFFFF5C7A)
                    : Colors.white.withValues(alpha: .85),
              ),
            ),
          ),
        ),
      ),
    );
  }
}