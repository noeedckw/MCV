import 'package:flutter/foundation.dart' show kIsWeb;

/// Sur web, les CDN images de Discogs ne renvoient pas de header
/// Access-Control-Allow-Origin -> XHR bloqué par CORS (OK en display <img>
/// natif, mais Flutter web/CanvasKit fetch les bytes -> bloqué).
/// On passe par un proxy d'images public qui, lui, ajoute le header.
String? resolveCoverUrl(String? url) {
  if (url == null || url.isEmpty) return url;
  if (!kIsWeb) return url;
  final stripped = url.replaceFirst(RegExp(r'^https?://'), '');
  return 'https://images.weserv.nl/?url=${Uri.encodeComponent(stripped)}';
}