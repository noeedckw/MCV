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
  final String? genre;
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
    required this.genre,
    required this.country,
    required this.style,
    required this.label,
  });

  static const double _radius = 18;

  Widget _label(String text, double maxWidth) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: .08),
              Colors.white.withValues(alpha: .03),
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: .08)),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: TextStyle(
            fontSize: style.metaFontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: .25,
            color: Colors.white.withValues(alpha: .70),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxLabelWidth = constraints.maxWidth - 28;

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
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: cover,
                      ),
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

                        const SizedBox(height: 10),

                        /// TAGS
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (genre != null && genre!.isNotEmpty)
                              _label(genre!, maxLabelWidth),
                            if (country != null && country!.isNotEmpty)
                              _label(country!, maxLabelWidth),
                            if (label != null && label!.isNotEmpty)
                              _label(label!, maxLabelWidth),
                          ],
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