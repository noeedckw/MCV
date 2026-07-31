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

/// Style de fond du splash. Un seul est tiré au hasard à chaque
/// lancement de l'app, comme les taches de couleur l'étaient déjà —
/// l'idée est juste étendue à plusieurs ambiances visuelles possibles.
/// Le disque vinyle qui tourne (_SpinningVinylPainter) est lui TOUJOURS
/// affiché, en dessous de ce style, quel que soit le tirage.
enum _SplashStyle { blurDots, vinylGroove, concentricWaves, auroraGradient }

/// Une tache de couleur floue du fond, position/couleur/taille générées
/// aléatoirement à chaque lancement de l'app. Utilisée uniquement quand
/// le style tiré est [_SplashStyle.blurDots].
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

/// Couleur de fond de référence du splash. Utilisée à la fois pour le
/// fond plein (Material) et pour le dégradé de raccord en haut d'écran
/// (voir _buildStatusBarFade) — garder une seule constante évite tout
/// désaccord de teinte entre les deux si elle change un jour.
const Color _splashBackgroundColor = Color(0xFF0A0910);

/// Couleur du fondu en haut d'écran, VOLONTAIREMENT du noir pur et non
/// _splashBackgroundColor : la status bar iOS est toujours noire pure,
/// donc le raccord doit matcher #000000 exactement, pas la teinte
/// légèrement violette du reste du splash.
const Color _statusBarFadeColor = Color(0xFF000000);

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
  // présent quel que soit le _style tiré. Durée longue (20s/tour) pour
  // une rotation perçue comme fluide et non-mécanique.
  late final AnimationController _vinylRotationController;

  late final Animation<double> _breatheScale;
  late final Animation<double> _pressScale;
  late final Animation<double> _zoomScale;
  late final Animation<double> _exitOpacity;
  late final Animation<double> _glowOpacity;

  late final List<_BlurDot> _dots;
  late final _SplashStyle _style;
  late final Color _accentColor;
  late final Color _accentColorSecondary;
  late final Color _vinylColor;

  // Fraction verticale du centre du vinyle (utilisée à la fois par le
  // painter du disque ET par le positionnement du logo, pour qu'ils
  // soient garantis alignés peu importe la taille de l'écran).
  static const double _vinylCenterYFraction = 0.42;

  // Ratio entre le rayon du disque et le "longestSide" du conteneur
  // (même valeur que dans _SpinningVinylPainter / _VinylGroovePainter).
  static const double _discRadiusRatio = 0.62;

  // Ratio entre le rayon du label central et le rayon du disque (même
  // valeur que dans _SpinningVinylPainter).
  static const double _labelRadiusRatio = 0.22;

  // Le logo doit être légèrement plus petit que le rond du label, pour
  // matcher visuellement sans le déborder. 1.0 = taille identique.
  static const double _logoToLabelRatio = 0.75;

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

    _style = _SplashStyle.values[random.nextInt(_SplashStyle.values.length)];
    _accentColor = _dotPalette[random.nextInt(_dotPalette.length)];
    // Deuxième teinte pour les styles à 2 couleurs (aurora), toujours
    // décalée d'au moins 3 crans dans la palette pour éviter un dégradé
    // presque monochrome.
    _accentColorSecondary = _dotPalette[
        (_dotPalette.indexOf(_accentColor) + 3 + random.nextInt(3)) %
            _dotPalette.length];

    // Couleur du vinyle tirée indépendamment de _accentColor, pour que
    // le disque et le fond de style puissent avoir 2 teintes différentes
    // (plus riche visuellement qu'une seule couleur partout).
    _vinylColor = _dotPalette[random.nextInt(_dotPalette.length)];

    // Génère 3 à 5 taches, couleurs et positions différentes à chaque
    // lancement de l'app (utilisées seulement si _style == blurDots).
    final dotCount = 3 + random.nextInt(3);
    _dots = List.generate(dotCount, (_) {
      return _BlurDot(
        color: _dotPalette[random.nextInt(_dotPalette.length)],
        size: 110 + random.nextDouble() * 190,
        dx: random.nextDouble(),
        dy: random.nextDouble(),
      );
    });

    // Laisse le tout premier frame du splash (ses propres animations)
    // se poser tranquillement avant de monter le contenu réel derrière
    // -> évite la saccade de construction initiale qui compétitionne
    // avec le début des animations de respiration/fond.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _showChild = true);
    });

    // Respiration en boucle, tant que l'utilisateur n'a pas tapé.
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _breatheScale = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );

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

    // Séquence de sortie au tap : léger "press", puis zoom massif vers
    // le spectateur pendant que tout s'estompe. Durée légèrement
    // allongée (750ms -> 900ms) et courbe moins extrême que
    // easeInExpo : easeInExpo concentre presque tout le mouvement sur
    // les toutes dernières frames, ce qui demande un rendu très lourd
    // sur très peu de temps -> perçu comme saccadé sur mobile.
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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
        // Scale max réduit (22 -> 12) et courbe easeInCubic (au lieu
        // de easeInExpo) : mouvement toujours rapide et dramatique,
        // mais réparti plus régulièrement sur la durée -> beaucoup
        // moins coûteux à rendre frame par frame, donc plus fluide.
        tween: Tween(begin: 1.0, end: 12.0).chain(
          CurveTween(curve: Curves.easeInCubic),
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
    _backgroundController.dispose();
    _vinylRotationController.dispose();
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
    _backgroundController.stop();
    _vinylRotationController.stop();
    _exitController.forward();
  }

  Widget _buildBlurDots(double width, double height) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
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
                color: dot.color.withValues(alpha: 0.5),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVinylGroove(double width, double height) {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, _) {
        return CustomPaint(
          size: Size(width, height),
          painter: _VinylGroovePainter(
            color: _accentColor,
            rotation: _backgroundController.value * 2 * math.pi,
          ),
        );
      },
    );
  }

  Widget _buildConcentricWaves(double width, double height) {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, _) {
        return CustomPaint(
          size: Size(width, height),
          painter: _ConcentricWavesPainter(
            color: _accentColor,
            phase: _backgroundController.value,
          ),
        );
      },
    );
  }

  Widget _buildAuroraGradient(double width, double height) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, _) {
          final angle = _backgroundController.value * 2 * math.pi;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(math.cos(angle), math.sin(angle)),
                end: Alignment(-math.cos(angle), -math.sin(angle)),
                colors: [
                  _accentColor.withValues(alpha: 0.5),
                  _accentColorSecondary.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackground(double width, double height) {
    switch (_style) {
      case _SplashStyle.blurDots:
        return _buildBlurDots(width, height);
      case _SplashStyle.vinylGroove:
        return _buildVinylGroove(width, height);
      case _SplashStyle.concentricWaves:
        return _buildConcentricWaves(width, height);
      case _SplashStyle.auroraGradient:
        return _buildAuroraGradient(width, height);
    }
  }

  /// Fondu noir statique tout en haut de l'écran, dont le rôle est
  /// purement cosmétique : faire un raccord visuel avec la status bar
  /// native iOS (toujours noire/opaque au-dessus du splash en mode PWA
  /// standalone), pour qu'on ne voie jamais de bande nette entre les
  /// deux. Placé au-dessus de tout le reste (vinyle, style de fond,
  /// logo, texte), fixe pendant toute la séquence (respiration comme
  /// sortie), et transparent aux taps pour ne jamais gêner le
  /// "tap to enter".
  ///
  /// IMPORTANT : implémenté avec un empilement de bandes pleines
  /// (Container + alpha), PAS avec un LinearGradient/shader. Un
  /// gradient à beaucoup de stops rapprochés s'affiche très bien sur
  /// desktop (Chrome dev, Chrome/Edge sur PC) mais peut ne pas
  /// s'afficher du tout sur WebKit iOS (Safari ET "Chrome iOS", qui
  /// utilise le même moteur WebKit sur iOS par contrainte Apple) —
  /// bug de rendu shader propre au GPU mobile. Un simple alpha
  /// blending de rectangles pleins n'a pas ce problème, il est
  /// supporté nativement partout.
  Widget _buildStatusBarFade(BuildContext context) {
    // On NE se base plus uniquement sur MediaQuery.padding.top : sur
    // Flutter web/PWA iOS, cette valeur peut remonter à 0 selon le
    // moment du build, ce qui rendait la zone opaque quasi invisible.
    // On prend le max entre la vraie safe-area (si dispo) et un
    // plancher fixe, pour garantir un résultat visible sur tous les
    // appareils/contextes.
    final topInset = MediaQuery.of(context).padding.top;
    final solidHeight = math.max(topInset, 40.0);
    // TEMPORAIRE / TEST : fondu exagéré jusqu'à environ la moitié de
    // l'écran, pour vérifier qu'il est bien visible sur iPhone/Android
    // avant de le réduire à une taille définitive plus discrète.
    final screenHeight = MediaQuery.of(context).size.height;
    final fadeLength = (screenHeight * 0.5) - solidHeight;
    const bandCount = 16;
    final bandHeight = fadeLength / bandCount;

    final bands = <Widget>[];
    for (int i = 0; i < bandCount; i++) {
      final t = i / bandCount; // 0..1 le long du fondu
      // Courbe inversée par rapport à avant : opacity reste PROCHE DE
      // 1 (noir plein) pendant la majeure partie du fondu, et ne
      // chute vraiment que sur la toute fin. L'ancienne courbe
      // perdait son opacité dès le début, ce qui révélait le fond
      // coloré du splash trop tôt et donnait une impression de gris,
      // pas de noir.
      final opacity = (1 - math.pow(t, 4.0)).toDouble().clamp(0.0, 1.0);

      bands.add(
        Positioned(
          top: solidHeight + i * bandHeight,
          left: 0,
          right: 0,
          height: bandHeight + 0.5, // léger overlap anti-liseré
          child: ColoredBox(
            color: _statusBarFadeColor.withValues(alpha: opacity),
          ),
        ),
      );
    }

    return IgnorePointer(
      child: Stack(
        children: [
          // Bande 100% opaque, garantie visible même si topInset
          // remonte à 0 dans certains contextes.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: solidHeight,
            child: ColoredBox(color: _statusBarFadeColor),
          ),
          ...bands,
        ],
      ),
    );
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
            color: _splashBackgroundColor,
            child: SizedBox.expand(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _enter,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final height = constraints.maxHeight;

                    // Géométrie du disque vinyle, calculée UNE FOIS ici
                    // avec exactement les mêmes ratios que les painters
                    // (_SpinningVinylPainter / _VinylGroovePainter), pour
                    // garantir que le logo tombe pile sur le rond
                    // central quelle que soit la taille de l'écran.
                    final vinylCenterY = height * _vinylCenterYFraction;
                    final discRadius =
                        math.max(width, height) * _discRadiusRatio;
                    final labelRadius = discRadius * _labelRadiusRatio;

                    // Taille du logo : un peu plus petit que le rond du
                    // label, responsive car dérivée de discRadius.
                    final logoSize =
                        labelRadius * 2 * _logoToLabelRatio;

                    // Glow proportionnel au logo (même ratio qu'avant :
                    // 400 / 140 ≈ 2.85).
                    final glowSize = logoSize * 2.85;

                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: _splashBackgroundColor,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Disque vinyle qui tourne, toujours présent en
                          // fond quel que soit le _style tiré au sort.
                          RepaintBoundary(
                            child: AnimatedBuilder(
                              animation: _vinylRotationController,
                              builder: (context, _) {
                                return CustomPaint(
                                  size: Size(width, height),
                                  painter: _SpinningVinylPainter(
                                    color: _vinylColor,
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
                            child: _buildBackground(width, height),
                          ),

                          // Voile sombre par-dessus le fond pour garder
                          // une lecture cohérente du logo peu importe le
                          // style tiré.
                          Container(
                            color: _splashBackgroundColor.withValues(
                              alpha: 0.45,
                            ),
                          ),

                          // Logo, calé exactement sur le centre du rond
                          // central du vinyle (même point que le label
                          // dessiné par _SpinningVinylPainter).
                          Positioned(
                            left: width / 2 - glowSize / 2,
                            top: vinylCenterY - glowSize / 2,
                            child: SizedBox(
                              width: glowSize,
                              height: glowSize,
                              child: RepaintBoundary(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    AnimatedBuilder(
                                      animation: _exitController,
                                      builder: (context, _) {
                                        if (!_exiting) {
                                          return const SizedBox.shrink();
                                        }
                                        return Opacity(
                                          opacity: _glowOpacity.value,
                                          child: Container(
                                            width: glowSize,
                                            height: glowSize,
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
                                        );
                                      },
                                    ),

                                    AnimatedBuilder(
                                      animation: Listenable.merge([
                                        _breatheController,
                                        _exitController,
                                      ]),
                                      builder: (context, child) {
                                        final scale = _exiting
                                            ? _pressScale.value * _zoomScale.value
                                            : _breatheScale.value;
                                        final opacity = _exiting ? _exitOpacity.value : 1.0;

                                        return Opacity(
                                          opacity: opacity,
                                          child: Transform.scale(
                                            scale: scale,
                                            filterQuality: FilterQuality.low,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: AppLogo(size: logoSize),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Texte, positionné indépendamment du logo :
                          // toujours au même point de départ (centre du
                          // vinyle), puis décalé vers le bas d'une
                          // distance relative à logoSize, pour rester
                          // cohérent quelle que soit la taille du logo.
                          Positioned(
                            left: 0,
                            right: 0,
                            top: vinylCenterY + logoSize * 0.8,
                            child: Center(
                              child: RepaintBoundary(
                                child: AnimatedBuilder(
                                  animation: _textController,
                                  builder: (context, _) {
                                    final textOpacity =
                                        _showText && !_exiting
                                            ? Curves.easeOut.transform(
                                                  _textController.value,
                                                ) *
                                                0.55
                                            : 0.0;

                                    return Opacity(
                                      opacity: textOpacity,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Text(
                                            'my collection of vinyl',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w300,
                                              fontStyle: FontStyle.italic,
                                              letterSpacing: 1.5,
                                              decoration:
                                                  TextDecoration.none,
                                            ),
                                          ),
                                          SizedBox(height: 20),
                                          Text(
                                            'tap to enter',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w300,
                                              fontStyle: FontStyle.italic,
                                              letterSpacing: 1,
                                              decoration:
                                                  TextDecoration.none,
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

                          // Fondu noir en haut d'écran, pour matcher la
                          // status bar native. Toujours en dernier =
                          // toujours au-dessus de tout le reste.
                          _buildStatusBarFade(context),
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

/// Anneaux concentriques façon sillons de vinyle, avec un reflet lumineux
/// qui tourne lentement dessus — effet disque qui tourne sous la
/// lumière. Utilisé uniquement quand _style == vinylGroove.
class _VinylGroovePainter extends CustomPainter {
  final Color color;
  final double rotation;

  _VinylGroovePainter({required this.color, required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final maxRadius = size.longestSide * 0.55;
    const ringCount = 14;

    for (int i = 0; i < ringCount; i++) {
      final t = i / ringCount;
      final radius = maxRadius * (0.25 + 0.75 * t);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = color.withValues(alpha: 0.10 + 0.05 * (1 - t));
      canvas.drawCircle(center, radius, paint);
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final glowPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          color.withValues(alpha: 0.25),
          Colors.transparent,
        ],
        stops: const [0.0, 0.12, 0.24],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: maxRadius));
    canvas.drawCircle(Offset.zero, maxRadius, glowPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _VinylGroovePainter oldDelegate) =>
      oldDelegate.rotation != rotation || oldDelegate.color != color;
}

/// Cercles qui naissent au centre et s'étendent en s'estompant, en
/// boucle continue — effet onde sonore/sonar. Utilisé uniquement quand
/// _style == concentricWaves.
class _ConcentricWavesPainter extends CustomPainter {
  final Color color;
  final double phase; // 0..1, boucle

  _ConcentricWavesPainter({required this.color, required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.4);
    final maxRadius = size.longestSide * 0.7;
    const waveCount = 3;

    for (int i = 0; i < waveCount; i++) {
      final t = (phase + i / waveCount) % 1.0;
      final radius = t * maxRadius;
      final opacity = (1 - t) * 0.22;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: opacity);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConcentricWavesPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.color != color;
}

/// Un vrai disque vinyle qui tourne en continu, toujours affiché en fond
/// derrière le style tiré au hasard — silhouette du disque, sillons
/// concentriques, label central coloré, et un reflet lumineux qui
/// balaie la surface en tournant, comme une lumière qui accroche le
/// vinyle.
class _SpinningVinylPainter extends CustomPainter {
  final Color color;
  final double rotation;

  _SpinningVinylPainter({required this.color, required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    // Rayon du disque visible (silhouette + sillons) : agrandi pour
    // éviter que le bord du disque soit visible en bas sur certains
    // écrans. Volontairement DÉCOUPLÉ du rayon utilisé pour le label
    // central ci-dessous, pour ne pas faire grandir le logo avec lui.
    final discRadius = size.longestSide * 0.78;
    // Rayon de référence pour le label central : reste basé sur le
    // ratio d'origine (0.62, identique à _discRadiusRatio du state),
    // pour que le rond central et donc le logo gardent exactement leur
    // taille et position d'avant, peu importe la taille du disque.
    final labelBaseRadius = size.longestSide * 0.62;

    // Silhouette du disque : quasi noir, à peine teinté par la couleur,
    // pour rester discret sur le fond déjà sombre.
    final discPaint = Paint()
      ..color = Color.lerp(const Color(0xFF15121C), color, 0.06)!;
    canvas.drawCircle(center, discRadius, discPaint);

    // Sillons concentriques.
    const grooveCount = 26;
    for (int i = 0; i < grooveCount; i++) {
      final t = i / grooveCount;
      final radius = discRadius * (0.32 + 0.66 * t);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.035);
      canvas.drawCircle(center, radius, paint);
    }

    // Reflet lumineux qui tourne avec le disque, façon lumière qui
    // accroche la surface d'un vinyle.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final shinePaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          color.withValues(alpha: 0.22),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
        startAngle: 0,
        endAngle: math.pi / 3,
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: discRadius));
    canvas.drawCircle(Offset.zero, discRadius, shinePaint);
    canvas.restore();

    // Label central du disque — basé sur labelBaseRadius (taille
    // d'origine), pas sur le discRadius agrandi.
    final labelRadius = labelBaseRadius * 0.22;
    final labelPaint = Paint()..color = color.withValues(alpha: 0.35);
    canvas.drawCircle(center, labelRadius, labelPaint);

    final labelRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color.withValues(alpha: 0.5);
    canvas.drawCircle(center, labelRadius, labelRingPaint);

    // Petit trou central, comme un vrai vinyle.
    final holePaint = Paint()..color = const Color(0xFF0A0910);
    canvas.drawCircle(center, labelRadius * 0.08, holePaint);
  }

  @override
  bool shouldRepaint(covariant _SpinningVinylPainter oldDelegate) =>
      oldDelegate.rotation != rotation || oldDelegate.color != color;
}