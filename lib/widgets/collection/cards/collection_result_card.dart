import 'package:flutter/material.dart';
import '../../../storage/vinyl_entry.dart';
import '../../cover_image.dart';
import '../../explorer/cards/mosaic_card.dart';
import '../../explorer/cards/standard_card.dart';
import '../../explorer/explorer_results_grid.dart';
import '../../explorer/cards/compact_card.dart';
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

  const CollectionResultCard({
    super.key,
    required this.entry,
    required this.columns,
    required this.style,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Widget cover = CoverImage(localPath: entry.localCoverPath, bytes: entry.coverBytes);

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
      3 => CompactCard(cover: cover, artist: artist, album: entry.title, style: style),
      _ => MosaicCard(cover: cover, album: entry.title, style: style),
    };

    return GestureDetector(onTap: onTap, child: content);
  }
}