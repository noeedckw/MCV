// Composants réutilisables de la modal "glass" utilisée pour le détail
// d'un album (résultat de recherche, entrée de collection/wishlist...).
// Extraits ici pour que les différentes modals partagent une seule
// implémentation au lieu de copier-coller et de diverger avec le temps.

import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Accent utilisé pour tout ce qui est "sélectionné"/"actif" dans les
/// modals glass.
const Color kGlassAccent = Color(0xFFE3B673);

const Duration kGlassModalTransitionDuration = Duration(milliseconds: 260);

/// Ouvre une modal avec le fond "verre dépoli" + transition scale/fade
/// standard. L'appelant garde la main sur son propre setup/teardown de
/// provider (ex: via `.whenComplete()` sur le Future retourné) — cette
/// fonction ne fait que factoriser la route + transition, qui était avant
/// copiée telle quelle dans chaque modal.
Future<T?> showGlassModal<T>({
  required BuildContext context,
  required WidgetBuilder pageBuilder,
  bool useRootNavigator = false,
}) {
  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.transparent,
    transitionDuration: kGlassModalTransitionDuration,
    pageBuilder: (context, anim1, anim2) => pageBuilder(context),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return AnimatedBuilder(
        animation: curved,
        child: child,
        builder: (context, child) => BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: 20 * curved.value,
            sigmaY: 20 * curved.value,
          ),
          child: Container(
            color: Colors.black.withValues(alpha: .5 * curved.value),
            child: FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween(begin: .95, end: 1.0).animate(curved),
                child: child,
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Enrobage standard de toute modal glass : safe area, largeur plafonnée
/// (600 sur grand écran, 92% sinon), hauteur plafonnée à l'espace
/// disponible, tap en dehors pour fermer, bouton close en haut à droite.
/// Remplace le bloc SafeArea/LayoutBuilder/Stack qui était dupliqué à
/// l'identique dans chaque modal.
class GlassModalScaffold extends StatelessWidget {
  final Widget child;
  final double panelRadius;
  final double topMargin;
  final double bottomMargin;
  final double minHeight;
  final double maxHeightCap;

  const GlassModalScaffold({
    super.key,
    required this.child,
    this.panelRadius = 28,
    this.topMargin = 16,
    this.bottomMargin = 16,
    this.minHeight = 280,
    this.maxHeightCap = 680,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).maybePop(),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final modalWidth = constraints.maxWidth < 680
                ? constraints.maxWidth * 0.92
                : 600.0;
            final modalMaxHeight =
                (constraints.maxHeight - topMargin - bottomMargin).clamp(
              minHeight,
              maxHeightCap,
            );

            return Padding(
              padding: EdgeInsets.only(top: topMargin, bottom: bottomMargin),
              child: Align(
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: SizedBox(
                    width: modalWidth,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: minHeight,
                        maxHeight: modalMaxHeight,
                      ),
                      child: Material(
                        type: MaterialType.transparency,
                        child: GlassPanel(
                          radius: panelRadius,
                          child: Stack(
                            children: [
                              child,
                              Positioned(
                                top: 10,
                                right: 10,
                                child: GlassCloseButton(
                                  onTap: () =>
                                      Navigator.of(context).maybePop(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Panel "verre" opaque : effet frosted-glass sur les bords (léger blur +
/// bordure lumineuse + ombre portée) mais fond quasi-opaque -> pas de
/// transparence distrayante qui laisserait deviner ce qu'il y a derrière.
class GlassPanel extends StatelessWidget {
  final double radius;
  final Widget child;

  const GlassPanel({super.key, this.radius = 28, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF232329).withValues(alpha: .97),
                const Color(0xFF131316).withValues(alpha: .97),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: .14),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .55),
                blurRadius: 50,
                offset: const Offset(0, 24),
              ),
              // Fin liseré lumineux en haut -> renforce l'effet "verre".
              BoxShadow(
                color: Colors.white.withValues(alpha: .04),
                blurRadius: 1,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlassCloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const GlassCloseButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: .35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            Icons.close_rounded,
            size: 19,
            color: Colors.white.withValues(alpha: .8),
          ),
        ),
      ),
    );
  }
}

class ModalSectionLabel extends StatelessWidget {
  final String text;
  const ModalSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Colors.white.withValues(alpha: .40),
      ),
    );
  }
}

class ModalChip extends StatelessWidget {
  final String text;
  const ModalChip(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white.withValues(alpha: .06),
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: .25,
          color: Colors.white.withValues(alpha: .70),
        ),
      ),
    );
  }
}

/// Petite icône "i" qui révèle une explication au tap, et se referme dès
/// qu'on tape ailleurs. Implémentation basée sur un Stack + Positioned :
/// une taille fixe est réservée dans le Row parent (= taille de l'icône)
/// donc rien n'est poussé à côté, même si le Tooltip lui-même est plus
/// large et déborde visuellement.
class ModalInfoTooltip extends StatelessWidget {
  final String message;
  const ModalInfoTooltip({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 13,
      height: 13,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Tooltip(
              message: message,
              triggerMode: TooltipTriggerMode.tap,
              showDuration: const Duration(seconds: 5),
              preferBelow: true,
              verticalOffset: 12,
              constraints: const BoxConstraints(maxWidth: 200),
              textStyle: TextStyle(
                fontSize: 11.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: .92),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                color: const Color(0xFF2A2A30).withValues(alpha: .98),
                border:
                    Border.all(color: Colors.white.withValues(alpha: .14)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .40),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              // Zone de référence élargie vers la droite pour décaler la
              // bulle -> l'icône reste collée à gauche dedans.
              child: SizedBox(
                width: 60,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 13,
                    color: Colors.white.withValues(alpha: .40),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Texte clampé à [collapsedLines] lignes par défaut, avec un toggle
/// "Show more" / "Show less" qui n'apparaît que si le texte déborde
/// vraiment à la largeur disponible. Utilisé pour la ligne "Label : ..."
/// (2 lignes) et le bloc notes (5 lignes) dans toutes les modals détail
/// album.
class CollapsibleTextSection extends StatefulWidget {
  final String text;
  final int collapsedLines;
  final TextStyle textStyle;
  final TextStyle toggleStyle;

  const CollapsibleTextSection({
    super.key,
    required this.text,
    required this.textStyle,
    this.collapsedLines = 5,
    this.toggleStyle = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: Colors.white70,
    ),
  });

  @override
  State<CollapsibleTextSection> createState() =>
      _CollapsibleTextSectionState();
}

class _CollapsibleTextSectionState extends State<CollapsibleTextSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.textStyle),
          maxLines: widget.collapsedLines,
          textDirection: ui.TextDirection.ltr,
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topLeft,
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: SizedBox(
                width: double.infinity,
                child: Text(
                  widget.text,
                  maxLines: widget.collapsedLines,
                  overflow: TextOverflow.ellipsis,
                  style: widget.textStyle,
                ),
              ),
              secondChild: SizedBox(
                width: double.infinity,
                child: Text(widget.text, style: widget.textStyle),
              ),
            ),
            if (overflows) ...[
              const SizedBox(height: 4),
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    _expanded ? 'Show less' : 'Show more',
                    style: widget.toggleStyle,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Preset pour la ligne "Label : ...".
class ModalLabelSection extends StatelessWidget {
  final String label;
  const ModalLabelSection({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return CollapsibleTextSection(
      text: 'Label : $label',
      collapsedLines: 2,
      textStyle: TextStyle(
        fontSize: 11.5,
        color: Colors.white.withValues(alpha: .45),
      ),
      toggleStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.white.withValues(alpha: .65),
      ),
    );
  }
}

/// Preset pour le bloc "Notes".
class ModalNotesSection extends StatelessWidget {
  final String notes;
  const ModalNotesSection({super.key, required this.notes});

  @override
  Widget build(BuildContext context) {
    return CollapsibleTextSection(
      text: notes,
      collapsedLines: 5,
      textStyle: TextStyle(
        fontSize: 12.5,
        height: 1.4,
        color: Colors.white.withValues(alpha: .55),
      ),
      toggleStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.white.withValues(alpha: .85),
      ),
    );
  }
}

/// Bouton glass compact, pensé pour aller par paire (côte à côte via
/// Expanded). [active] bascule entre un style neutre/atténué et un style
/// plus "rempli" une fois l'action effectuée (déjà en collection /
/// wishlist) — aucune couleur, juste l'opacité/poids du blanc qui change.
class GlassActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const GlassActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Colors.white.withValues(alpha: active ? .95 : .78);
    return Material(
      color: Colors.white.withValues(alpha: active ? .14 : .06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: active ? .30 : .12),
              width: active ? 1.3 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bloc cover art 138x138 avec ombre portée, coins arrondis, tap pour
/// ouvrir le viewer plein écran. Utilisé en haut de chaque modal détail
/// album.
class ModalCoverThumbnail extends StatelessWidget {
  final Widget cover;
  final VoidCallback onTap;
  final double size;

  const ModalCoverThumbnail({
    super.key,
    required this.cover,
    required this.onTap,
    this.size = 138,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(width: size, height: size, child: cover),
        ),
      ),
    );
  }
}

/// Dimensionne le bloc artiste + album (+ année) pour qu'il ne dépasse
/// jamais [maxHeight] (par défaut la hauteur de la cover à côté) : part de
/// tailles "idéales" et, seulement si le texte réel (avec son retour à la
/// ligne à la largeur disponible) déborderait cette hauteur, réduit les
/// deux tailles ensemble — jamais sous un plancher de lisibilité — jusqu'à
/// ce que ça rentre.
class FittedAlbumTitles extends StatelessWidget {
  final String artist;
  final String album;
  final String? year;
  final double maxHeight;

  const FittedAlbumTitles({
    super.key,
    required this.artist,
    required this.album,
    required this.year,
    this.maxHeight = 138,
  });

  static const double _artistBase = 15.5;
  static const double _artistMin = 12.0;
  static const double _albumBase = 21.0;
  static const double _albumMin = 15.0;

  TextStyle _artistStyle(double size) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: .78),
      );

  TextStyle _albumStyle(double size) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        height: 1.15,
        letterSpacing: -.3,
      );

  static const TextStyle _yearStyle = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
  );

  double _measure(
    String text,
    TextStyle style,
    double maxWidth,
    TextScaler scaler,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
      textScaler: scaler,
    )..layout(maxWidth: maxWidth);
    return painter.height;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final scaler = MediaQuery.textScalerOf(context);

        final yearHeight = year != null
            ? _measure(year!, _yearStyle, maxWidth, scaler) + 6
            : 0.0;

        double artistSize = _artistBase;
        double albumSize = _albumBase;

        for (double t = 1.0; t >= 0; t -= 0.03) {
          artistSize = (_artistBase * t).clamp(_artistMin, _artistBase);
          albumSize = (_albumBase * t).clamp(_albumMin, _albumBase);
          final artistHeight =
              _measure(artist, _artistStyle(artistSize), maxWidth, scaler);
          final albumHeight =
              _measure(album, _albumStyle(albumSize), maxWidth, scaler);
          final total = artistHeight + 4 + albumHeight + yearHeight;
          if (total <= maxHeight ||
              (artistSize <= _artistMin && albumSize <= _albumMin)) {
            break;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(artist, style: _artistStyle(artistSize)),
            const SizedBox(height: 4),
            Text(album, style: _albumStyle(albumSize)),
            if (year != null) ...[
              const SizedBox(height: 6),
              Text(
                year!,
                style: _yearStyle.copyWith(
                  color: Colors.white.withValues(alpha: .45),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}