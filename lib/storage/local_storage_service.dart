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
}
