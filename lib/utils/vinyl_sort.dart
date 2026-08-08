import '../storage/vinyl_entry.dart';

enum CollectionSort { dateAdded, artist, album, releaseDate }

/// Best-effort release date extraction for sorting: prefers a full parsed
/// date (when releaseDate holds something like "2011-05-09"), falls back
/// to just the year, and treats anything unparseable/missing as unknown.
/// Unknown entries always sort to the end, regardless of sort direction,
/// instead of clumping at whichever end -1969-epoch/null comparisons
/// would otherwise push them to.
DateTime? releaseDateOf(VinylEntry v) {
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

/// Trie [list] en place (et la retourne aussi, par confort d'appel) selon
/// [sort], dans l'ordre [descending] ou croissant sinon. Les entrées sans
/// date de sortie connue (sort == releaseDate) sont toujours reléguées en
/// fin de liste, peu importe la direction du tri.
List<VinylEntry> sortVinyls(
  List<VinylEntry> list, {
  required CollectionSort sort,
  required bool descending,
}) {
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
        final da = releaseDateOf(a);
        final db = releaseDateOf(b);
        if (da == null && db == null) {
          cmp = 0;
        } else if (da == null) {
          cmp = 1;
        } else if (db == null) {
          cmp = -1;
        } else {
          cmp = da.compareTo(db);
        }
        break;
    }
    if (sort == CollectionSort.releaseDate &&
        (releaseDateOf(a) == null || releaseDateOf(b) == null)) {
      return cmp;
    }
    return descending ? -cmp : cmp;
  });

  return list;
}