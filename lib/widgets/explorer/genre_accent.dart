import 'dart:math';
import 'package:flutter/material.dart';

/// Associe un style musical à une couleur d'accent pensée pour un fond
/// très sombre (bordure semi-transparente + icône un cran plus claire,
/// jamais saturée à fond).
///
/// Un seul GenreAccent est tiré au hasard au niveau de la page Explorer,
/// puis transmis à la search bar ET aux autres composants qui doivent
/// matcher la même couleur (cover, badge, etc).
///
/// [genre] est le libellé affiché à l'utilisateur (FR ou stylisé).
/// [discogsGenre] / [discogsStyle] sont les valeurs EXACTES attendues par
/// les paramètres `genre=` et `style=` de l'API Discogs — ces valeurs sont
/// figées côté Discogs (casse, espaces, "/" compris) et ne correspondent
/// pas toujours au libellé affiché. `discogsStyle` est utilisé en priorité
/// quand présent (plus précis), sinon on retombe sur `discogsGenre`.
class GenreAccent {
  final String genre;
  final Color color;
  final String discogsGenre;
  final String? discogsStyle;

  const GenreAccent(
    this.genre,
    this.color, {
    required this.discogsGenre,
    this.discogsStyle,
  });

  /// Valeur à envoyer à DiscogsApi : le style si connu (plus précis),
  /// sinon le genre.
  String get discogsQuery => discogsStyle ?? discogsGenre;

