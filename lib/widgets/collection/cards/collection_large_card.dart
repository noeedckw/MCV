// collection_large_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../storage/vinyl_entry.dart';
import '../../explorer/explorer_results_grid.dart' show GridFormatStyle;
import '../../../utils/artist_name.dart';

/// Portrait card for the Collection tab. Surfaces label/condition/genres/
/// styles as a mixed set of tags (capped to 2 lines, with a "+N" chip
/// right after the last visible tag if there's more — tapping anywhere on
/// the card already opens the full detail), and always shows a neutral
/// glass edition badge at the very bottom: the pressing's format/country
/// when it's a specific edition, or "Master Release · No specific
/// pressing" otherwise — always a single clean line.
class CollectionLargeCard extends StatelessWidget {
  final VinylEntry entry;
  final Widget cover;
  final GridFormatStyle style;

  const CollectionLargeCard({
    super.key,
    required this.entry,
    required this.cover,
    required this.style,
  });

  static const double _radius = 18;
  static const int _maxTagLines = 2;
  static const double _tagSpacing = 8;
  static const double _tagRunSpacing = 8;

  TextStyle get _tagTextStyle => TextStyle(
        fontSize: style.metaFontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: .25,
        color: Colors.white.withValues(alpha: .70),
      );

  double _tagWidth(String text, TextStyle textStyle, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    return painter.width + 22;
  }

  int _greedyFitCount(
    List<String> tags,
    double maxWidth,
    TextScaler scaler, {
    double lastLineReserve = 0,
  }) {
    var count = 0;
    var line = 0;
    var lineWidth = 0.0;

    for (var i = 0; i < tags.length; i++) {
      final w = _tagWidth(tags[i], _tagTextStyle, scaler);
      final onLastLine = line == _maxTagLines - 1;
      final reserve = onLastLine ? lastLineReserve : 0.0;
      final isFirstOnLine = lineWidth == 0.0;
      final neededWidth = isFirstOnLine ? w + reserve : lineWidth + _tagSpacing + w + reserve;

      if (neededWidth <= maxWidth) {
        count++;
        lineWidth = isFirstOnLine ? w : lineWidth + _tagSpacing + w;
        continue;
      }

      if (onLastLine) break;
      line++;
      count++;
      lineWidth = w;
    }
    return count;
  }

  ({List<String> visible, int hiddenCount}) _fitTags(
    List<String> tags,
    double maxWidth,
    TextScaler scaler,
  ) {
    if (tags.isEmpty) return (visible: const [], hiddenCount: 0);

    final fitAll = _greedyFitCount(tags, maxWidth, scaler);
    if (fitAll >= tags.length) {
      return (visible: tags, hiddenCount: 0);
    }

    final moreChipWidth = _tagWidth('+${tags.length}', _tagTextStyle, scaler);
    final fitWithReserve = _greedyFitCount(
      tags,
      maxWidth,
      scaler,
      lastLineReserve: _tagSpacing + moreChipWidth,
    );

    return (
      visible: tags.sublist(0, fitWithReserve),
      hiddenCount: tags.length - fitWithReserve,
    );
  }

  Widget _tag(String text, {bool muted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: muted ? .05 : .08),
            Colors.white.withValues(alpha: muted ? .02 : .03),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: muted ? .06 : .08)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: _tagTextStyle.copyWith(
          color: Colors.white.withValues(alpha: muted ? .45 : .70),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final year = entry.year?.toString();
    final hasYear = year != null && year.isNotEmpty && year != "0";

    // Edition badge: format + country when it's a specific pressing,
    // a clear "Master Release" line otherwise. Always a single line.
    final versionParts = <String>[
      if (entry.format != null && entry.format!.isNotEmpty) entry.format!,
      if (entry.releaseCountry != null && entry.releaseCountry!.isNotEmpty) entry.releaseCountry!,
    ];
    final isSpecific = entry.isSpecificEdition;
    final versionTitle = isSpecific
        ? (versionParts.isNotEmpty ? versionParts.join(' · ') : 'Specific Edition')
        : 'Master Release · No specific pressing';

    // Mixed tags — label, condition, genres, styles. No date here.
    final allTags = <String>[
      if (entry.condition != null && entry.condition!.isNotEmpty) entry.condition!,
      ...?entry.genres,
      ...?entry.styles,
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxTagsWidth = constraints.maxWidth - (style.textPadding.horizontal);
            final scaler = MediaQuery.textScalerOf(context);
            final fitted = _fitTags(allTags, maxTagsWidth, scaler);

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_radius),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: .06),
                    Colors.white.withValues(alpha: .02),
                  ],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: .10), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .35),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: AspectRatio(aspectRatio: 1, child: cover),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: style.textPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          cleanArtistName(entry.artist),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: style.titleFontSize,
                            fontWeight: FontWeight.w600,
                            letterSpacing: .1,
                            color: Colors.white.withValues(alpha: .85),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                entry.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: style.titleFontSize + 4,
                                  fontWeight: FontWeight.w800,
                                  height: 1.08,
                                  letterSpacing: -.3,
                                  color: Colors.white.withValues(alpha: .95),
                                ),
                              ),
                            ),
                            if (hasYear)
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Text(
                                  year,
                                  style: TextStyle(
                                    fontSize: style.yearFontSize,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: .45),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        if (allTags.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: _tagSpacing,
                            runSpacing: _tagRunSpacing,
                            children: [
                              for (final t in fitted.visible) _tag(t),
                              if (fitted.hiddenCount > 0) _tag('+${fitted.hiddenCount}', muted: true),
                            ],
                          ),
                        ],

                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white.withValues(alpha: .06),
                            border: Border.all(color: Colors.white.withValues(alpha: .12)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSpecific ? Icons.verified_rounded : Icons.album_outlined,
                                size: 14,
                                color: Colors.white.withValues(alpha: .60),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  versionTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: .80),
                                    fontSize: style.metaFontSize,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}