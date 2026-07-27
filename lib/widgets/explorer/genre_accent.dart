import 'dart:math';
import 'package:flutter/material.dart';

/// Associe un style musical à une couleur d'accent pensée pour un fond
/// très sombre (bordure semi-transparente + icône un cran plus claire,
/// jamais saturée à fond).
///
/// Un seul GenreAccent est tiré au hasard au niveau de la page Explorer,
/// puis transmis à la search bar ET aux autres composants qui doivent
/// matcher la même couleur (cover, badge, etc).
class GenreAccent {
  final String genre;
  final Color color;

  const GenreAccent(this.genre, this.color);

  static const List<GenreAccent> palette = [
    GenreAccent('Pop', Color(0xFFA88CFF)),
    GenreAccent('Jazz', Color(0xFF5EDCC8)),
    GenreAccent('R&B', Color(0xFFFF8CBE)),
    GenreAccent('Hip-Hop', Color(0xFFFFC46E)),
    GenreAccent('Electro', Color(0xFF78AAFF)),
    GenreAccent('Indie', Color(0xFFBEE178)),
    GenreAccent('Blues', Color(0xFF4A7A9E)),
    GenreAccent('Rap', Color(0xFFFF6B5B)),
  ];

  static GenreAccent random() => palette[Random().nextInt(palette.length)];
}
