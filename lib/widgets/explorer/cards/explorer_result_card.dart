import 'package:flutter/material.dart';
import '../../cover/cover_image.dart';
import '../explorer_results_grid.dart';
import '../../shared/compact_card.dart';
import 'explorer_large_card.dart';
import '../../shared/mosaic_card.dart';
import '../../shared/standard_card.dart';

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

  /// Same shape handling as [_formatValue], but keeps each entry separate
  /// instead of joining them — used for genres, which we now render as
  /// individual tags rather than one long string.
  static List<String>? _asStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      final list = value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      return list.isEmpty ? null : list;
    }
    final s = value.toString().trim();
    return s.isEmpty ? null : [s];
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
    final genres = _asStringList(result["genre"]);
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
        genres: genres,
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