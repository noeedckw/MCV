import 'dart:math' as math;
import 'package:flutter/material.dart';

class VinylIcon extends StatelessWidget {
  const VinylIcon({super.key, this.size = 24, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _VinylPainter(
        color ?? IconTheme.of(context).color ?? Colors.white,
      ),
    );
  }
}

class SearchVinylIcon extends StatelessWidget {
  const SearchVinylIcon({super.key, this.size = 24, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _SearchPainter(
        color ?? IconTheme.of(context).color ?? Colors.white,
      ),
    );
  }
}

class _VinylPainter extends CustomPainter {
  const _VinylPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.55
      ..strokeCap = StrokeCap.round;

    //------------------------------------------
    // Cercle extérieur
    //------------------------------------------

    canvas.drawCircle(const Offset(12, 12), 10, stroke);

    //------------------------------------------
    // Reflet
    //------------------------------------------

    canvas.drawArc(
      Rect.fromCircle(center: Offset(12, 12), radius: 6.8),
      math.pi * 1.12,
      math.pi * 0.28,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.40
        ..strokeCap = StrokeCap.round,
    );

    //------------------------------------------
    // Petit point du reflet
    //------------------------------------------

    canvas.drawCircle(const Offset(13.0, 5.4), 0.60, Paint()..color = color);

    //------------------------------------------
    // Arc inférieur
    //------------------------------------------

    canvas.drawArc(
      Rect.fromCircle(center: Offset(12, 12), radius: 6.8),
      math.pi * 0.05,
      math.pi * 0.41,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.40
        ..strokeCap = StrokeCap.round,
    );

    //------------------------------------------
    // Label central
    //------------------------------------------

    canvas.drawCircle(const Offset(12, 12), 2.55, Paint()..color = color);

    //------------------------------------------
    // Trou du disque
    //------------------------------------------

    canvas.drawCircle(
      const Offset(12, 12),
      0.55,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SearchPainter extends CustomPainter {
  const _SearchPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.55
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // Cercle
    path.addArc(
      Rect.fromCircle(center: const Offset(10.2, 10.2), radius: 7.3),
      math.pi * 0.45,
      math.pi * 1.80,
    );

    // Manche
    path.moveTo(15.5, 15.5);
    path.lineTo(20.4, 20.4);

    // Dessin en une seule fois
    canvas.drawPath(path, stroke);

    //------------------------------------------
    // Reflet
    //------------------------------------------

    canvas.drawArc(
      Rect.fromCircle(center: Offset(10.2, 10.2), radius: 4.2),
      math.pi * 1.30,
      math.pi * 0.35,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.40
        ..strokeCap = StrokeCap.round,
    );

    //------------------------------------------
    // Petit point
    //------------------------------------------

    canvas.drawCircle(const Offset(13.95, 8.25), 0.60, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
