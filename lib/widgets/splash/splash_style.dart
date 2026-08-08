import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Style de fond du splash. Un seul est tiré au hasard à chaque
/// lancement de l'app, comme les taches de couleur l'étaient déjà —
/// l'idée est juste étendue à plusieurs ambiances visuelles possibles.
/// Le disque vinyle qui tourne (SpinningVinylPainter) est lui TOUJOURS
/// affiché, en dessous de ce style, quel que soit le tirage.
enum SplashStyle { blurDots, vinylGroove, concentricWaves, auroraGradient }

/// Une tache de couleur floue du fond, position/couleur/taille générées
/// aléatoirement à chaque lancement de l'app. Utilisée uniquement quand
/// le style tiré est [SplashStyle.blurDots].
class BlurDot {
  final Color color;
  final double size;
  final double dx; // position fractionnelle horizontale (0.0 - 1.0)
  final double dy; // position fractionnelle verticale (0.0 - 1.0)

  const BlurDot({
    required this.color,
    required this.size,
    required this.dx,
    required this.dy,
  });
}

/// Couleur de fond de référence du splash. Utilisée à la fois pour le
/// fond plein (Material) et pour le dégradé de raccord en haut d'écran
/// (voir StatusBarFade) — garder une seule constante évite tout
/// désaccord de teinte entre les deux si elle change un jour.
const Color splashBackgroundColor = Color(0xFF0A0910);

/// Couleur du fondu en haut d'écran, VOLONTAIREMENT du noir pur et non
/// splashBackgroundColor : la status bar iOS est toujours noire pure,
/// donc le raccord doit matcher #000000 exactement, pas la teinte
/// légèrement violette du reste du splash.
const Color statusBarFadeColor = Color(0xFF000000);

/// Palette large et vive : les couleurs piochées dedans restent
/// harmonieuses entre elles même en combinaison aléatoire.
const List<Color> splashDotPalette = [
  Color(0xFF7C4DFF), // violet
  Color(0xFF2979FF), // bleu
  Color(0xFF00BFA5), // turquoise
  Color(0xFFFF4081), // rose
  Color(0xFFFF6D00), // orange
  Color(0xFFAA00FF), // magenta
  Color(0xFF00E5FF), // cyan
  Color(0xFFFFD600), // jaune doré
  Color(0xFF00C853), // vert
];

/// Résultat d'un tirage aléatoire complet des couleurs et du style du
/// splash, effectué une fois par lancement de l'app dans `initState`.
class SplashRandomization {
  final SplashStyle style;
  final Color accentColor;
  final Color accentColorSecondary;
  final Color vinylColor;
  final List<BlurDot> dots;

  const SplashRandomization({
    required this.style,
    required this.accentColor,
    required this.accentColorSecondary,
    required this.vinylColor,
    required this.dots,
  });

  factory SplashRandomization.random() {
    final random = math.Random();

    final style = SplashStyle.values[random.nextInt(SplashStyle.values.length)];
    final accentColor = splashDotPalette[random.nextInt(splashDotPalette.length)];

    // Deuxième teinte pour les styles à 2 couleurs (aurora), toujours
    // décalée d'au moins 3 crans dans la palette pour éviter un dégradé
    // presque monochrome.
    final accentColorSecondary = splashDotPalette[
        (splashDotPalette.indexOf(accentColor) + 3 + random.nextInt(3)) %
            splashDotPalette.length];

    // Couleur du vinyle tirée indépendamment de accentColor, pour que le
    // disque et le fond de style puissent avoir 2 teintes différentes
    // (plus riche visuellement qu'une seule couleur partout).
    final vinylColor = splashDotPalette[random.nextInt(splashDotPalette.length)];

    // Génère 3 à 5 taches, couleurs et positions différentes à chaque
    // lancement de l'app (utilisées seulement si style == blurDots).
    final dotCount = 3 + random.nextInt(3);
    final dots = List.generate(dotCount, (_) {
      return BlurDot(
        color: splashDotPalette[random.nextInt(splashDotPalette.length)],
        size: 110 + random.nextDouble() * 190,
        dx: random.nextDouble(),
        dy: random.nextDouble(),
      );
    });

    return SplashRandomization(
      style: style,
      accentColor: accentColor,
      accentColorSecondary: accentColorSecondary,
      vinylColor: vinylColor,
      dots: dots,
    );
  }
}