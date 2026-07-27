import 'package:flutter/foundation.dart';
import '../storage/local_storage_service.dart';
import '../storage/vinyl_entry.dart';

enum CollectionView { owned, wantlist }

enum CollectionSort { dateAdded, artist, album, releaseDate }

class CollectionProvider extends ChangeNotifier {
  final LocalStorageService storage;
  List<VinylEntry> vinyls = [];
  String searchQuery = '';

  CollectionView view = CollectionView.owned;
  CollectionSort sort = CollectionSort.dateAdded;
  bool sortDescending = true; // le plus récent d'abord par défaut

  CollectionProvider(this.storage) {
    reload();
  }

  Future<void> reload() async {
    // getAllVinyls() / getAllWantlist() are the same underlying table split
    // by isWantlist (see LocalStorageService) — `vinyls` here holds both,
    // since _viewVinyls below filters on isWantlist itself.
    final owned = await storage.getAllVinyls();
    final wantlist = await storage.getAllWantlist();
    vinyls = [...owned, ...wantlist];
    notifyListeners();
  }

  List<VinylEntry> get _viewVinyls => vinyls
      .where((v) => v.isWantlist == (view == CollectionView.wantlist))
      .toList();

  // Best-effort release date extraction for sorting: prefers a full parsed
  // date (when releaseDate holds something like "2011-05-09"), falls back
  // to just the year, and treats anything unparseable/missing as unknown.
  // Unknown entries always sort to the end, regardless of sort direction,
  // instead of clumping at whichever end -1969-epoch/null comparisons
  // would otherwise push them to.
  DateTime? _releaseDateOf(VinylEntry v) {
    final raw = v.releaseDate;
    if (raw != null && raw.isNotEmpty) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed;
    }
    if (v.year != null && v.year != 0) {
      return DateTime(v.year!);
    }
    return null;
  }

  List<VinylEntry> get filteredVinyls {
    var list = _viewVinyls;

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list
          .where(
            (v) =>
                v.artist.toLowerCase().contains(q) ||
                v.title.toLowerCase().contains(q),
          )
          .toList();
    }

    list.sort((a, b) {
      int cmp;
      switch (sort) {
        case CollectionSort.artist:
          cmp = a.artist.toLowerCase().compareTo(b.artist.toLowerCase());
          break;
        case CollectionSort.album:
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case CollectionSort.dateAdded:
          cmp = a.dateAdded.compareTo(b.dateAdded);
          break;
        case CollectionSort.releaseDate:
          final da = _releaseDateOf(a);
          final db = _releaseDateOf(b);
          if (da == null && db == null) {
            cmp = 0;
          } else if (da == null) {
            cmp = 1; // unknown always last
          } else if (db == null) {
            cmp = -1;
          } else {
            cmp = da.compareTo(db);
          }
          break;
      }
      // Unknown release dates stay pinned last even when the list is
      // flipped to ascending -> don't invert that particular comparison.
      if (sort == CollectionSort.releaseDate &&
          (_releaseDateOf(a) == null || _releaseDateOf(b) == null)) {
        return cmp;
      }
      return sortDescending ? -cmp : cmp;
    });

    return list;
  }

  int get ownedCount => vinyls.where((v) => !v.isWantlist).length;
  int get wantlistCount => vinyls.where((v) => v.isWantlist).length;

  void setView(CollectionView newView) {
    if (view == newView) return;
    view = newView;
    notifyListeners();
  }

  // Retaper le même critère de tri inverse juste l'ordre, comme sur
  // beaucoup d'apps -> pas besoin d'un bouton séparé pour ça, mais
  // toggleSortDirection reste dispo pour un bouton explicite dans l'UI.
  void setSort(CollectionSort newSort) {
    if (sort == newSort) {
      sortDescending = !sortDescending;
    } else {
      sort = newSort;
      sortDescending =
          sort == CollectionSort.dateAdded ||
          sort == CollectionSort.releaseDate;
    }
    notifyListeners();
  }

  void toggleSortDirection() {
    sortDescending = !sortDescending;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  Future<void> deleteVinyl(int id) async {
    await storage.deleteVinyl(id);
    await reload();
  }

  Future<void> removeEntry(VinylEntry entry) async {
    if (entry.discogsId != null) {
      if (entry.isWantlist) {
        await storage.removeWantlistByDiscogsId(
          entry.discogsId!,
          releaseId: entry.releaseId,
        );
      } else {
        await storage.deleteVinylByDiscogsId(
          entry.discogsId!,
          releaseId: entry.releaseId,
        );
      }
    } else if (entry.id != null) {
      await storage.deleteVinyl(entry.id!);
    }
    await reload();
  }

  Future<void> moveToWantlist(VinylEntry entry) async {
    if (entry.discogsId == null) return;
    await storage.moveToWantlist(entry.discogsId!, releaseId: entry.releaseId);
    await reload();
  }

  Future<void> moveToCollection(VinylEntry entry) async {
    if (entry.discogsId == null) return;
    await storage.moveToCollection(
      entry.discogsId!,
      releaseId: entry.releaseId,
    );
    await reload();
  }
}
