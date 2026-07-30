import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_logo.dart';
import 'keyboard_warmup_stub.dart'
    if (dart.library.js_interop) 'keyboard_warmup_web.dart';

// warmupKeyboard() pointe vers la vraie implémentation JS interop en
// compilation web, et vers un no-op sur toutes les autres plateformes
// (natif iOS/Android/desktop) — import conditionnel au niveau fichier,
// donc pas d'erreur de compilation en dehors du web.

/// Une tache de couleur floue du fond, position/couleur/taille générées
/// aléatoirement à chaque lancement de l'app.
class _BlurDot {
  final Color color;
  final double size;
  final double dx; // position fractionnelle horizontale (0.0 - 1.0)
  final double dy; // position fractionnelle verticale (0.0 - 1.0)

  const _BlurDot({
    required this.color,
    required this.size,
    required this.dx,
    required this.dy,
  });
}

/// Écran affiché au lancement de l'app (utile surtout en PWA standalone
/// iOS). L'utilisateur tape sur le logo pour "entrer" : ce tap déclenche
/// une animation de zoom + fade, ET sert de façon invisible à corriger un
/// bug connu de décalage de clic en mode standalone iOS, en forçant un
/// vrai cycle clavier au moment de la transition.
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

  late final AnimationController _breatheController;
  late final AnimationController _exitController;
  late final AnimationController _textController;

  late final Animation<double> _breatheScale;
  late final Animation<double> _pressScale;
  late final Animation<double> _zoomScale;
  late final Animation<double> _exitOpacity;
  late final Animation<double> _glowOpacity;

  late final List<_BlurDot> _dots;

  // Palette large et vive : les couleurs piochées dedans restent
  // harmonieuses entre elles même en combinaison aléatoire.
  static const List<Color> _dotPalette = [
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

  @override
  void initState() {
    super.initState();

    final random = math.Random();

    // Génère 3 à 5 taches, couleurs et positions différentes à chaque
    // lancement de l'app.
    final dotCount = 3 + random.nextInt(3);
    _dots = List.generate(dotCount, (_) {
      return _BlurDot(
        color: _dotPalette[random.nextInt(_dotPalette.length)],
        size: 110 + random.nextDouble() * 190,
        dx: random.nextDouble(),
        dy: random.nextDouble(),
      );
    });

    // Respiration en boucle, tant que l'utilisateur n'a pas tapé.
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _breatheScale = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );

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

    // Séquence de sortie au tap : léger "press", puis zoom massif vers
    // le spectateur pendant que tout s'estompe.
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _pressScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.88).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 12,
      ),
      TweenSequenceItem(tween: ConstantTween(0.88), weight: 3),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 85),
    ]).animate(_exitController);

    _zoomScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 15),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 22.0).chain(
          CurveTween(curve: Curves.easeInExpo),
        ),
        weight: 85,
      ),
    ]).animate(_exitController);

    _exitOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 60,
      ),
    ]).animate(_exitController);

    // Flash lumineux qui accompagne le zoom, pour du punch visuel.
    _glowOpacity = TweenSequence<double>([
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
    ]).animate(_exitController);

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
    super.dispose();
  }

  void _enter() {
    if (_exiting) return;
    setState(() => _exiting = true);

    // Le warmup doit être appelé ici, dans le handler de tap lui-même,
    // pour rester dans la fenêtre de "vrai geste utilisateur" qu'iOS
    // exige pour autoriser l'ouverture du clavier.
    try {
      warmupKeyboard();
    } catch (_) {}

    _breatheController.stop();
    _exitController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Écran final, en dessous, révélé en fondu à mesure que le
        // splash disparaît.
        if (_exiting)
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
            color: const Color(0xFF0A0910),
            child: SizedBox.expand(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _enter,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final height = constraints.maxHeight;

                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: const Color(0xFF0A0910),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Taches de couleur floues, en fond.
                          ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: 90,
                              sigmaY: 90,
                            ),
                            child: Stack(
                              children: _dots.map((dot) {
                                return Positioned(
                                  left: dot.dx * width - dot.size / 2,
                                  top: dot.dy * height - dot.size / 2,
                                  child: Container(
                                    width: dot.size,
                                    height: dot.size,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: dot.color.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          // Voile sombre par-dessus les taches pour garder
                          // un fond globalement assombri et le logo lisible.
                          Container(
                            color: const Color(0xFF0A0910).withValues(
                              alpha: 0.45,
                            ),
                          ),

                          // Logo + texte, au premier plan.
                          Center(
                            child: AnimatedBuilder(
                              animation: Listenable.merge([
                                _breatheController,
                                _exitController,
                                _textController,
                              ]),
                              builder: (context, _) {
                                final scale = _exiting
                                    ? _pressScale.value * _zoomScale.value
                                    : _breatheScale.value;
                                final opacity = _exiting
                                    ? _exitOpacity.value
                                    : 1.0;
                                final textOpacity = _showText && !_exiting
                                    ? Curves.easeOut.transform(
                                            _textController.value,
                                          ) *
                                          0.55
                                    : 0.0;

                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (_exiting)
                                      Opacity(
                                        opacity: _glowOpacity.value,
                                        child: Container(
                                          width: 400,
                                          height: 400,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: RadialGradient(
                                              colors: [
                                                Colors.white,
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    Opacity(
                                      opacity: opacity,
                                      child: Transform.scale(
                                        scale: scale,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const AppLogo(size: 150),
                                            const SizedBox(height: 40),
                                            Opacity(
                                              opacity: textOpacity,
                                              child: Column(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: [
                                                  const Text(
                                                    'my collection of vinyl',
                                                    textAlign:
                                                        TextAlign.center,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w300,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                      letterSpacing: 1.5,
                                                      decoration:
                                                          TextDecoration.none,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 20),
                                                  const Text(
                                                    'tap to enter',
                                                    textAlign:
                                                        TextAlign.center,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w300,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                      letterSpacing: 1,
                                                      decoration:
                                                          TextDecoration.none,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
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