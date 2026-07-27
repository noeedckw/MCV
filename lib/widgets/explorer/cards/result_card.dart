import 'package:flutter/material.dart';
import '../../cover_image.dart';
import '../explorer_results_grid.dart';
import 'compact_card.dart';
import 'large_card.dart';
import 'mosaic_card.dart';
import 'standard_card.dart';

class ResultCard extends StatelessWidget {
  final Map result;
  final int columns;
  final GridFormatStyle style;
  final VoidCallback onTap;

  const ResultCard({
    super.key,
    required this.result,
    required this.columns,
    required this.style,
    required this.onTap,
  });

  static String _stripDisambiguation(String artist) {
    return artist.replaceAll(RegExp(r'\s\(\d+\)'), '').trim();
  }

  static String? _formatValue(dynamic value) {
    if (value == null) return null;
    if (value is List) return value.join(" • ");
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final title = result["title"] as String? ?? "";
    final parts = title.split(" - ");
    final rawArtist = parts.isNotEmpty ? parts[0] : "";
    final artist = _stripDisambiguation(rawArtist);
    final album = parts.length > 1 ? parts.sublist(1).join(" - ") : title;

    final year = result["year"]?.toString();
    final hasYear = year != null && year.isNotEmpty && year != "0";
    final cover = result["cover_image"] as String?;
    final genre = _formatValue(result["genre"]);
    final country = _formatValue(result["country"]);
    final label = _formatValue(result["label"]);
    final coverWidget = CoverImage(networkUrl: cover);

    final Widget content = switch (columns) {
      1 => LargeCard(
        cover: coverWidget,
        artist: artist,
        album: album,
        year: year,
        hasYear: hasYear,
        genre: genre,
        country: country,
        label: label,
        style: style,
      ),
      2 => StandardCard(
        cover: coverWidget,
        artist: artist,
        album: album,
        year: year,
        hasYear: hasYear,
        style: style,
      ),
      3 => CompactCard(
        cover: coverWidget,
        artist: artist,
        album: album,
        style: style,
      ),
      _ => MosaicCard(cover: coverWidget, album: album, style: style),
    };

    return GestureDetector(onTap: onTap, child: content);
  }
}
