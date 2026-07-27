import 'dart:convert';
import 'dart:html';
import 'dart:indexed_db';
import 'dart:typed_data';
import 'local_storage_service.dart';
import 'vinyl_entry.dart';

class LocalStorageServiceImpl implements LocalStorageService {
  late Database _db;
  static const _store = 'vinyls';
  // v1/v2 devices have this store; it's only read once during migration,
  // never written to again.
  static const _legacyWantlistStore = 'wantlist';

  @override
  Future<void> init() async {
    // v3: 'vinyls' and 'wantlist' become one store, distinguished by the
    // isWantlist flag on each record, matching the native/drift storage.
    _db = await window.indexedDB!.open(
      'vinyl_collection',
      version: 3,
      onUpgradeNeeded: (VersionChangeEvent event) async {
        final db = (event.target as Request).result as Database;
        // NB: only the versionchange transaction from this open request can
        // touch object stores here — this is the one IndexedDB hands us via
        // the open request itself, not a freshly-opened transaction.
        final txn = (event.target as OpenDBRequest).transaction!;

        if (!db.objectStoreNames!.contains(_store)) {
          db.createObjectStore(_store, autoIncrement: true, keyPath: 'id');
        }

        if (db.objectStoreNames!.contains(_legacyWantlistStore)) {
          final legacyStore = txn.objectStore(_legacyWantlistStore);
          final unifiedStore = txn.objectStore(_store);
          await for (final cursor
              in legacyStore.openCursor(autoAdvance: true)) {
            final value = Map<String, dynamic>.from(cursor.value as Map);
            value['isWantlist'] = true;
            value.putIfAbsent('condition', () => null);
            value.putIfAbsent('releaseId', () => null);
            value.putIfAbsent('releaseCountry', () => null);
            value.putIfAbsent('releaseDate', () => null);
            await unifiedStore.put(value);
          }
          db.deleteObjectStore(_legacyWantlistStore);
        }
      },
    );
  }

  // NOTE: dart:indexed_db's exact typing for reaching the versionchange
  // transaction off the open request (OpenDBRequest.transaction) varies a
  // bit by SDK version — this compiled against the API shape used
  // elsewhere in your codebase, but please smoke-test the upgrade path in
  // a browser (bump version, reload against an existing v1/v2 IndexedDB)
  // before shipping; if `event.target` doesn't resolve to OpenDBRequest in
  // your SDK, use whatever accessor you already use elsewhere for it.

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
      isWantlist: value['isWantlist'] as bool? ?? false,
      releaseId: value['releaseId'] as int?,
      releaseCountry: value['releaseCountry'] as String?,
      releaseDate: value['releaseDate'] as String?,
      genres: (value['genres'] as List?)?.cast<String>(),
      styles: (value['styles'] as List?)?.cast<String>(),
      tracklist: (value['tracklist'] as List?)
          ?.map((e) => TrackInfo.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      notes: value['notes'] as String?,
    );

  Future<void> _insert(
    VinylEntry vinyl,
    bool isWantlist,
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
      'coverBase64':
          coverImageBytes != null ? base64Encode(coverImageBytes) : null,
      'dateAdded': vinyl.dateAdded.toIso8601String(),
      'isWantlist': isWantlist,
      'releaseId': vinyl.releaseId,
      'releaseCountry': vinyl.releaseCountry,
      'releaseDate': vinyl.releaseDate,
      'genres': vinyl.genres,
      'styles': vinyl.styles,
      'tracklist': vinyl.tracklist?.map((t) => t.toJson()).toList(),
      'notes': vinyl.notes,
    });
  }

  Future<List<VinylEntry>> _getAll({required bool isWantlist}) async {
    final txn = _db.transaction(_store, 'readonly');
    final store = txn.objectStore(_store);
    final results = <VinylEntry>[];
    await for (final cursor in store.openCursor(autoAdvance: true)) {
      final value = cursor.value as Map;
      if ((value['isWantlist'] as bool? ?? false) == isWantlist) {
        results.add(_fromMap(value));
      }
    }
    return results;
  }

  @override
  Future<List<VinylEntry>> getAllVinyls() => _getAll(isWantlist: false);

  @override
  Future<List<VinylEntry>> getAllWantlist() => _getAll(isWantlist: true);

  @override
  Future<void> insertVinyl(VinylEntry vinyl, {Uint8List? coverImageBytes}) =>
      _insert(vinyl, false, coverImageBytes);

  @override
  Future<void> insertWantlist(VinylEntry vinyl,
          {Uint8List? coverImageBytes}) =>
      _insert(vinyl, true, coverImageBytes);

  @override
  Future<void> deleteVinyl(int id) async {
    final txn = _db.transaction(_store, 'readwrite');
    await txn.objectStore(_store).delete(id);
  }

  Future<void> _deleteByDiscogsId(int discogsId, bool isWantlist, {int? releaseId}) async {
    final txn = _db.transaction(_store, 'readwrite');
    final store = txn.objectStore(_store);
    await for (final cursor in store.openCursor(autoAdvance: false)) {
      final value = cursor.value as Map;
      if (value['discogsId'] == discogsId &&
          value['releaseId'] == releaseId &&
          (value['isWantlist'] as bool? ?? false) == isWantlist) {
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
  Future<void> removeWantlistByDiscogsId(int discogsId, {int? releaseId}) =>
      _deleteByDiscogsId(discogsId, true, releaseId: releaseId);

  Future<bool> _existsByDiscogsId(int discogsId, bool isWantlist, {int? releaseId}) async {
    final all = await _getAll(isWantlist: isWantlist);
    return all.any((v) => v.discogsId == discogsId && v.releaseId == releaseId);
  }

  @override
  Future<bool> vinylExistsByDiscogsId(int discogsId, {int? releaseId}) =>
      _existsByDiscogsId(discogsId, false, releaseId: releaseId);

  @override
  Future<bool> wantlistExistsByDiscogsId(int discogsId, {int? releaseId}) =>
      _existsByDiscogsId(discogsId, true, releaseId: releaseId);

  Future<void> _setWantlist(int discogsId, bool isWantlist, {int? releaseId}) async {
    final txn = _db.transaction(_store, 'readwrite');
    final store = txn.objectStore(_store);
    await for (final cursor in store.openCursor(autoAdvance: false)) {
      final value = Map<String, dynamic>.from(cursor.value as Map);
      if (value['discogsId'] == discogsId &&
          value['releaseId'] == releaseId &&
          (value['isWantlist'] as bool? ?? false) == !isWantlist) {
        value['isWantlist'] = isWantlist;
        await cursor.update(value);
        break;
      }
      cursor.next();
    }
  }

  @override
  Future<void> moveToCollection(int discogsId, {int? releaseId}) =>
      _setWantlist(discogsId, false, releaseId: releaseId);

  @override
  Future<void> moveToWantlist(int discogsId, {int? releaseId}) =>
      _setWantlist(discogsId, true, releaseId: releaseId);
}