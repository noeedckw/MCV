import 'dart:io';
import 'dart:typed_data';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'local_storage_service.dart';
import 'vinyl_entry.dart';
import 'dart:convert';

part 'local_storage_native.g.dart';

// Single table for both the owned collection and the wantlist now.
// `isWantlist` is the discriminator: moving an item between the two lists
// is a column update instead of a delete-in-one-table / insert-in-another,
// which previously made "move without duplicating" (and preserving
// releaseId/condition/original dateAdded) awkward with two tables.
class VinylsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get discogsId => integer().nullable()();
  TextColumn get artist => text()();
  TextColumn get title => text()();
  IntColumn get year => integer().nullable()();
  TextColumn get label => text().nullable()();
  TextColumn get format => text().nullable()();
  TextColumn get condition => text().nullable()();
  TextColumn get localCoverPath => text().nullable()();
  DateTimeColumn get dateAdded =>
      dateTime().clientDefault(() => DateTime.now())();

  BoolColumn get isWantlist => boolean().withDefault(const Constant(false))();
  IntColumn get releaseId => integer().nullable()();
  TextColumn get releaseCountry => text().nullable()();
  TextColumn get releaseDate => text().nullable()();

  // --- v4 ---
  TextColumn get genres => text().nullable()(); // JSON-encoded List<String>
  TextColumn get styles => text().nullable()(); // JSON-encoded List<String>

  // --- v5 ---
  TextColumn get tracklist => text().nullable()(); // JSON-encoded List<Map>
  TextColumn get notes => text().nullable()();
}

