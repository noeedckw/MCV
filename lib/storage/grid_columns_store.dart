import 'package:shared_preferences/shared_preferences.dart';

/// Cache en mémoire (synchrone) des préférences de colonnes de grille,
/// adossé à `SharedPreferences` pour la persistance entre les sessions.
///
/// Permet à n'importe quelle grille (`ExplorerResultsGrid`,
/// `CollectionGrid`, ...) de lire sa valeur sauvegardée de façon
/// SYNCHRONE dès `initState`, sans jamais afficher un état par défaut
/// avant la vraie valeur — même quand le `State` est recréé.
///
/// Appeler [GridColumnsStore.init] une fois, tôt dans `main()`, avant
/// `runApp`.
class GridColumnsStore {
  GridColumnsStore._();

  static SharedPreferences? _prefs;
  static final Map<String, int> _cache = {};

  static const _keyPrefix = 'grid_columns_';

  /// À appeler une fois au démarrage, avant `runApp(...)`.
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    for (final k in _prefs!.getKeys()) {
      if (k.startsWith(_keyPrefix)) {
        final v = _prefs!.getInt(k);
        if (v != null) _cache[k.substring(_keyPrefix.length)] = v;
      }
    }
  }

  /// Lecture synchrone — utilisable directement dans `initState`.
  /// [gridKey] ex: `'explorer'`, `'collection'`, `'wantlist'`.
  static int? get(String gridKey) => _cache[gridKey];

  /// Écrit en mémoire immédiatement (donc dispo tout de suite pour tout
  /// nouveau `State`) puis persiste sur disque en arrière-plan.
  static void set(String gridKey, int columns) {
    _cache[gridKey] = columns;
    _prefs?.setInt('$_keyPrefix$gridKey', columns);
  }
}