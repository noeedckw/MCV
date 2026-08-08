import 'package:flutter/material.dart';

import '../app_logo.dart';
import 'splash_logo_animations.dart';

/// Logo animé du splash : halo lumineux qui flashe pendant la sortie, et
/// logo qui respire doucement en boucle tant que l'utilisateur n'a pas
/// tapé, puis qui réagit au tap (léger "press") avant de zoomer vers le
/// spectateur en s'estompant.
class SplashLogo extends StatelessWidget {
  final double logoSize;
  final double glowSize;
  final bool exiting;
  final AnimationController breatheController;
  final AnimationController exitController;
  final SplashLogoAnimations animations;

  const SplashLogo({
    super.key,
    required this.logoSize,
    required this.glowSize,
    required this.exiting,
    required this.breatheController,
    required this.exitController,
    required this.animations,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: glowSize,
      height: glowSize,
      child: RepaintBoundary(
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: exitController,
              builder: (context, _) {
                if (!exiting) return const SizedBox.shrink();
                return Opacity(
                  opacity: animations.glowOpacity.value,
                  child: Container(
                    width: glowSize,
                    height: glowSize,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Colors.white, Colors.transparent],
                      ),
                    ),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: Listenable.merge([breatheController, exitController]),
              builder: (context, child) {
                final scale = exiting
                    ? animations.pressScale.value * animations.zoomScale.value
                    : animations.breatheScale.value;
                final opacity = exiting ? animations.exitOpacity.value : 1.0;

                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    filterQuality: FilterQuality.high,
                    child: child,
                  ),
                );
              },
              child: AppLogo(size: logoSize),
            ),
          ],
        ),
      ),
    );
  }
}