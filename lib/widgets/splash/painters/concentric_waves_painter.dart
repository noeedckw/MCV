import 'package:flutter/material.dart';

/// Cercles qui naissent au centre et s'étendent en s'estompant, en
/// boucle continue — effet onde sonore/sonar. Utilisé uniquement quand
/// le style de fond tiré au sort est `SplashStyle.concentricWaves`.
class ConcentricWavesPainter extends CustomPainter {
  final Color color;
  final double phase; // 0..1, boucle

  ConcentricWavesPainter({required this.color, required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.4);
    final maxRadius = size.longestSide * 0.7;
    const waveCount = 3;

    for (int i = 0; i < waveCount; i++) {
      final t = (phase + i / waveCount) % 1.0;
      final radius = t * maxRadius;
      final opacity = (1 - t) * 0.22;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: opacity);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ConcentricWavesPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.color != color;
}