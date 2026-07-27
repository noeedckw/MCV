// lib/utils/artist_name.dart

/// Strips Discogs' disambiguation suffix from an artist name, e.g.
/// "Boards of Canada (2)" -> "Boards of Canada", or mid-string on
/// collabs: "Future (4) & Metro Boomin" -> "Future & Metro Boomin".
/// Discogs appends this "(N)" number whenever several artists share
/// the same name — it's internal bookkeeping, never meant to be shown.
String cleanArtistName(String raw) {
  return raw
      .replaceAll(RegExp(r'\s*\(\d+\)'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}