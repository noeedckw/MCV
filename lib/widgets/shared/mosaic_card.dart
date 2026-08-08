// mosaic_card.dart
import 'package:flutter/material.dart';
import '../explorer/explorer_results_grid.dart';

class MosaicCard extends StatelessWidget {
  final Widget cover;
  final String album;
  final GridFormatStyle style;

  const MosaicCard({
    super.key,
    required this.cover,
    required this.album,
    required this.style,
  });

  static const double _radius = 10;
  static const double _coverInset = 5;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_coverInset),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        color: Colors.white.withValues(alpha: .04),
        border: Border.all(
          color: Colors.white.withValues(alpha: .08),
          width: 1,
        ),
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            cover, // coins carrés
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: style.textPadding,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: .70),
                    ],
                  ),
                ),
                child: Text(
                  album,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: style.titleFontSize,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: .95),
                    letterSpacing: .1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
