import 'dart:convert';
import 'package:http/http.dart' as http;

import 'discogs_cache.dart';
import 'token_storage_service.dart';

/// Levée quand Discogs répond 401 : la clé enregistrée n'est plus valide
/// (révoquée, expirée...). Permet à l'UI de forcer un retour à
/// DiscogsSetupScreen sans confondre ça avec une erreur réseau générique.
class DiscogsAuthException implements Exception {
  final String message;
  const DiscogsAuthException(this.message);

  @override
  String toString() => message;
}

class DiscogsApi {
  final String token;
  final DiscogsCache _cache;

  DiscogsApi(this.token, {DiscogsCache? cache})
    : _cache = cache ?? DiscogsCache();

  /// Construit l'instance à partir du token stocké. À utiliser au démarrage,
  /// une fois que AppGate a confirmé qu'un token existe. Lève une exception
  /// si aucun token n'est trouvé — ne devrait normalement jamais arriver
  /// puisque AppGate garde l'accès à l'app.
  static Future<DiscogsApi> fromStorage(
    TokenStorageService storage, {
    DiscogsCache? cache,
  }) async {
    final token = await storage.getToken();
    if (token == null) {
      throw const DiscogsAuthException('Aucune clé Discogs configurée.');
    }
    return DiscogsApi(token, cache: cache);
  }

  static const _baseUrl = 'https://api.discogs.com';
  static const _userAgent = 'VinylCollectionApp/1.0';

  /// Centralise la gestion des statuts d'erreur communs à tous les endpoints.
  /// Utilisé après chaque appel http.get pour éviter de dupliquer les
  /// mêmes if/else dans les 5 méthodes.
  Never _throwForStatus(int statusCode) {
    if (statusCode == 401) {
      throw const DiscogsAuthException(
        'Votre clé Discogs a été refusée. Reconnectez votre compte.',
      );
    } else if (statusCode == 429) {
      throw Exception('Trop de requêtes, réessaie dans quelques secondes.');
    } else {
      throw Exception('Erreur Discogs ($statusCode)');
    }
  }

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
    }
    _throwForStatus(response.statusCode);
  }

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
    }
    _throwForStatus(response.statusCode);
  }

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
    }
    _throwForStatus(response.statusCode);
  }

  Future<Map<String, dynamic>> getMasterDetails(int masterId) async {
    final cacheKeyId = masterId.toString();
    final cached = _cache.get('master_detail', cacheKeyId);
    if (cached != null) return cached.first as Map<String, dynamic>;

    final url = Uri.parse('$_baseUrl/masters/$masterId?token=$token');
    final response = await http.get(url, headers: {'User-Agent': _userAgent});

    if (response.statusCode == 200) {
      final detail = jsonDecode(response.body) as Map<String, dynamic>;
      _cache.set('master_detail', cacheKeyId, [detail]);
      return detail;
    }
    _throwForStatus(response.statusCode);
  }

  Future<Map<String, dynamic>> getReleaseDetails(int releaseId) async {
    final cacheKeyId = releaseId.toString();
    final cached = _cache.get('release_detail', cacheKeyId);
    if (cached != null) return cached.first as Map<String, dynamic>;

    final url = Uri.parse('$_baseUrl/releases/$releaseId?token=$token');
    final response = await http.get(url, headers: {'User-Agent': _userAgent});

    if (response.statusCode == 200) {
      final detail = jsonDecode(response.body) as Map<String, dynamic>;
      _cache.set('release_detail', cacheKeyId, [detail]);
      return detail;
    }
    _throwForStatus(response.statusCode);
  }

  void clearCache() => _cache.clear();
}