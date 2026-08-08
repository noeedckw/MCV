import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Un vrai disque vinyle qui tourne en continu, toujours affiché en fond
/// derrière le style tiré au hasard — silhouette du disque, sillons
/// concentriques, label central coloré, et un reflet lumineux qui
/// balaie la surface en tournant, comme une lumière qui accroche le
/// vinyle.
class SpinningVinylPainter extends CustomPainter {
  final Color color;
  final double rotation;

  SpinningVinylPainter({required this.color, required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    // Rayon du disque visible (silhouette + sillons) : agrandi pour
    // éviter que le bord du disque soit visible en bas sur certains
    // écrans. Volontairement DÉCOUPLÉ du rayon utilisé pour le label
    // central ci-dessous, pour ne pas faire grandir le logo avec lui.
    final discRadius = size.longestSide * 0.78;
    // Rayon de référence pour le label central : reste basé sur le
    // ratio d'origine (0.62, identique à SplashGeometry.discRadiusRatio),
    // pour que le rond central et donc le logo gardent exactement leur
    // taille et position d'avant, peu importe la taille du disque.
    final labelBaseRadius = size.longestSide * 0.62;

    // Silhouette du disque : quasi noir, à peine teinté par la couleur,
    // pour rester discret sur le fond déjà sombre.
    final discPaint = Paint()
      ..color = Color.lerp(const Color(0xFF15121C), color, 0.06)!;
    canvas.drawCircle(center, discRadius, discPaint);

    // Sillons concentriques.
    const grooveCount = 26;
    for (int i = 0; i < grooveCount; i++) {
      final t = i / grooveCount;
      final radius = discRadius * (0.32 + 0.66 * t);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.035);
      canvas.drawCircle(center, radius, paint);
    }

    // Reflet lumineux qui tourne avec le disque, façon lumière qui
    // accroche la surface d'un vinyle.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final shinePaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          color.withValues(alpha: 0.22),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
        startAngle: 0,
        endAngle: math.pi / 3,
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: discRadius));
    canvas.drawCircle(Offset.zero, discRadius, shinePaint);
    canvas.restore();

    // Label central du disque — basé sur labelBaseRadius (taille
    // d'origine), pas sur le discRadius agrandi.
    final labelRadius = labelBaseRadius * 0.22;
    final labelPaint = Paint()..color = color.withValues(alpha: 0.35);
    canvas.drawCircle(center, labelRadius, labelPaint);

    final labelRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color.withValues(alpha: 0.5);
    canvas.drawCircle(center, labelRadius, labelRingPaint);

    // Petit trou central, comme un vrai vinyle.
    final holePaint = Paint()..color = const Color(0xFF0A0910);
    canvas.drawCircle(center, labelRadius * 0.08, holePaint);
  }

  @override
  bool shouldRepaint(covariant SpinningVinylPainter oldDelegate) =>
      oldDelegate.rotation != rotation || oldDelegate.color != color;
}