import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'glass_container.dart';

/// Position de l'image par rapport au texte dans une carte.
/// - [top]  : texte en haut, image pleine largeur en dessous.
/// - [left] : petite image à gauche, texte à droite.
enum OnboardingImagePosition { top, left }

/// Une étape du carrousel.
///
/// RIEN n'est calculé automatiquement ici : chaque valeur que tu vois
/// (taille de la carte, taille de l'image, espacements, styles...) est
/// exactement ce qui sera affiché. Chaque [OnboardingStep] est 100%
/// indépendante des autres : tu peux donner `cardHeight: 120` à la
/// première carte et `cardHeight: 320` à la suivante sans que ça
/// n'affecte quoi que ce soit ailleurs (voir [OnboardingCarousel] pour
/// le seul endroit où une valeur commune — la hauteur du PageView — est
/// dérivée des cartes).
class OnboardingStep {
  final String title;
  final String description;

  /// Chemin de l'image (optionnel) : URL réseau (http/https) ou asset
  /// local (assets/...), détecté automatiquement. `null` = pas d'image,
  /// carte texte seul.
  final String? imageUrl;
  final OnboardingImagePosition imagePosition;

  // --- Taille et style de la carte (container) ---

  /// Largeur de la carte. `null` = prend toute la largeur disponible du
  /// carrousel (comportement par défaut, recommandé la plupart du temps).
  final double? cardWidth;

  /// Hauteur de la carte. Propre à CHAQUE carte, à définir explicitement.
  final double cardHeight;

  final EdgeInsets cardPadding;
  final double cardBorderRadius;

  // --- Taille et style de l'image (si [imageUrl] != null) ---

  final double imageWidth;
  final double imageHeight;
  final BoxFit imageFit;
  final BorderRadius imageBorderRadius;

  // --- Espacements internes, ajustables indépendamment ---

  /// Espace entre l'image et le texte (utilisé seulement en [OnboardingImagePosition.left]/[top]).
  final double gapImageText;

  /// Espace entre le titre et la description.
  final double gapTitleDescription;

  // --- Styles texte (optionnels : sinon un style par défaut est utilisé) ---

  final TextStyle? titleStyle;
  final TextStyle? descriptionStyle;

  const OnboardingStep({
    required this.title,
    required this.description,
    required this.cardHeight,
    this.imageUrl,
    this.imagePosition = OnboardingImagePosition.top,
    this.cardWidth,
    this.cardPadding = const EdgeInsets.all(18),
    this.cardBorderRadius = 22,
    this.imageWidth = 90,
    this.imageHeight = 100,
    this.imageFit = BoxFit.cover,
    this.imageBorderRadius = const BorderRadius.all(Radius.circular(16)),
    this.gapImageText = 16,
    this.gapTitleDescription = 8,
    this.titleStyle,
    this.descriptionStyle,
  });
}

/// Carrousel horizontal — une carte plein cadre à la fois, swipe libre.
///
/// La SEULE mutualisation entre cartes : la hauteur du [PageView] lui-même,
/// qui doit forcément être unique (contrainte Flutter). Elle vaut la plus
/// grande des `cardHeight` de la liste. Chaque carte garde ensuite sa
/// propre `cardHeight` À L'INTÉRIEUR de cet espace (alignée en haut), donc
/// une carte plus petite que le max n'est jamais étirée.
class OnboardingCarousel extends StatefulWidget {
  final List<OnboardingStep> steps;

  const OnboardingCarousel({super.key, required this.steps});

  @override
  State<OnboardingCarousel> createState() => _OnboardingCarouselState();
}

