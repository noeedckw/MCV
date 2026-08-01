import 'dart:typed_data';
import 'vinyl_entry.dart';

abstract class LocalStorageService {
  Future<void> init();

  // Collection and wantlist are now the same underlying store, split by
  // VinylEntry.isWantlist — kept as separate methods here (rather than a
  // single `getAll()` + filter) so existing call sites don't need to change.

  Future<List<VinylEntry>> getAllVinyls();
  Future<void> insertVinyl(VinylEntry vinyl, {Uint8List? coverImageBytes});
  Future<void> deleteVinyl(int id);
  Future<bool> vinylExistsByDiscogsId(int discogsId, {int? releaseId});
  Future<void> deleteVinylByDiscogsId(int discogsId, {int? releaseId});

  Future<List<VinylEntry>> getAllWantlist();
  Future<void> insertWantlist(VinylEntry vinyl, {Uint8List? coverImageBytes});
  Future<void> removeWantlistByDiscogsId(int discogsId, {int? releaseId});
  Future<bool> wantlistExistsByDiscogsId(int discogsId, {int? releaseId});

  Future<void> moveToCollection(int discogsId, {int? releaseId});
  Future<void> moveToWantlist(int discogsId, {int? releaseId});

  // --- Favoris ---
  // Uniquement pour les entrées de la collection (isWantlist == false).
  // Basé sur l'id local (VinylEntry.id) plutôt que discogsId/releaseId,
  // puisque le toggle part toujours d'une entrée déjà chargée qui a son id.

  /// Bascule le statut favori d'une entrée de la collection.
  Future<void> setFavorite(int id, bool isFavorite);

  /// Entrées de la collection marquées favorites.
  Future<List<VinylEntry>> getAllFavorites();
}