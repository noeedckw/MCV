import 'dart:convert';
import 'dart:typed_data';
import 'package:idb_shim/idb_browser.dart';
import 'local_storage_service.dart';
import 'vinyl_entry.dart';

class LocalStorageServiceImpl implements LocalStorageService {
  late Database _db;
  static const _store = 'vinyls';
  // v1/v2 devices have this store; it's only read once during migration,
  // never written to again.
  static const _legacyWishlistStore = 'wishlist';

  @override
  Future<void> init() async {
    final idbFactory = getIdbFactory()!;
    _db = await idbFactory.open(
      'vinyl_collection',
      version: 3,
      onUpgradeNeeded: (VersionChangeEvent event) async {
        // idb_shim expose directement .database et .transaction sur
        // l'event — plus besoin du cast event.target as Request/OpenDBRequest
        // qu'on faisait avec dart:indexed_db.
        final db = event.database;
        final txn = event.transaction;

        if (!db.objectStoreNames.contains(_store)) {
          db.createObjectStore(_store, autoIncrement: true, keyPath: 'id');
        }

        if (db.objectStoreNames.contains(_legacyWishlistStore)) {
          final legacyStore = txn.objectStore(_legacyWishlistStore);
          final unifiedStore = txn.objectStore(_store);
          await for (final cursor in legacyStore.openCursor(
            autoAdvance: true,
          )) {
            final value = Map<String, dynamic>.from(cursor.value as Map);
            value['isWishlist'] = true;
            value.putIfAbsent('condition', () => null);
            value.putIfAbsent('releaseId', () => null);
            value.putIfAbsent('releaseCountry', () => null);
            value.putIfAbsent('releaseDate', () => null);
            await unifiedStore.put(value);
          }
          db.deleteObjectStore(_legacyWishlistStore);
        }
      },
    );
  }

  // NOTE: smoke-test le chemin de migration en navigateur (bump de version,
  // reload sur une IndexedDB v1/v2 existante) avant de shipper — idb_shim
  // reproduit fidèlement l'API dart:indexed_db mais mérite un test réel du
  // upgrade path côté navigateur.

