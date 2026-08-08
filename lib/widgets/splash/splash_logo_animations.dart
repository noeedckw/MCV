import 'package:flutter/material.dart';

/// Regroupe toutes les animations dérivées du logo (respiration, press,
/// zoom de sortie, fade, glow), construites à partir des deux
/// controllers qui pilotent le splash : `breatheController` tourne en
/// boucle tant que l'utilisateur n'a pas tapé, `exitController` joue une
/// seule fois au tap.
class SplashLogoAnimations {
  final Animation<double> breatheScale;
  final Animation<double> pressScale;
  final Animation<double> zoomScale;
  final Animation<double> exitOpacity;
  final Animation<double> glowOpacity;

  SplashLogoAnimations._({
    required this.breatheScale,
    required this.pressScale,
    required this.zoomScale,
    required this.exitOpacity,
    required this.glowOpacity,
  });

  factory SplashLogoAnimations.build({
    required AnimationController breatheController,
    required AnimationController exitController,
  }) {
    final breatheScale = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: breatheController, curve: Curves.easeInOut),
    );

    // Séquence de sortie au tap : léger "press", puis zoom massif vers le
    // spectateur pendant que tout s'estompe. Courbe moins extrême que
    // easeInExpo : easeInExpo concentre presque tout le mouvement sur les
    // toutes dernières frames, ce qui demande un rendu très lourd sur
    // très peu de temps -> perçu comme saccadé sur mobile.
    final pressScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.88).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 12,
      ),
      // Retour progressif, easeInOut pour une dérivée nulle aux deux
      // bouts (raccord fluide avec le press qui précède ET avec le zoom
      // qui suit).
      TweenSequenceItem(
        tween: Tween(begin: 0.88, end: 1.0).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 18,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
    ]).animate(exitController);

    final zoomScale = TweenSequence<double>([
      // Poids aligné sur la fin du press-release ci-dessus (12+18=30) :
      // le zoom ne démarre qu'une fois le logo revenu net à sa taille
      // normale, au lieu de chevaucher visiblement les deux mouvements.
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 30),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 12.0).chain(
          CurveTween(curve: Curves.easeInCubic),
        ),
        weight: 70,
      ),
    ]).animate(exitController);

    final exitOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 60,
      ),
    ]).animate(exitController);

    // Flash lumineux qui accompagne le zoom, pour du punch visuel.
    final glowOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.35).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.35, end: 0.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 75,
      ),
    ]).animate(exitController);

    return SplashLogoAnimations._(
      breatheScale: breatheScale,
      pressScale: pressScale,
      zoomScale: zoomScale,
      exitOpacity: exitOpacity,
      glowOpacity: glowOpacity,
    );
  }
}