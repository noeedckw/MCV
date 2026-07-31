import 'package:flutter/material.dart';

import 'vinyl_icon.dart';

/// Logo de l'app, réutilisé dans le header et sur la dernière frame
/// de l'onboarding. Si l'asset n'est pas encore présent, on retombe
/// proprement sur l'icône vinyle générique pour ne rien casser.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 40});

  static const _assetPath = 'assets/images/mcv_logo.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.25),
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.16),
            const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.04),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        _assetPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Center(
          child: VinylIcon(color: Colors.white, size: size * 0.6),
        ),
      ),
    );
  }
}