  static const List<GenreAccent> palette = [
    GenreAccent(
      'Pop',
      Color(0xFFA88CFF),
      discogsGenre: 'Pop',
    ),
    GenreAccent(
      'Jazz',
      Color(0xFF5EDCC8),
      discogsGenre: 'Jazz',
    ),
    GenreAccent(
      'R&B',
      Color(0xFFFF8CBE),
      discogsGenre: 'Funk / Soul',
      discogsStyle: 'Rhythm & Blues',
    ),
    GenreAccent(
      'Hip-Hop',
      Color(0xFFFFC46E),
      discogsGenre: 'Hip Hop',
    ),
    GenreAccent(
      'Electro',
      Color(0xFF78AAFF),
      discogsGenre: 'Electronic',
    ),
    GenreAccent(
      'Indie',
      Color(0xFFBEE178),
      discogsGenre: 'Rock',
      discogsStyle: 'Indie Rock',
    ),
    GenreAccent(
      'Blues',
      Color(0xFF4A7A9E),
      discogsGenre: 'Blues',
    ),
    GenreAccent(
      'Rap',
      Color(0xFFFF6B5B),
      discogsGenre: 'Hip Hop',
      discogsStyle: 'Rap',
    ),
    GenreAccent(
      'Rock',
      Color(0xFFE06C6C),
      discogsGenre: 'Rock',
    ),
    GenreAccent(
      'Metal',
      Color(0xFF9A9FB0),
      discogsGenre: 'Rock',
      discogsStyle: 'Heavy Metal',
    ),
    GenreAccent(
      'Punk',
      Color(0xFFFF5C8A),
      discogsGenre: 'Rock',
      discogsStyle: 'Punk',
    ),
    GenreAccent(
      'Reggae',
      Color(0xFF6FCF7B),
      discogsGenre: 'Reggae',
    ),
    GenreAccent(
      'Dancehall',
      Color(0xFFFFA66E),
      discogsGenre: 'Reggae',
      discogsStyle: 'Dancehall',
    ),
    GenreAccent(
      'Afrobeat',
      Color(0xFFFFB84D),
      discogsGenre: 'Funk / Soul',
      discogsStyle: 'Afrobeat',
    ),
    GenreAccent(
      'Amapiano',
      Color(0xFFE0A85E),
      discogsGenre: 'Electronic',
      discogsStyle: 'Amapiano',
    ),
    GenreAccent(
      'Funk',
      Color(0xFFE0C25E),
      discogsGenre: 'Funk / Soul',
      discogsStyle: 'Funk',
    ),
    GenreAccent(
      'Soul',
      Color(0xFFD98E5A),
      discogsGenre: 'Funk / Soul',
      discogsStyle: 'Soul',
    ),
    GenreAccent(
      'Disco',
      Color(0xFFE07EDB),
      discogsGenre: 'Electronic',
      discogsStyle: 'Disco',
    ),
    GenreAccent(
      'House',
      Color(0xFF6EC6FF),
      discogsGenre: 'Electronic',
      discogsStyle: 'House',
    ),
    GenreAccent(
      'Techno',
      Color(0xFF8C9CFF),
      discogsGenre: 'Electronic',
      discogsStyle: 'Techno',
    ),
    GenreAccent(
      'Trance',
      Color(0xFF7CE0E8),
      discogsGenre: 'Electronic',
      discogsStyle: 'Trance',
    ),
    GenreAccent(
      'Drum & Bass',
      Color(0xFF5ED9A0),
      discogsGenre: 'Electronic',
      discogsStyle: 'Drum n Bass',
    ),
    GenreAccent(
      'Dubstep',
      Color(0xFF9A6EE0),
      discogsGenre: 'Electronic',
      discogsStyle: 'Dubstep',
    ),
    GenreAccent(
      'Trap',
      Color(0xFFC98CFF),
      discogsGenre: 'Hip Hop',
      discogsStyle: 'Trap',
    ),
    GenreAccent(
      'Reggaeton',
      Color(0xFFFF7A9E),
      discogsGenre: 'Latin',
      discogsStyle: 'Reggaeton',
    ),
    GenreAccent(
      'Latin',
      Color(0xFFFF9F6E),
      discogsGenre: 'Latin',
    ),
    GenreAccent(
      'Salsa',
      Color(0xFFFF8552),
      discogsGenre: 'Latin',
      discogsStyle: 'Salsa',
    ),
    GenreAccent(
      'K-Pop',
      Color(0xFFFF9EC4),
      discogsGenre: 'Pop',
      discogsStyle: 'K-pop',
    ),
    GenreAccent(
      'J-Pop',
      Color(0xFFFFB3D1),
      discogsGenre: 'Pop',
      discogsStyle: 'J-pop',
    ),
    GenreAccent(
      'Country',
      Color(0xFFD9B36A),
      discogsGenre: 'Folk, World, & Country',
      discogsStyle: 'Country',
    ),
    GenreAccent(
      'Folk',
      Color(0xFFB8C98A),
      discogsGenre: 'Folk, World, & Country',
      discogsStyle: 'Folk',
    ),
    GenreAccent(
      'Classique',
      Color(0xFFC9B8E8),
      discogsGenre: 'Classical',
    ),
    GenreAccent(
      'Opéra',
      Color(0xFFCBA8D9),
      discogsGenre: 'Classical',
      discogsStyle: 'Opera',
    ),
    GenreAccent(
      'Ambient',
      Color(0xFF8FB3C9),
      discogsGenre: 'Electronic',
      discogsStyle: 'Ambient',
    ),
    GenreAccent(
      'Lo-Fi',
      Color(0xFFB0A08C),
      discogsGenre: 'Hip Hop',
      discogsStyle: 'Downtempo',
    ),
    GenreAccent(
      'Chill',
      Color(0xFF7FC9C0),
      discogsGenre: 'Electronic',
      discogsStyle: 'Downtempo',
    ),
    GenreAccent(
      'Gospel',
      Color(0xFFE8C87A),
      discogsGenre: 'Funk / Soul',
      discogsStyle: 'Gospel',
    ),
    GenreAccent(
      'Grime',
      Color(0xFF8C7AE0),
      discogsGenre: 'Hip Hop',
      discogsStyle: 'Grime',
    ),
    GenreAccent(
      'Ska',
      Color(0xFFE0D06E),
      discogsGenre: 'Reggae',
      discogsStyle: 'Ska',
    ),
    GenreAccent(
      'Synthwave',
      Color(0xFFFF6EC7),
      discogsGenre: 'Electronic',
      discogsStyle: 'Synth-pop',
    ),
    GenreAccent(
      'Alternative',
      Color(0xFF7A9AE0),
      discogsGenre: 'Rock',
      discogsStyle: 'Alternative Rock',
    ),
    GenreAccent(
      'Emo',
      Color(0xFF9E8CC9),
      discogsGenre: 'Rock',
      discogsStyle: 'Emo',
    ),
    GenreAccent(
      'Bluegrass',
      Color(0xFFC9A85E),
      discogsGenre: 'Folk, World, & Country',
      discogsStyle: 'Bluegrass',
    ),
    GenreAccent(
      'World',
      Color(0xFF6EC98F),
      discogsGenre: 'Folk, World, & Country',
    ),
  ];

  static GenreAccent random() => palette[Random().nextInt(palette.length)];
}