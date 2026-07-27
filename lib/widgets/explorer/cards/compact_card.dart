// compact_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../explorer_results_grid.dart';

class CompactCard extends StatelessWidget {
  final Widget cover;
  final String artist;
  final String album;
  final GridFormatStyle style;

  const CompactCard({
    super.key,
    required this.cover,
    required this.artist,
    required this.album,
    required this.style,
  });

  static const double _radius = 12;
  static const double _coverInset = 8;

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
                child: AspectRatio(aspectRatio: 1, child: cover),
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
                          height: 1.15,
                          color: Colors.white.withValues(alpha: .85),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        album,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: style.subtitleFontSize,
                          height: 1.15,
                          color: Colors.white.withValues(alpha: .58),
                        ),
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
