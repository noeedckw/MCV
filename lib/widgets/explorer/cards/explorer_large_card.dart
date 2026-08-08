// large_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../explorer_results_grid.dart';

class LargeCard extends StatelessWidget {
  final Widget cover;
  final String artist;
  final String album;
  final String? year;
  final bool hasYear;
  final List<String>? genres;
  final String? country;
  final GridFormatStyle style;
  final String? label;

  const LargeCard({
    super.key,
    required this.cover,
    required this.artist,
    required this.album,
    required this.year,
    required this.hasYear,
    required this.genres,
    required this.country,
    required this.style,
    required this.label,
  });

  static const double _radius = 18;
  static const int _maxTagLines = 2;
  static const double _tagSpacing = 8;
  static const double _tagRunSpacing = 8;

  bool get _hasKnownCountry {
    final c = country?.trim();
    return c != null && c.isNotEmpty && c.toLowerCase() != 'unknown';
  }

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
      final neededWidth = isFirstOnLine
          ? w + reserve
          : lineWidth + _tagSpacing + w + reserve;

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

  Widget _label(String text, {bool muted = false}) {
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
        border: Border.all(
          color: Colors.white.withValues(alpha: muted ? .06 : .08),
        ),
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
    // Genres (chacun en tag séparé) + pays (si connu) + label, tous mélangés
    // comme sur la Collection card.
    final allTags = <String>[
      ...?genres,
      if (_hasKnownCountry) country!.trim(),
      if (label != null && label!.isNotEmpty) label!,
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxTagsWidth =
                constraints.maxWidth - style.textPadding.horizontal;
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
                border: Border.all(
                  color: Colors.white.withValues(alpha: .10),
                  width: 1,
                ),
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
                  /// COVER
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

                  /// TEXT
                  Container(
                    width: double.infinity,
                    padding: style.textPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        /// ARTIST
                        Text(
                          artist,
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

                        /// ALBUM + YEAR
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                album,
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
                                  year!,
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

                          /// TAGS
                          Wrap(
                            spacing: _tagSpacing,
                            runSpacing: _tagRunSpacing,
                            children: [
                              for (final t in fitted.visible) _label(t),
                              if (fitted.hiddenCount > 0)
                                _label('+${fitted.hiddenCount}', muted: true),
                            ],
                          ),
                        ],
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