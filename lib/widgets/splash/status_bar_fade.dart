import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'splash_style.dart';

/// Fondu noir statique tout en haut de l'écran, dont le rôle est
/// purement cosmétique : faire un raccord visuel avec la status bar
/// native iOS (toujours noire/opaque au-dessus du splash en mode PWA
/// standalone), pour qu'on ne voie jamais de bande nette entre les deux.
/// Fixe pendant toute la séquence (respiration comme sortie), et
/// transparent aux taps pour ne jamais gêner le "tap to enter".
///
/// N'a de sens que sur web (PWA standalone iOS) : à afficher
/// conditionnellement derrière `kIsWeb` côté appelant, inutile sur app
/// native où il n'y a pas de status bar web à matcher.
///
/// IMPORTANT : implémenté avec un empilement de bandes pleines
/// (ColoredBox + alpha), PAS avec un LinearGradient/shader. Un gradient
/// à beaucoup de stops rapprochés s'affiche très bien sur desktop
/// (Chrome dev, Chrome/Edge sur PC) mais peut ne pas s'afficher du tout
/// sur WebKit iOS (Safari ET "Chrome iOS", qui utilise le même moteur
/// WebKit sur iOS par contrainte Apple) — bug de rendu shader propre au
/// GPU mobile. Un simple alpha blending de rectangles pleins n'a pas ce
/// problème, il est supporté nativement partout.
class StatusBarFade extends StatelessWidget {
  const StatusBarFade({super.key});

  // Nombre de bandes du fondu. Il n'est reconstruit qu'au setState du
  // parent (pas à chaque frame d'animation), donc le coût est
  // négligeable. Plus de bandes = moins de "marches" visibles entre
  // alphas successifs.
  static const int _bandCount = 120;

  @override
  Widget build(BuildContext context) {
    // On NE se base pas uniquement sur MediaQuery.padding.top : sur
    // Flutter web/PWA iOS, cette valeur peut remonter à 0 selon le
    // moment du build, ce qui rendait la zone opaque quasi invisible. On
    // prend le max entre la vraie safe-area (si dispo) et un plancher
    // fixe, pour garantir un résultat visible sur tous les
    // appareils/contextes.
    final topInset = MediaQuery.of(context).padding.top;
    final screenHeight = MediaQuery.of(context).size.height;

    // Zone 100% opaque minuscule : juste de quoi matcher la status bar,
    // sans occuper d'espace visible en soi. Plus de plancher artificiel
    // (0.004 * screenHeight) : seul topInset reste garanti dur, le reste
    // appartient au dégradé -> le noir plein "dur" est réduit au strict
    // minimum, tout le reste est progressif.
    final solidHeight = math.max(topInset, 6.0);

    // Fondu allongé pour un dégradé smooth et bien visible. Zone réduite
    // (0.12 -> 0.16 avec smootherstep) : le fondu reste perçu comme très
    // smooth même sur une zone plus courte — une courbe linéaire aurait
    // besoin de plus d'espace pour "cacher" sa cassure.
    final fadeLength = math.max(screenHeight * 0.16, 0.0);
    final bandHeight = fadeLength / _bandCount;

    return IgnorePointer(
      child: Stack(
        children: [
          // Bande 100% opaque, garantie visible même si topInset remonte
          // à 0 dans certains contextes.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: solidHeight,
            child: const ColoredBox(color: statusBarFadeColor),
          ),
          for (int i = 0; i < _bandCount; i++)
            _fadeBand(index: i, solidHeight: solidHeight, bandHeight: bandHeight),
        ],
      ),
    );
  }

  Widget _fadeBand({
    required int index,
    required double solidHeight,
    required double bandHeight,
  }) {
    final t = index / _bandCount; // 0..1 le long du fondu

    // Smootherstep au lieu d'un fondu linéaire : dérivée nulle aux deux
    // bouts -> raccord "à plat" avec la bande opaque du dessus ET avec
    // la transparence totale du dessous. C'est ça qui supprime la
    // cassure, pas juste plus de bandes.
    final smoothT = t * t * t * (t * (t * 6 - 15) + 10);
    final opacity = (1 - smoothT).clamp(0.0, 1.0);

    return Positioned(
      top: solidHeight + index * bandHeight,
      left: 0,
      right: 0,
      height: bandHeight + 0.5,
      child: ColoredBox(
        color: statusBarFadeColor.withValues(alpha: opacity),
      ),
    );
  }
}