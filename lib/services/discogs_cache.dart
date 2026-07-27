/// Cache mémoire simple pour les résultats de recherche Discogs.
///
/// Clé = type d'appel + requête normalisée (trim + lowercase). Le type
/// (ex: "release", "master") évite qu'une recherche de releases et une
/// recherche de masters sur la même query se marchent dessus dans le cache.
///
/// 100% mémoire pour l'instant (perdu au redémarrage de l'app). La classe
/// est isolée exprès : pour migrer vers un cache persistant (shared_preferences,
/// Hive, etc.) plus tard, il suffira de changer get/set ici, sans toucher
/// au reste du code.
class DiscogsCache {
  final Map<String, List<dynamic>> _store = {};

  String _key(String type, String query) =>
      '$type:${query.trim().toLowerCase()}';

  List<dynamic>? get(String type, String query) => _store[_key(type, query)];

  void set(String type, String query, List<dynamic> results) {
    // List.unmodifiable pour éviter qu'un appelant mute accidentellement
    // une entrée de cache partagée entre plusieurs écrans/widgets.
    _store[_key(type, query)] = List.unmodifiable(results);
  }

  void clear() => _store.clear();
}