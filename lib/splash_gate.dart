import 'package:flutter/material.dart';

import 'widgets/app_logo.dart';
import 'keyboard_warmup_stub.dart'
    if (dart.library.js_interop) 'keyboard_warmup_web.dart';

// warmupKeyboard() pointe vers la vraie implémentation JS interop en
// compilation web, et vers un no-op sur toutes les autres plateformes
// (natif iOS/Android/desktop) — import conditionnel au niveau fichier,
// donc pas d'erreur de compilation en dehors du web.

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

  late final AnimationController _breatheController;
  late final AnimationController _exitController;

  late final Animation<double> _breatheScale;
  late final Animation<double> _pressScale;
  late final Animation<double> _zoomScale;
  late final Animation<double> _exitOpacity;
  late final Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();

    // Respiration en boucle, tant que l'utilisateur n'a pas tapé.
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _breatheScale = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );

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
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _enter,
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.3, -0.6),
                  radius: 1.4,
                  colors: [Color(0xFF221F2B), Color(0xFF121114)],
                ),
              ),
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _breatheController,
                  _exitController,
                ]),
                builder: (context, _) {
                  final scale = _exiting
                      ? _pressScale.value * _zoomScale.value
                      : _breatheScale.value;
                  final opacity = _exiting ? _exitOpacity.value : 1.0;

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
                                colors: [Colors.white, Colors.transparent],
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
                              const AppLogo(size: 110),
                              const SizedBox(height: 32),
                              Text(
                                'MY COLLECTION OF VINYL',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.5,
                                ),
                              ),
                              const SizedBox(height: 48),
                              if (!_exiting)
                                AnimatedBuilder(
                                  animation: _breatheController,
                                  builder: (context, child) {
                                    final o =
                                        0.4 + (_breatheController.value * 0.5);
                                    return Opacity(opacity: o, child: child);
                                  },
                                  child: Text(
                                    'Tap to enter',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.6,
                                      ),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                    ),
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
          ),
      ],
    );
  }
}