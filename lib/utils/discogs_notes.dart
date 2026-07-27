/// Discogs notes often embed internal reference markup — [a=Artist],
/// [l=Label], [r=12345], [m=12345], [url=...]...[/url], bbcode tags like
/// [b]/[i], or raw URLs — none of which mean anything to an end user, and
/// half of them look broken once the site's own renderer isn't there to
/// turn them into a link. Rather than just stripping the brackets out
/// (which would leave mangled half-sentences behind, e.g. "preceded by the
/// singles ''"), this drops the ENTIRE line whenever it contains one of
/// these, then collapses whatever run of blank lines that leaves behind.
String? cleanDiscogsNotes(String? raw) {
  if (raw == null) return null;

  final referencePattern = RegExp(r'\[[a-zA-Z]{1,4}[=)][^\[\]]*\]');
  final bbcodeTagPattern = RegExp(r'\[/?[a-zA-Z]+\]');
  final urlPattern = RegExp(r'https?://\S+');

  final keptLines = raw.split('\n').where((line) {
    return !referencePattern.hasMatch(line) &&
        !bbcodeTagPattern.hasMatch(line) &&
        !urlPattern.hasMatch(line);
  });

  final result = <String>[];
  var lastWasBlank = false;
  for (final line in keptLines) {
    final isBlank = line.trim().isEmpty;
    if (isBlank && lastWasBlank) continue;
    result.add(line);
    lastWasBlank = isBlank;
  }
  while (result.isNotEmpty && result.first.trim().isEmpty) {
    result.removeAt(0);
  }
  while (result.isNotEmpty && result.last.trim().isEmpty) {
    result.removeLast();
  }

  final cleaned = result.join('\n').trim();
  return cleaned.isEmpty ? null : cleaned;
}
