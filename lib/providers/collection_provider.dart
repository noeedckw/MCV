import 'package:flutter/foundation.dart';
import '../storage/local_storage_service.dart';
import '../storage/vinyl_entry.dart';
import '../utils/vinyl_sort.dart';

// Réexporté pour que le code existant qui fait
// `import 'collection_provider.dart'` continue de voir CollectionSort sans
// rien changer chez lui — seul le tri lui-même a déménagé.
export '../utils/vinyl_sort.dart' show CollectionSort;

enum CollectionView { owned, wishlist }

class CollectionProvider extends ChangeNotifier {
  final LocalStorageService storage;
  List<VinylEntry> vinyls = [];
  String searchQuery = '';

  // Owned-only filter — favorites don't exist on wishlist entries, so this
  // has no effect when `view == CollectionView.wishlist`; see
  // filteredVinylsFor below.
  bool favoritesOnly = false;

  CollectionView view = CollectionView.owned;
  CollectionSort sort = CollectionSort.dateAdded;
  bool sortDescending = true; // le plus récent d'abord par défaut

  CollectionProvider(this.storage) {
    reload();
  }

  Future<void> reload() async {
    // getAllVinyls() / getAllWishlist() are the same underlying table split
    // by isWishlist (see LocalStorageService) — `vinyls` here holds both,
    // since _viewVinyls below filters on isWishlist itself.
    final owned = await storage.getAllVinyls();
    final wishlist = await storage.getAllWishlist();
    vinyls = [...owned, ...wishlist];
    notifyListeners();
  }

  List<VinylEntry> _viewVinylsFor(CollectionView targetView) => vinyls
      .where((v) => v.isWishlist == (targetView == CollectionView.wishlist))
      .toList();

  List<VinylEntry> filteredVinylsFor(CollectionView targetView) {
    var list = _viewVinylsFor(targetView);

    // Le filtre favoris n'a de sens que pour la collection possédée — les
    // entrées wishlist n'ont jamais isFavorite=true (voir toggleFavorite,
    // jamais câblé depuis la vue wishlist), donc sans ce garde-fou la
    // wishlist se retrouvait vidée dès que favoritesOnly était actif sur
    // owned, alors que ce sont deux listes indépendantes dans le PageView.
    if (favoritesOnly && targetView == CollectionView.owned) {
      list = list.where((v) => v.isFavorite).toList();
    }

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

    return sortVinyls(list, sort: sort, descending: sortDescending);
  }

  List<VinylEntry> get filteredVinyls => filteredVinylsFor(view);

  int get ownedCount => vinyls.where((v) => !v.isWishlist).length;
  int get wishlistCount => vinyls.where((v) => v.isWishlist).length;

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

  void setFavoritesOnly(bool value) {
    if (favoritesOnly == value) return;
    favoritesOnly = value;
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
      if (entry.isWishlist) {
        await storage.removeWishlistByDiscogsId(
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

  Future<void> moveToWishlist(VinylEntry entry) async {
    if (entry.discogsId == null) return;
    await storage.moveToWishlist(entry.discogsId!, releaseId: entry.releaseId);
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

  // Favorites only make sense for owned entries (see VinylEntry.isFavorite
  // doc + CollectionResultCard/collection_album_detail_modal, both of
  // which already hide the heart on wishlist items) — no isWishlist guard
  // needed here since callers only ever wire this up from the owned view.
  Future<void> toggleFavorite(VinylEntry entry) async {
    if (entry.id == null) return;
    await storage.setFavorite(entry.id!, !entry.isFavorite);
    await reload();
  }
}