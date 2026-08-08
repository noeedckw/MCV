import 'package:flutter/material.dart';

import 'glass_modal_kit.dart' show kGlassAccent, ModalSectionLabel;

/// Ligne de tracklist normalisée, pour que le widget partagé ci-dessous
/// n'ait pas à savoir si la source était une Map Discogs brute ou un
/// modèle typé (ex: VinylTrack).
class TrackRowData {
  final String position;
  final String title;
  final String duration;

  const TrackRowData({
    required this.position,
    required this.title,
    this.duration = '',
  });
}

/// Affiche une section "TRACKLIST" : label (+ petit spinner optionnel
/// pendant le chargement de la tracklist d'une autre édition), message
/// d'état vide, puis les lignes elles-mêmes.
///
/// [switchKey] pilote la transition fade/slide de l'AnimatedSwitcher —
/// passer une valeur qui change avec la tracklist sous-jacente (ex: l'id
/// de l'édition sélectionnée) pour avoir la petite transition ; laisser la
/// valeur par défaut pour une tracklist statique qui ne change jamais sous
/// la modal.
class TracklistSection extends StatelessWidget {
  final List<TrackRowData> tracks;
  final bool isSwitching;
  final Object switchKey;
  final String emptyMessage;

  const TracklistSection({
    super.key,
    required this.tracks,
    this.isSwitching = false,
    this.switchKey = 'static',
    this.emptyMessage = 'Tracklist unavailable.',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const ModalSectionLabel('TRACKLIST'),
            if (isSwitching) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 11,
                height: 11,
                child: CircularProgressIndicator(
                  strokeWidth: 1.6,
                  valueColor: AlwaysStoppedAnimation<Color>(kGlassAccent),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, .03),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: isSwitching
              ? const SizedBox(key: ValueKey('loading'))
              : Column(
                  key: ValueKey(switchKey),
                  children: tracks.isEmpty
                      ? [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              emptyMessage,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.white.withValues(alpha: .45),
                              ),
                            ),
                          ),
                        ]
                      : tracks.map((t) => _TrackRow(track: t)).toList(),
                ),
        ),
      ],
    );
  }
}

class _TrackRow extends StatelessWidget {
  final TrackRowData track;
  const _TrackRow({required this.track});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              track.position,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: .40),
              ),
            ),
          ),
          Expanded(
            child: Text(
              track.title,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.white.withValues(alpha: .82),
              ),
            ),
          ),
          if (track.duration.isNotEmpty)
            Text(
              track.duration,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: .40),
              ),
            ),
        ],
      ),
    );
  }
}