@DriftDatabase(tables: [VinylsTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 3) {
            await m.addColumn(vinylsTable, vinylsTable.isWantlist);
            await m.addColumn(vinylsTable, vinylsTable.releaseId);
            await m.addColumn(vinylsTable, vinylsTable.releaseCountry);
            await m.addColumn(vinylsTable, vinylsTable.releaseDate);

            final hasLegacyWantlistTable = await m.database
                .customSelect(
                  "SELECT name FROM sqlite_master WHERE type='table' AND name='wantlist_table'",
                )
                .getSingleOrNull();

            if (hasLegacyWantlistTable != null) {
              await m.database.customStatement('''
                INSERT INTO vinyls_table
                  (discogs_id, artist, title, year, label, format, local_cover_path, date_added, is_wantlist)
                SELECT
                  discogs_id, artist, title, year, label, format, local_cover_path, date_added, 1
                FROM wantlist_table
              ''');
              await m.database.customStatement('DROP TABLE wantlist_table');
            }
          }
          if (from < 4) {
            await m.addColumn(vinylsTable, vinylsTable.genres);
            await m.addColumn(vinylsTable, vinylsTable.styles);
          }
          if (from < 5) {
            await m.addColumn(vinylsTable, vinylsTable.tracklist);
            await m.addColumn(vinylsTable, vinylsTable.notes);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'vinyl_collection.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

class LocalStorageServiceImpl implements LocalStorageService {
  late final AppDatabase _db;

  @override
  Future<void> init() async {
    _db = AppDatabase();
  }

  VinylEntry _toEntry(VinylsTableData r) => VinylEntry(
        id: r.id,
        discogsId: r.discogsId,
        artist: r.artist,
        title: r.title,
        year: r.year,
        label: r.label,
        format: r.format,
        condition: r.condition,
        localCoverPath: r.localCoverPath,
        dateAdded: r.dateAdded,
        isWantlist: r.isWantlist,
        releaseId: r.releaseId,
        releaseCountry: r.releaseCountry,
        releaseDate: r.releaseDate,
        genres: r.genres != null ? (jsonDecode(r.genres!) as List).cast<String>() : null,
        styles: r.styles != null ? (jsonDecode(r.styles!) as List).cast<String>() : null,
        tracklist: r.tracklist != null
            ? (jsonDecode(r.tracklist!) as List)
                .map((e) => TrackInfo.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList()
            : null,
        notes: r.notes,
      );

  @override
  Future<List<VinylEntry>> getAllVinyls() async {
    final rows = await (_db.select(_db.vinylsTable)
          ..where((t) => t.isWantlist.equals(false)))
        .get();
    return rows.map(_toEntry).toList();
  }

  @override
  Future<List<VinylEntry>> getAllWantlist() async {
    final rows = await (_db.select(_db.vinylsTable)
          ..where((t) => t.isWantlist.equals(true)))
        .get();
    return rows.map(_toEntry).toList();
  }

  Future<void> _insert(
    VinylEntry vinyl,
    bool isWantlist,
    Uint8List? coverImageBytes,
  ) async {
    final coverPath = await _writeCoverIfNeeded(
      isWantlist ? 'wantlist' : 'vinyl',
      vinyl.discogsId,
      coverImageBytes,
    );

    await _db.into(_db.vinylsTable).insert(VinylsTableCompanion.insert(
          discogsId: Value(vinyl.discogsId),
          artist: vinyl.artist,
          title: vinyl.title,
          year: Value(vinyl.year),
          label: Value(vinyl.label),
          format: Value(vinyl.format),
          condition: Value(vinyl.condition),
          localCoverPath: Value(coverPath),
          isWantlist: Value(isWantlist),
          releaseId: Value(vinyl.releaseId),
          releaseCountry: Value(vinyl.releaseCountry),
          releaseDate: Value(vinyl.releaseDate),
          genres: Value(vinyl.genres != null ? jsonEncode(vinyl.genres) : null),
          styles: Value(vinyl.styles != null ? jsonEncode(vinyl.styles) : null),
          tracklist: Value(
            vinyl.tracklist != null
                ? jsonEncode(vinyl.tracklist!.map((t) => t.toJson()).toList())
                : null,
          ),
          notes: Value(vinyl.notes),
        ));
  }

  @override
  Future<void> insertVinyl(VinylEntry vinyl, {Uint8List? coverImageBytes}) =>
      _insert(vinyl, false, coverImageBytes);

  @override
  Future<void> insertWantlist(VinylEntry vinyl,
          {Uint8List? coverImageBytes}) =>
      _insert(vinyl, true, coverImageBytes);

  @override
  Future<void> deleteVinyl(int id) async {
    await (_db.delete(_db.vinylsTable)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> deleteVinylByDiscogsId(int discogsId, {int? releaseId}) async {
    await (_db.delete(_db.vinylsTable)
          ..where((t) =>
              t.discogsId.equals(discogsId) &
              t.isWantlist.equals(false) &
              (releaseId == null ? t.releaseId.isNull() : t.releaseId.equals(releaseId))))
        .go();
  }

  @override
  Future<void> removeWantlistByDiscogsId(int discogsId, {int? releaseId}) async {
    await (_db.delete(_db.vinylsTable)
          ..where((t) =>
              t.discogsId.equals(discogsId) &
              t.isWantlist.equals(true) &
              (releaseId == null ? t.releaseId.isNull() : t.releaseId.equals(releaseId))))
        .go();
  }

  @override
  Future<bool> vinylExistsByDiscogsId(int discogsId, {int? releaseId}) async {
    final result = await (_db.select(_db.vinylsTable)
          ..where((t) =>
              t.discogsId.equals(discogsId) &
              t.isWantlist.equals(false) &
              (releaseId == null ? t.releaseId.isNull() : t.releaseId.equals(releaseId))))
        .getSingleOrNull();
    return result != null;
  }

  @override
  Future<bool> wantlistExistsByDiscogsId(int discogsId, {int? releaseId}) async {
    final result = await (_db.select(_db.vinylsTable)
          ..where((t) =>
              t.discogsId.equals(discogsId) &
              t.isWantlist.equals(true) &
              (releaseId == null ? t.releaseId.isNull() : t.releaseId.equals(releaseId))))
        .getSingleOrNull();
    return result != null;
  }

  @override
  Future<void> moveToCollection(int discogsId, {int? releaseId}) async {
    await (_db.update(_db.vinylsTable)
          ..where((t) =>
              t.discogsId.equals(discogsId) &
              t.isWantlist.equals(true) &
              (releaseId == null ? t.releaseId.isNull() : t.releaseId.equals(releaseId))))
        .write(const VinylsTableCompanion(isWantlist: Value(false)));
  }

  @override
  Future<void> moveToWantlist(int discogsId, {int? releaseId}) async {
    await (_db.update(_db.vinylsTable)
          ..where((t) =>
              t.discogsId.equals(discogsId) &
              t.isWantlist.equals(false) &
              (releaseId == null ? t.releaseId.isNull() : t.releaseId.equals(releaseId))))
        .write(const VinylsTableCompanion(isWantlist: Value(true)));
  }

  Future<String?> _writeCoverIfNeeded(
      String prefix, int? discogsId, Uint8List? bytes) async {
    if (bytes == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    final coversDir = Directory(p.join(dir.path, 'covers'));
    if (!await coversDir.exists()) await coversDir.create(recursive: true);
    final file =
        File(p.join(coversDir.path, '${prefix}_discogs_$discogsId.jpg'));
    await file.writeAsBytes(bytes);
    return file.path;
  }
}