// Petits helpers de formatage partagés par toutes les modals "détail
// album" (résultat de recherche Discogs, collection/wishlist...). Gardés
// en String in / String out pour ne dépendre d'aucun modèle de données
// particulier (Map Discogs brut ou VinylEntry typé).

/// Discogs suffixe parfois les noms (labels, artistes...) d'un numéro de
/// désambiguation entre parenthèses, ex: "Warp Records (2)" -> on ne garde
/// que "Warp Records".
String stripDisambiguationNumbers(String value) {
  return value.replaceAll(RegExp(r'\s?\(\d+\)'), '').trim();
}

/// `label` peut être une String simple ou une List<String> selon la
/// source (résultat de recherche vs entrée stockée) -> on normalise en une
/// seule String, jointe par " • ", nettoyée des numéros de désambiguation.
String? formatLabelValue(dynamic value) {
  if (value == null) return null;
  final raw = value is List
      ? (value.isEmpty ? null : value.join(' • '))
      : value.toString();
  if (raw == null || raw.isEmpty) return null;
  final cleaned = stripDisambiguationNumbers(raw);
  return cleaned.isEmpty ? null : cleaned;
}

/// Discogs renvoie parfois `released` vide ou "0000-00-00" -> on préfère
/// n'afficher aucune date plutôt qu'une valeur qui ne veut rien dire.
String? validReleased(dynamic value) {
  if (value == null) return null;
  final str = value.toString().trim();
  if (str.isEmpty) return null;
  if (RegExp(r'^[0-]+$').hasMatch(str)) return null;
  return str;
}

/// Idem pour `year: 0`.
String? validYear(dynamic value) {
  if (value == null) return null;
  final str = value.toString().trim();
  if (str.isEmpty || str == '0') return null;
  return str;
}