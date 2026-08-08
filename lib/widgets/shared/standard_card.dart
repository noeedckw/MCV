// standard_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../explorer/explorer_results_grid.dart';

class StandardCard extends StatelessWidget {
  final Widget cover;
  final String artist;
  final String album;
  final String? year;
  final bool hasYear;
  final GridFormatStyle style;

  const StandardCard({
    super.key,
    required this.cover,
    required this.artist,
    required this.album,
    required this.year,
    required this.hasYear,
    required this.style,
  });

  static const double _radius = 10;
  static const double _coverInset =
      8; // ← écart entre le cadre et l'image carrée

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
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
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  _coverInset,
                  _coverInset,
                  _coverInset,
                  0,
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: cover, // coins carrés, non clippés
                ),
              ),
              SizedBox(
                height: style.textContainerHeight,
                width: double.infinity,
                child: Padding(
                  padding: style.textPadding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: style.titleFontSize,
                          fontWeight: FontWeight.w600,
                          letterSpacing: .1,
                          height: 1.2,
                          color: Colors.white.withValues(alpha: .85),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              album,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: style.subtitleFontSize,
                                height: 1.2,
                                color: Colors.white.withValues(alpha: .58),
                              ),
                            ),
                          ),
                          if (hasYear) ...[
                            const SizedBox(width: 6),
                            Text(
                              year!,
                              style: TextStyle(
                                fontSize: style.yearFontSize,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: .45),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
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
