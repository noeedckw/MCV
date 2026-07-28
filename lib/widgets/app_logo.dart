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
        // Beaucoup moins arrondi qu'un cercle : un rayon proportionnel
        // à la taille, façon icône d'app plutôt que pastille ronde.
        borderRadius: BorderRadius.circular(size * 0.16),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
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