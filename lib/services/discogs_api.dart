import 'dart:convert';
import 'package:http/http.dart' as http;

import 'discogs_cache.dart';

class DiscogsApi {
  final String token;
  final DiscogsCache _cache;

  DiscogsApi(this.token, {DiscogsCache? cache})
    : _cache = cache ?? DiscogsCache();

  static const _baseUrl = 'https://api.discogs.com';
  static const _userAgent = 'VinylCollectionApp/1.0';

  /// Recherche de releases (pressages précis, format Vinyl). Comportement
  /// inchangé — c'est l'appel existant utilisé par ExplorerProvider et
  /// ExplorerVinylShowcase.
  Future<List<dynamic>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final cached = _cache.get('release', trimmed);
    if (cached != null) return cached;

    final url = Uri.parse(
      '$_baseUrl/database/search?q=${Uri.encodeComponent(trimmed)}&type=release&format=Vinyl&token=$token',
    );

    final response = await http.get(url, headers: {'User-Agent': _userAgent});

    if (response.statusCode == 200) {
      final results = (jsonDecode(response.body)['results'] as List);
      _cache.set('release', trimmed, results);
      return results;
    } else if (response.statusCode == 429) {
      throw Exception('Trop de requêtes, réessaie dans quelques secondes.');
    } else {
      throw Exception('Erreur Discogs (${response.statusCode})');
    }
  }

  /// Recherche de masters uniquement (un master = un album, indépendamment
  /// de ses pressages). À utiliser pour la grille si tu veux ensuite lister
  /// les versions disponibles au clic via getMasterVersions().
  Future<List<dynamic>> searchMasters(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final cached = _cache.get('master', trimmed);
    if (cached != null) return cached;

    final url = Uri.parse(
      '$_baseUrl/database/search?q=${Uri.encodeComponent(trimmed)}&type=master&token=$token',
    );

    final response = await http.get(url, headers: {'User-Agent': _userAgent});

    if (response.statusCode == 200) {
      final results = (jsonDecode(response.body)['results'] as List);
      _cache.set('master', trimmed, results);
      return results;
    } else if (response.statusCode == 429) {
      throw Exception('Trop de requêtes, réessaie dans quelques secondes.');
    } else {
      throw Exception('Erreur Discogs (${response.statusCode})');
    }
  }

  /// Versions/pressages disponibles pour un master donné, à appeler quand
  /// l'utilisateur clique sur une card de la grille (résultat de
  /// searchMasters). Clé de cache basée sur l'ID, pas sur une query texte.
  Future<List<dynamic>> getMasterVersions(int masterId) async {
    final cacheKey = masterId.toString();
    final cached = _cache.get('master_versions', cacheKey);
    if (cached != null) return cached;

    final url = Uri.parse(
      '$_baseUrl/masters/$masterId/versions?format=Vinyl&token=$token',
    );

    final response = await http.get(url, headers: {'User-Agent': _userAgent});

    if (response.statusCode == 200) {
      final versions = (jsonDecode(response.body)['versions'] as List);
      _cache.set('master_versions', cacheKey, versions);
      return versions;
    } else if (response.statusCode == 429) {
      throw Exception('Trop de requêtes, réessaie dans quelques secondes.');
    } else {
      throw Exception('Erreur Discogs (${response.statusCode})');
    }
  }

  /// Détail complet d'un master : tracklist, genres, styles, images, notes.
  /// Complémentaire de getMasterVersions() — l'un donne le contenu de
  /// l'album, l'autre les pressages disponibles.
  Future<Map<String, dynamic>> getMasterDetails(int masterId) async {
    final cacheKeyId = masterId.toString();
    final cached = _cache.get('master_detail', cacheKeyId);
    if (cached != null) return cached.first as Map<String, dynamic>;

    final url = Uri.parse('$_baseUrl/masters/$masterId?token=$token');
    final response = await http.get(url, headers: {'User-Agent': _userAgent});

    if (response.statusCode == 200) {
      final detail = jsonDecode(response.body) as Map<String, dynamic>;
      // _cache attend une List<dynamic> ; on enveloppe/déballe l'objet unique
      // pour réutiliser le même DiscogsCache sans changer sa signature.
      _cache.set('master_detail', cacheKeyId, [detail]);
      return detail;
    } else if (response.statusCode == 429) {
      throw Exception('Trop de requêtes, réessaie dans quelques secondes.');
    } else {
      throw Exception('Erreur Discogs (${response.statusCode})');
    }
  }

  /// Détail complet d'une édition précise (release) : tracklist, notes,
  /// images, etc. Différent de getMasterDetails() — un master est l'entité
  /// "album" générique, un release est un pressage précis (deluxe, réédition,
  /// pays différent...) qui peut avoir sa propre tracklist (bonus tracks,
  /// disc 2, etc.). Appelé quand l'utilisateur choisit une édition dans la
  /// modal de détail.
  Future<Map<String, dynamic>> getReleaseDetails(int releaseId) async {
    final cacheKeyId = releaseId.toString();
    final cached = _cache.get('release_detail', cacheKeyId);
    if (cached != null) return cached.first as Map<String, dynamic>;

    final url = Uri.parse('$_baseUrl/releases/$releaseId?token=$token');
    final response = await http.get(url, headers: {'User-Agent': _userAgent});

    if (response.statusCode == 200) {
      final detail = jsonDecode(response.body) as Map<String, dynamic>;
      // Même enveloppe List<dynamic> que master_detail, pour rester
      // compatible avec la signature existante de DiscogsCache.
      _cache.set('release_detail', cacheKeyId, [detail]);
      return detail;
    } else if (response.statusCode == 429) {
      throw Exception('Trop de requêtes, réessaie dans quelques secondes.');
    } else {
      throw Exception('Erreur Discogs (${response.statusCode})');
    }
  }

  /// Vide le cache. Utile pour les tests, ou un futur bouton "rafraîchir".
  void clearCache() => _cache.clear();
}
