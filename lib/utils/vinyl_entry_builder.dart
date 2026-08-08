import '../storage/vinyl_entry.dart';
import 'discogs_notes.dart';

/// Construit un [VinylEntry] à partir d'un résultat de recherche/master
/// Discogs, avec (éventuellement) le détail du master et/ou d'une édition
/// précise déjà chargés.
///
/// Extrait de ExplorerProvider : c'est une pure transformation de données
/// (aucun état, aucun appel réseau, aucun notifyListeners), donc elle vit
/// ici plutôt que dans le provider — plus facile à tester isolément, et
/// le provider n'a plus à porter cette logique.
class VinylEntryBuilder {
  const VinylEntryBuilder._();

  /// [result] : le résultat de recherche/master brut (Discogs).
  /// [selectedVersion] : l'édition précise choisie dans la modal, si une a
  /// été sélectionnée.
  /// [masterDetail] : le détail du master déjà chargé (tracklist/genres/
  /// styles/notes par défaut).
  /// [releaseDetail] : le détail de l'édition précise déjà chargé, s'il y
  /// en a un — prioritaire sur masterDetail pour label/tracklist.
  static VinylEntry build({
    required Map<String, dynamic> result,
    required Map? selectedVersion,
    required Map<String, dynamic>? masterDetail,
    required Map<String, dynamic>? releaseDetail,
  }) {
    final title = result['title'] as String? ?? '';
    final parts = title.split(' - ');
    final artist = parts.isNotEmpty ? parts[0] : 'Inconnu';
    final albumTitle = parts.length > 1 ? parts.sublist(1).join(' - ') : title;

    final releaseId = selectedVersion != null
        ? selectedVersion['id'] as int?
        : null;
    final releaseCountry = selectedVersion != null
        ? selectedVersion['country'] as String?
        : null;
    final releaseDate = selectedVersion != null
        ? selectedVersion['released'] as String?
        : null;

    final rawYear = releaseDate ?? result['year']?.toString();
    final year = int.tryParse((rawYear ?? '').split('-').first);

    final format = selectedVersion != null
        ? selectedVersion['format'] as String?
        : (result['format'] as List?)?.join(', ');

    return VinylEntry(
      discogsId: result['id'] as int,
      artist: artist,
      title: albumTitle,
      year: year,
      format: format,
      label: _labelFor(result, releaseDetail),
      releaseId: releaseId,
      releaseCountry: releaseCountry,
      releaseDate: releaseDate,
      genres: (masterDetail?['genres'] as List?)?.cast<String>(),
      styles: (masterDetail?['styles'] as List?)?.cast<String>(),
      tracklist: _tracklistFor(selectedVersion, masterDetail, releaseDetail),
      notes: cleanDiscogsNotes(masterDetail?['notes'] as String?),
    );
  }

  /// Toujours privilégier la plus haute résolution disponible pour l'image
  /// enregistrée en local : l'image du release précis (si édition
  /// sélectionnée et son detail chargé), sinon celle du master, sinon le
  /// cover_image du résultat de recherche. Ne JAMAIS utiliser
  /// `selectedVersion['thumb']` pour l'enregistrement — ce n'est qu'une
  /// miniature basse résolution destinée à la liste des éditions dans la
  /// modal, pas à un usage plein cadre dans la collection.
  static String? coverUrlFor({
    required Map<String, dynamic> result,
    required Map<String, dynamic>? masterDetail,
    required Map<String, dynamic>? releaseDetail,
  }) {
    final releaseImages = releaseDetail?['images'] as List?;
    if (releaseImages != null && releaseImages.isNotEmpty) {
      final uri = releaseImages[0]['uri'] as String?;
      if (uri != null && uri.isNotEmpty) return uri;
    }

    final masterImages = masterDetail?['images'] as List?;
    if (masterImages != null && masterImages.isNotEmpty) {
      final uri = masterImages[0]['uri'] as String?;
      if (uri != null && uri.isNotEmpty) return uri;
    }

    return result['cover_image'] as String?;
  }

  static List<TrackInfo>? _extractTracklist(List? raw) {
    if (raw == null || raw.isEmpty) return null;
    return raw.map((t) {
      final track = t as Map;
      return TrackInfo(
        position: track['position'] as String? ?? '',
        title: track['title'] as String? ?? '',
        duration: track['duration'] as String? ?? '',
      );
    }).toList();
  }

  /// La tracklist à sauvegarder : celle de l'édition précise si une a été
  /// choisie et que releaseDetail a fini de charger, sinon celle du master
  /// en repli (ex: l'utilisateur ajoute juste après avoir changé d'édition,
  /// avant que le fetch de releaseDetail ait fini — mieux vaut sauvegarder
  /// la tracklist du master que rien du tout).
  static List<TrackInfo>? _tracklistFor(
    Map? selectedVersion,
    Map<String, dynamic>? masterDetail,
    Map<String, dynamic>? releaseDetail,
  ) {
    final raw = selectedVersion != null
        ? (releaseDetail?['tracklist'] as List? ??
              masterDetail?['tracklist'] as List?)
        : masterDetail?['tracklist'] as List?;
    return _extractTracklist(raw);
  }

  /// Discogs n'expose `labels` (le vrai label de musique / maison de
  /// disque, ex: Columbia, Motown...) qu'au niveau RELEASE, jamais au
  /// niveau master — ça n'a pas de sens là, puisque le label peut varier
  /// d'une édition à l'autre. On privilégie donc :
  /// 1. Le label de l'édition précise sélectionnée (releaseDetail), si son
  ///    detail a fini de charger.
  /// 2. Sinon, le label déjà présent dans le résultat de recherche
  ///    (`result['label']`) — celui-là même utilisé par ResultCard/LargeCard
  ///    sur les cards de résultats, souvent une List<String>.
  static String? _labelFor(
    Map<String, dynamic> result,
    Map<String, dynamic>? releaseDetail,
  ) {
    final releaseLabels = releaseDetail?['labels'] as List?;

    if (releaseLabels != null && releaseLabels.isNotEmpty) {
      final name = releaseLabels.first['name'] as String?;
      if (name != null && name.isNotEmpty) return name;
    }

    final searchLabel = result['label'];
    if (searchLabel is List && searchLabel.isNotEmpty) {
      return searchLabel.cast<String>().join(' • ');
    }
    if (searchLabel is String && searchLabel.isNotEmpty) return searchLabel;

    return null;
  }
}