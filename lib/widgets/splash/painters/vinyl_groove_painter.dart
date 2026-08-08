import 'package:flutter/material.dart';

/// Anneaux concentriques façon sillons de vinyle, avec un reflet lumineux
/// qui tourne lentement dessus — effet disque qui tourne sous la
/// lumière. Utilisé uniquement quand le style de fond tiré au sort est
/// `SplashStyle.vinylGroove`.
class VinylGroovePainter extends CustomPainter {
  final Color color;
  final double rotation;

  VinylGroovePainter({required this.color, required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final maxRadius = size.longestSide * 0.55;
    const ringCount = 14;

    for (int i = 0; i < ringCount; i++) {
      final t = i / ringCount;
      final radius = maxRadius * (0.25 + 0.75 * t);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = color.withValues(alpha: 0.10 + 0.05 * (1 - t));
      canvas.drawCircle(center, radius, paint);
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final glowPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          color.withValues(alpha: 0.25),
          Colors.transparent,
        ],
        stops: const [0.0, 0.12, 0.24],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: maxRadius));
    canvas.drawCircle(Offset.zero, maxRadius, glowPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant VinylGroovePainter oldDelegate) =>
      oldDelegate.rotation != rotation || oldDelegate.color != color;
}