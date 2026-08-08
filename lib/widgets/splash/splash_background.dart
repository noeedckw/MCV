import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'painters/concentric_waves_painter.dart';
import 'painters/vinyl_groove_painter.dart';
import 'splash_style.dart';

/// Affiche le style de fond tiré au hasard au lancement de l'app (voir
/// `SplashRandomization`). N'inclut PAS le disque vinyle tournant en
/// fond, qui est lui toujours affiché indépendamment de ce style (voir
/// `SpinningVinylPainter`, utilisé directement par `SplashGate`).
class SplashBackground extends StatelessWidget {
  final SplashStyle style;
  final Animation<double> animation;
  final Color accentColor;
  final Color accentColorSecondary;
  final List<BlurDot> dots;
  final double width;
  final double height;

  const SplashBackground({
    super.key,
    required this.style,
    required this.animation,
    required this.accentColor,
    required this.accentColorSecondary,
    required this.dots,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case SplashStyle.blurDots:
        return _BlurDots(dots: dots, width: width, height: height);
      case SplashStyle.vinylGroove:
        return _VinylGroove(
          animation: animation,
          color: accentColor,
          width: width,
          height: height,
        );
      case SplashStyle.concentricWaves:
        return _ConcentricWaves(
          animation: animation,
          color: accentColor,
          width: width,
          height: height,
        );
      case SplashStyle.auroraGradient:
        return _AuroraGradient(
          animation: animation,
          color: accentColor,
          colorSecondary: accentColorSecondary,
        );
    }
  }
}

class _BlurDots extends StatelessWidget {
  final List<BlurDot> dots;
  final double width;
  final double height;

  const _BlurDots({
    required this.dots,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
      child: Stack(
        children: dots.map((dot) {
          return Positioned(
            left: dot.dx * width - dot.size / 2,
            top: dot.dy * height - dot.size / 2,
            child: Container(
              width: dot.size,
              height: dot.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dot.color.withValues(alpha: 0.5),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _VinylGroove extends StatelessWidget {
  final Animation<double> animation;
  final Color color;
  final double width;
  final double height;

  const _VinylGroove({
    required this.animation,
    required this.color,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return CustomPaint(
          size: Size(width, height),
          painter: VinylGroovePainter(
            color: color,
            rotation: animation.value * 2 * math.pi,
          ),
        );
      },
    );
  }
}

class _ConcentricWaves extends StatelessWidget {
  final Animation<double> animation;
  final Color color;
  final double width;
  final double height;

  const _ConcentricWaves({
    required this.animation,
    required this.color,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return CustomPaint(
          size: Size(width, height),
          painter: ConcentricWavesPainter(
            color: color,
            phase: animation.value,
          ),
        );
      },
    );
  }
}

class _AuroraGradient extends StatelessWidget {
  final Animation<double> animation;
  final Color color;
  final Color colorSecondary;

  const _AuroraGradient({
    required this.animation,
    required this.color,
    required this.colorSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final angle = animation.value * 2 * math.pi;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(math.cos(angle), math.sin(angle)),
                end: Alignment(-math.cos(angle), -math.sin(angle)),
                colors: [
                  color.withValues(alpha: 0.5),
                  colorSecondary.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}