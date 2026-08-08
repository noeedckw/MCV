import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'splash/painters/spinning_vinyl_painter.dart';
import 'splash/splash_background.dart';
import 'splash/splash_geometry.dart';
import 'splash/splash_logo.dart';
import 'splash/splash_logo_animations.dart';
import 'splash/splash_style.dart';
import 'splash/splash_tap_text.dart';
import 'splash/status_bar_fade.dart';

/// Écran affiché au lancement de l'app (utile surtout en PWA standalone
/// iOS). L'utilisateur tape sur le logo pour "entrer" : ce tap déclenche
/// une animation de zoom + fade du logo, qui révèle progressivement
/// l'écran suivant déjà en place derrière.
///
/// Usage dans main.dart :
///   home: SplashGate(child: MonEcranPrincipal()),
class SplashGate extends StatefulWidget {
  final Widget child;

  const SplashGate({super.key, required this.child});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate>
    with TickerProviderStateMixin {
  bool _entered = false;
  bool _exiting = false;
  bool _showText = false;
  bool _showChild = false;

  late final AnimationController _breatheController;
  late final AnimationController _exitController;
  late final AnimationController _textController;

  // Pilote toutes les animations de fond (vinylGroove, concentricWaves,
  // auroraGradient). Une seule boucle continue de 14s, chaque style en
  // dérive ce dont il a besoin (rotation, phase, angle...) — pas besoin
  // d'un controller séparé par style.
  late final AnimationController _backgroundController;

  // Rotation lente et continue du disque vinyle en fond, toujours
  // présent quel que soit le style tiré au sort. Durée longue (20s/tour)
  // pour une rotation perçue comme fluide et non-mécanique.
  late final AnimationController _vinylRotationController;

  late final SplashLogoAnimations _logoAnimations;
  late final SplashRandomization _random;

  @override
  void initState() {
    super.initState();

    _random = SplashRandomization.random();

    // Laisse le tout premier frame du splash (ses propres animations) se
    // poser tranquillement avant de monter le contenu réel derrière ->
    // évite la saccade de construction initiale qui compétitionne avec
    // le début des animations de respiration/fond.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _showChild = true);
    });

    // Respiration en boucle, tant que l'utilisateur n'a pas tapé.
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _vinylRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Le texte reste invisible pendant 10 secondes, puis apparaît
    // doucement en fondu, comme une pensée qui émerge.
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    Future.delayed(const Duration(seconds: 10), () {
      if (!mounted || _exiting) return;
      setState(() => _showText = true);
      _textController.forward();
    });

    // Séquence de sortie au tap, durée légèrement allongée (750ms ->
    // 900ms) pour un rendu moins saccadé sur mobile — voir
    // SplashLogoAnimations pour le détail des courbes utilisées.
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoAnimations = SplashLogoAnimations.build(
      breatheController: _breatheController,
      exitController: _exitController,
    );

    _exitController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _entered = true);
      }
    });
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _exitController.dispose();
    _textController.dispose();
    _backgroundController.dispose();
    _vinylRotationController.dispose();
    super.dispose();
  }

  void _enter() {
    if (_exiting) return;
    setState(() => _exiting = true);

    _breatheController.stop();
    _backgroundController.stop();
    _vinylRotationController.stop();

    // Zoom + fade du logo jusqu'au bout, en une seule course : l'écran
    // suivant (déjà monté derrière) apparaît en fondu au fur et à mesure,
    // sans rideau noir intermédiaire.
    _exitController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_showChild)
        // Écran final, en dessous, révélé en fondu à mesure que le
        // splash disparaît.
          AnimatedBuilder(
            animation: _exitController,
            builder: (context, child) {
              final revealProgress = Curves.easeIn.transform(
                _exitController.value.clamp(0.0, 1.0),
              );
              return Opacity(opacity: revealProgress, child: child);
            },
            child: widget.child,
          ),

        if (!_entered)
          Material(
            color: splashBackgroundColor,
            child: SizedBox.expand(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _enter,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final height = constraints.maxHeight;
                    final geometry = SplashGeometry.of(width, height);

                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: splashBackgroundColor,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Disque vinyle qui tourne, toujours présent en
                          // fond quel que soit le style tiré au sort.
                          RepaintBoundary(
                            child: AnimatedBuilder(
                              animation: _vinylRotationController,
                              builder: (context, _) {
                                return CustomPaint(
                                  size: Size(width, height),
                                  painter: SpinningVinylPainter(
                                    color: _random.vinylColor,
                                    rotation:
                                        _vinylRotationController.value *
                                            2 *
                                            math.pi,
                                  ),
                                );
                              },
                            ),
                          ),

                          // Fond, style tiré au hasard au lancement.
                          RepaintBoundary(
                            child: SplashBackground(
                              style: _random.style,
                              animation: _backgroundController,
                              accentColor: _random.accentColor,
                              accentColorSecondary: _random.accentColorSecondary,
                              dots: _random.dots,
                              width: width,
                              height: height,
                            ),
                          ),

                          // Voile sombre par-dessus le fond pour garder une
                          // lecture cohérente du logo peu importe le style
                          // tiré.
                          Container(
                            color: splashBackgroundColor.withValues(alpha: 0.45),
                          ),

                          // Logo, calé exactement sur le centre du rond
                          // central du vinyle (même point que le label
                          // dessiné par SpinningVinylPainter).
                          Positioned(
                            left: width / 2 - geometry.glowSize / 2,
                            top: geometry.vinylCenterY - geometry.glowSize / 2,
                            child: SplashLogo(
                              logoSize: geometry.logoSize,
                              glowSize: geometry.glowSize,
                              exiting: _exiting,
                              breatheController: _breatheController,
                              exitController: _exitController,
                              animations: _logoAnimations,
                            ),
                          ),

                          // Texte, positionné indépendamment du logo :
                          // toujours au même point de départ (centre du
                          // vinyle), puis décalé vers le bas d'une distance
                          // relative à logoSize, pour rester cohérent quelle
                          // que soit la taille du logo.
                          Positioned(
                            left: 0,
                            right: 0,
                            top: geometry.vinylCenterY + geometry.logoSize * 0.8,
                            child: Center(
                              child: SplashTapText(
                                textController: _textController,
                                showText: _showText,
                                exiting: _exiting,
                              ),
                            ),
                          ),

                          // Fondu noir en haut d'écran, pour matcher la
                          // status bar native. Uniquement sur web (PWA iOS
                          // notamment) : inutile sur app native
                          // Android/iOS, il n'y a pas de status bar web à
                          // raccorder. Toujours en dernier dans le Stack =
                          // toujours au-dessus de tout le reste quand
                          // présent.
                          if (kIsWeb) const StatusBarFade(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}