class _OnboardingCarouselState extends State<OnboardingCarousel> {
  late final PageController _pageController;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) return const SizedBox.shrink();

    final carouselHeight =
        widget.steps.map((s) => s.cardHeight).reduce((a, b) => a > b ? a : b);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRect(
          child: SizedBox(
            height: carouselHeight,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.steps.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, index) {
                final step = widget.steps[index];

                // Chaque carte garde exactement sa propre `cardHeight` et
                // est centrée VERTICALEMENT dans l'espace du PageView
                // (les cartes plus petites que le max ne sont ni étirées
                // ni collées en haut : elles flottent au centre).
                // RepaintBoundary isole chaque carte pour limiter les
                // artefacts de rendu (ex: flash du flou de GlassContainer)
                // pendant le swipe.
                final card = RepaintBoundary(
                  child: Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      height: step.cardHeight,
                      width: step.cardWidth,
                      child: _StepCard(step: step),
                    ),
                  ),
                );

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: card,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        _Dots(count: widget.steps.length, activeIndex: _page),
      ],
    );
  }
}

/// Petits points de pagination sous le carrousel.
class _Dots extends StatelessWidget {
  final int count;
  final int activeIndex;

  const _Dots({required this.count, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.white.withValues(alpha: isActive ? 0.9 : 0.28),
          ),
        );
      }),
    );
  }
}

/// Carte d'une étape : fond en verre (glass), contenu construit selon
/// les valeurs exactes de [step] (aucun calcul auto). Si le contenu
/// dépasse la `cardHeight` choisie, il est simplement coupé (jamais de
/// débordement visuel, jamais d'exception de layout) — c'est à toi
/// d'ajuster `cardHeight` si besoin.
class _StepCard extends StatelessWidget {
  final OnboardingStep step;
  const _StepCard({required this.step});

  static const _defaultTitleStyle = TextStyle(
    color: Colors.white,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: -.2,
    height: 1.2,
  );

  static final _defaultDescriptionStyle = TextStyle(
    color: Colors.white.withValues(alpha: 0.65),
    fontSize: 13,
    height: 1.35,
  );

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: step.cardBorderRadius,
      padding: step.cardPadding,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: 0,
          maxHeight: double.infinity,
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          step.title,
          textAlign: TextAlign.center,
          softWrap: true,
          style: step.titleStyle ?? _defaultTitleStyle,
        ),
        SizedBox(height: step.gapTitleDescription),
        Text(
          step.description,
          textAlign: TextAlign.center,
          softWrap: true,
          style: step.descriptionStyle ?? _defaultDescriptionStyle,
        ),
      ],
    );

    if (step.imageUrl == null) return text;

    final image = SizedBox(
      width: step.imagePosition == OnboardingImagePosition.left
          ? step.imageWidth
          : double.infinity,
      height: step.imageHeight,
      child: _buildImage(step.imageUrl!, step.imageFit, step.imageBorderRadius),
    );

    if (step.imagePosition == OnboardingImagePosition.left) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          image,
          SizedBox(width: step.gapImageText),
          Flexible(child: text),
        ],
      );
    }

    // top
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        text,
        SizedBox(height: step.gapImageText),
        image,
      ],
    );
  }
}

bool _isNetworkUrl(String path) =>
    path.startsWith('http://') || path.startsWith('https://');

/// Image d'une étape (réseau ou asset local, détection automatique).
Widget _buildImage(String path, BoxFit fit, BorderRadius radius) {
  Widget errorBox() => Container(
        color: Colors.white.withValues(alpha: 0.06),
        alignment: Alignment.center,
        child: Icon(
          Icons.image_not_supported_rounded,
          color: Colors.white.withValues(alpha: 0.3),
          size: 22,
        ),
      );

  final Widget image = _isNetworkUrl(path)
      ? Image.network(
          path,
          fit: fit,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              color: Colors.white.withValues(alpha: 0.06),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint('[OnboardingCarousel] échec chargement réseau "$path" -> $error');
            return errorBox();
          },
        )
      : Image.asset(
          path,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            // Cause la plus fréquente : le chemin n'est pas déclaré dans
            // le bloc `flutter: assets:` de pubspec.yaml, ou l'app n'a
            // pas été relancée (flutter run complet) après l'avoir ajouté.
            debugPrint('[OnboardingCarousel] échec chargement asset "$path" -> $error');
            return errorBox();
          },
        );

  return ClipRRect(borderRadius: radius, child: image);
}