  VinylEntry _fromMap(Map value) => VinylEntry(
    id: value['id'] as int?,
    discogsId: value['discogsId'] as int?,
    artist: value['artist'] as String,
    title: value['title'] as String,
    year: value['year'] as int?,
    label: value['label'] as String?,
    format: value['format'] as String?,
    condition: value['condition'] as String?,
    coverBytes: value['coverBase64'] != null
        ? base64Decode(value['coverBase64'] as String)
        : null,
    dateAdded: DateTime.parse(value['dateAdded'] as String),
    isWishlist: value['isWishlist'] as bool? ?? false,
    releaseId: value['releaseId'] as int?,
    releaseCountry: value['releaseCountry'] as String?,
    releaseDate: value['releaseDate'] as String?,
    genres: (value['genres'] as List?)?.cast<String>(),
    styles: (value['styles'] as List?)?.cast<String>(),
    tracklist: (value['tracklist'] as List?)
        ?.map((e) => TrackInfo.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    notes: value['notes'] as String?,
    isFavorite: value['isFavorite'] as bool? ?? false,
  );

  Future<void> _insert(
    VinylEntry vinyl,
    bool isWishlist,
    Uint8List? coverImageBytes,
  ) async {
    final txn = _db.transaction(_store, 'readwrite');
    final store = txn.objectStore(_store);
    await store.put({
      'discogsId': vinyl.discogsId,
      'artist': vinyl.artist,
      'title': vinyl.title,
      'year': vinyl.year,
      'label': vinyl.label,
      'format': vinyl.format,
      'condition': vinyl.condition,
      'coverBase64': coverImageBytes != null
          ? base64Encode(coverImageBytes)
          : null,
      'dateAdded': vinyl.dateAdded.toIso8601String(),
      'isWishlist': isWishlist,
      'releaseId': vinyl.releaseId,
      'releaseCountry': vinyl.releaseCountry,
      'releaseDate': vinyl.releaseDate,
      'genres': vinyl.genres,
      'styles': vinyl.styles,
      'tracklist': vinyl.tracklist?.map((t) => t.toJson()).toList(),
      'notes': vinyl.notes,
      'isFavorite': vinyl.isFavorite,
    });
  }

  Future<List<VinylEntry>> _getAll({required bool isWishlist}) async {
    final txn = _db.transaction(_store, 'readonly');
    final store = txn.objectStore(_store);
    final results = <VinylEntry>[];
    await for (final cursor in store.openCursor(autoAdvance: true)) {
      final value = cursor.value as Map;
      if ((value['isWishlist'] as bool? ?? false) == isWishlist) {
        results.add(_fromMap(value));
      }
    }
    return results;
  }

  @override
  Future<List<VinylEntry>> getAllVinyls() => _getAll(isWishlist: false);

  @override
  Future<List<VinylEntry>> getAllWishlist() => _getAll(isWishlist: true);

  @override
  Future<List<VinylEntry>> getAllFavorites() async {
    final all = await _getAll(isWishlist: false);
    return all.where((v) => v.isFavorite).toList();
  }

  @override
  Future<void> insertVinyl(VinylEntry vinyl, {Uint8List? coverImageBytes}) =>
      _insert(vinyl, false, coverImageBytes);

  @override
  Future<void> insertWishlist(VinylEntry vinyl, {Uint8List? coverImageBytes}) =>
      _insert(vinyl, true, coverImageBytes);

  @override
  Future<void> deleteVinyl(int id) async {
    final txn = _db.transaction(_store, 'readwrite');
    await txn.objectStore(_store).delete(id);
  }

  Future<void> _deleteByDiscogsId(
    int discogsId,
    bool isWishlist, {
    int? releaseId,
  }) async {
    final txn = _db.transaction(_store, 'readwrite');
    final store = txn.objectStore(_store);
    await for (final cursor in store.openCursor(autoAdvance: false)) {
      final value = cursor.value as Map;
      if (value['discogsId'] == discogsId &&
          value['releaseId'] == releaseId &&
          (value['isWishlist'] as bool? ?? false) == isWishlist) {
        await cursor.delete();
        break;
      }
      cursor.next();
    }
  }

  @override
  Future<void> deleteVinylByDiscogsId(int discogsId, {int? releaseId}) =>
      _deleteByDiscogsId(discogsId, false, releaseId: releaseId);

  @override
  Future<void> removeWishlistByDiscogsId(int discogsId, {int? releaseId}) =>
      _deleteByDiscogsId(discogsId, true, releaseId: releaseId);

  Future<bool> _existsByDiscogsId(
    int discogsId,
    bool isWishlist, {
    int? releaseId,
  }) async {
    final all = await _getAll(isWishlist: isWishlist);
    return all.any((v) => v.discogsId == discogsId && v.releaseId == releaseId);
  }

  @override
  Future<bool> vinylExistsByDiscogsId(int discogsId, {int? releaseId}) =>
      _existsByDiscogsId(discogsId, false, releaseId: releaseId);

  @override
  Future<bool> wishlistExistsByDiscogsId(int discogsId, {int? releaseId}) =>
      _existsByDiscogsId(discogsId, true, releaseId: releaseId);

  Future<void> _setWishlist(
    int discogsId,
    bool isWishlist, {
    int? releaseId,
  }) async {
    final txn = _db.transaction(_store, 'readwrite');
    final store = txn.objectStore(_store);
    await for (final cursor in store.openCursor(autoAdvance: false)) {
      final value = Map<String, dynamic>.from(cursor.value as Map);
      if (value['discogsId'] == discogsId &&
          value['releaseId'] == releaseId &&
          (value['isWishlist'] as bool? ?? false) == !isWishlist) {
        value['isWishlist'] = isWishlist;
        await cursor.update(value);
        break;
      }
      cursor.next();
    }
  }

  @override
  Future<void> moveToCollection(int discogsId, {int? releaseId}) =>
      _setWishlist(discogsId, false, releaseId: releaseId);

  @override
  Future<void> moveToWishlist(int discogsId, {int? releaseId}) =>
      _setWishlist(discogsId, true, releaseId: releaseId);

  @override
  Future<void> setFavorite(int id, bool isFavorite) async {
    final txn = _db.transaction(_store, 'readwrite');
    final store = txn.objectStore(_store);
    await for (final cursor in store.openCursor(autoAdvance: false)) {
      final value = Map<String, dynamic>.from(cursor.value as Map);
      if (value['id'] == id) {
        value['isFavorite'] = isFavorite;
        await cursor.update(value);
        break;
      }
      cursor.next();
    }
  }
}