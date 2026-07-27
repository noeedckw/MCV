import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/discogs_api.dart';
import '../storage/local_storage_service.dart';
import '../storage/vinyl_entry.dart';
import 'collection_provider.dart';
import '../utils/discogs_notes.dart';

class ExplorerProvider extends ChangeNotifier {
  final DiscogsApi discogsApi;
  final LocalStorageService storage;
  final CollectionProvider collectionProvider;

  ExplorerProvider(this.discogsApi, this.storage, this.collectionProvider);

  List<dynamic> results = [];
  bool isLoading = false;
  String? errorMessage;

  String? lastQuery;

  // Versions disponibles pour le master actuellement ouvert (détail au clic
  // sur une card). Séparé de `results` car ce n'est pas une liste de
  // résultats de recherche mais les pressages d'un seul master.
  List<dynamic> masterVersions = [];
  bool isLoadingVersions = false;
  String? versionsErrorMessage;
  int? currentMasterId;

  // Incrémenté à chaque nouvelle recherche. Sert à identifier la requête
  // "courante" : si un appel async se termine alors que _requestId a déjà
  // changé (une recherche plus récente a démarré, ou l'utilisateur a vidé
  // le champ), son résultat est ignoré. Ça règle à la fois la concurrence
  // (pas de résultat obsolète qui écrase un résultat plus récent) et évite
  // de manipuler un Completer/Future à annuler manuellement.
  int _requestId = 0;

  // Même logique que _requestId, mais dédiée aux appels de versions de
  // master, pour ne pas interférer avec la recherche principale.
  int _versionsRequestId = 0;

  Map<String, dynamic>? masterDetail;
  bool isLoadingDetail = false;
  String? detailErrorMessage;
  int _detailRequestId = 0;

  // Vrai pendant que la modal de détail d'un album est affichée (ouverture
  // -> fermeture, animation de sortie comprise). Regardé par ExplorerScreen
  // et MainNavigationScreen pour cacher la search bar et la navbar tant
  // qu'elle est ouverte.
  bool _isDetailModalOpen = false;
  bool get isDetailModalOpen => _isDetailModalOpen;

  void setDetailModalOpen(bool value) {
    if (_isDetailModalOpen == value) return;
    _isDetailModalOpen = value;
    notifyListeners();
  }

  Future<void> loadMasterDetail(int masterId) async {
    final requestId = ++_detailRequestId;

    isLoadingDetail = true;
    detailErrorMessage = null;
    masterDetail = null;
    notifyListeners();

    try {
      final detail = await discogsApi.getMasterDetails(masterId);

      if (requestId != _detailRequestId) return;

      masterDetail = detail;
      isLoadingDetail = false;
      notifyListeners();
    } catch (e) {
      if (requestId != _detailRequestId) return;

      detailErrorMessage = e.toString();
      isLoadingDetail = false;
      notifyListeners();
    }
  }

  /// Toggle collection : ajoute si absent, retire si déjà présent.
  /// selectedVersion est passé séparément (plutôt que déjà fourré dans
  /// `result['selected_version']`) pour que la modal n'ait qu'un seul
  /// point d'appel, que l'utilisateur ait choisi une édition ou non.
  ///
  /// `discogsId` utilisé pour ajouter/retirer est toujours celui du MASTER
  /// (result['id']), jamais celui de l'édition choisie : c'est la clé
  /// stable qui répond à "cet album est-il déjà dans ma collection ?",
  /// indépendamment du pressage. Le pressage lui-même est du métadata
  /// (releaseId/releaseCountry/releaseDate sur le VinylEntry), pas la clé
  /// de dédup — sinon rouvrir la modale après avoir ajouté une édition
  /// précise affichait à nouveau "Add to Collection" au lieu de "In
  /// Collection", puisque checkCollectionStatus vérifie par masterId.
  Future<void> toggleCollection(
    Map<String, dynamic> result,
    Map? selectedVersion,
  ) async {
    final masterId = result['id'] as int;
    final releaseId = selectedVersion?['id'] as int?;

    if (isInCollection) {
      await storage.deleteVinylByDiscogsId(masterId, releaseId: releaseId);
      isInCollection = false;
      notifyListeners();
      await collectionProvider.reload();
      return;
    }

    final payload = <String, dynamic>{
      ...result,
      'selected_version': selectedVersion,
    };
    await addToCollection(payload);
  }

  void clearMasterDetail() {
    masterDetail = null;
    isLoadingDetail = false;
    detailErrorMessage = null;
    isInCollection = false;
    isInWantlist = false;
    _statusCheckedForToken = null;
    clearMasterVersions();
    clearReleaseDetail();
  }

  Future<void> search(String query) async {
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      // Invalide toute requête en cours : son résultat, s'il arrive plus
      // tard, sera ignoré grâce au check requestId ci-dessous.
      _requestId++;
      lastQuery = '';
      results = [];
      isLoading = false;
      errorMessage = null;
      notifyListeners();
      return;
    }

    // Recherche strictement identique à la précédente, déjà résolue sans
    // erreur : inutile de relancer quoi que ce soit (le cache de DiscogsApi
    // s'en chargerait de toute façon, mais ça évite même de renotifier les
    // listeners pour rien). Un état d'erreur, en revanche, autorise un
    // nouvel essai sur la même requête (retry).
    if (trimmed == lastQuery && !isLoading && errorMessage == null) {
      return;
    }

    final requestId = ++_requestId;

    lastQuery = trimmed;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final searchResults = await discogsApi.search(trimmed);

      // Une recherche plus récente a démarré entre-temps : on jette ce
      // résultat obsolète sans toucher à l'état actuel.
      if (requestId != _requestId) return;

      results = searchResults;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      if (requestId != _requestId) return;

      errorMessage = e.toString();
      results = [];
      isLoading = false;
      notifyListeners();
    }
  }

  /// Identique à search(), mais interroge uniquement les masters (un master
  /// = un album, indépendamment de ses pressages). Utilise le même
  /// mécanisme de _requestId pour éviter qu'une recherche obsolète écrase
  /// un résultat plus récent.
  Future<void> searchMasters(String query) async {
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      _requestId++;
      lastQuery = '';
      results = [];
      isLoading = false;
      errorMessage = null;
      notifyListeners();
      return;
    }

    if (trimmed == lastQuery && !isLoading && errorMessage == null) {
      return;
    }

    final requestId = ++_requestId;

    lastQuery = trimmed;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final searchResults = await discogsApi.searchMasters(trimmed);

      if (requestId != _requestId) return;

      results = searchResults;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      if (requestId != _requestId) return;

      errorMessage = e.toString();
      results = [];
      isLoading = false;
      notifyListeners();
    }
  }

  /// À appeler quand l'utilisateur clique sur une card issue de
  /// searchMasters() — récupère les pressages/versions disponibles pour ce
  /// master précis.
  Future<void> loadMasterVersions(int masterId) async {
    final requestId = ++_versionsRequestId;

    currentMasterId = masterId;
    isLoadingVersions = true;
    versionsErrorMessage = null;
    masterVersions = [];
    notifyListeners();

    try {
      final versions = await discogsApi.getMasterVersions(masterId);

      if (requestId != _versionsRequestId) return;

      masterVersions = versions;
      isLoadingVersions = false;
      notifyListeners();
    } catch (e) {
      if (requestId != _versionsRequestId) return;

      versionsErrorMessage = e.toString();
      masterVersions = [];
      isLoadingVersions = false;
      notifyListeners();
    }
  }

  /// Réinitialise l'état des versions (ex: à la fermeture de l'écran détail).
  void clearMasterVersions() {
    currentMasterId = null;
    masterVersions = [];
    isLoadingVersions = false;
    versionsErrorMessage = null;
    notifyListeners();
  }

  List<TrackInfo>? _extractTracklist(List? raw) {
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
  List<TrackInfo>? _tracklistForEntry(Map? selectedVersion) {
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
  String? _labelForEntry(Map<String, dynamic> result, Map? selectedVersion) {
    final releaseLabels = releaseDetail?['labels'] as List?;
    print('DEBUG label — releaseLabels: $releaseLabels');
    print(
      'DEBUG label — result["label"]: ${result['label']} (type: ${result['label'].runtimeType})',
    );
    print('DEBUG label — selectedVersion: $selectedVersion');

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

  /// Toujours privilégier la plus haute résolution disponible pour l'image
  /// enregistrée en local : l'image du release précis (si édition
  /// sélectionnée et son detail chargé), sinon celle du master, sinon le
  /// cover_image du résultat de recherche. Ne JAMAIS utiliser
  /// `selectedVersion['thumb']` pour l'enregistrement — ce n'est qu'une
  /// miniature basse résolution destinée à la liste des éditions dans la
  /// modal, pas à un usage plein cadre dans la collection.
  String? _coverUrlForEntry(Map<String, dynamic> result) {
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

  /// Construit un VinylEntry à partir d'un résultat de recherche/master +
  /// une édition optionnellement sélectionnée dans la modal. Utilisé pour la
  /// collection ET la wantlist, pour que les deux stockent exactement les
  /// mêmes infos (format/label/genres/styles/tracklist/notes/édition) et que
  /// cliquer sur une entrée affiche toujours tout, peu importe la liste.
  VinylEntry _buildVinylEntry(
    Map<String, dynamic> result,
    Map? selectedVersion,
  ) {
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

    final label = _labelForEntry(result, selectedVersion);

    return VinylEntry(
      discogsId: result['id'] as int,
      artist: artist,
      title: albumTitle,
      year: year,
      format: format,
      label: label,
      releaseId: releaseId,
      releaseCountry: releaseCountry,
      releaseDate: releaseDate,
      genres: (masterDetail?['genres'] as List?)?.cast<String>(),
      styles: (masterDetail?['styles'] as List?)?.cast<String>(),
      tracklist: _tracklistForEntry(selectedVersion),
      notes: cleanDiscogsNotes(masterDetail?['notes'] as String?),
    );
  }

  // --- Ajouts dans ExplorerProvider ---

  bool isInCollection = false;
  bool isInWantlist = false;

  String? _statusCheckedForToken; // remplace int? _statusCheckedForId

  Future<void> checkCollectionStatus(
    int masterId, {
    Map? selectedVersion,
  }) async {
    final releaseId = selectedVersion?['id'] as int?;
    final token = '$masterId-${releaseId ?? 'generic'}';
    _statusCheckedForToken = token;

    final inCollection = await storage.vinylExistsByDiscogsId(
      masterId,
      releaseId: releaseId,
    );
    final inWantlist = await storage.wantlistExistsByDiscogsId(
      masterId,
      releaseId: releaseId,
    );

    // Si l'utilisateur a changé d'édition (ou fermé la modal) entre-temps,
    // ce résultat est obsolète.
    if (_statusCheckedForToken != token) return;

    isInCollection = inCollection;
    isInWantlist = inWantlist;
    notifyListeners();
  }

  /// Ajoute ou retire de la wantlist le master actuellement affiché dans la
  /// modal (toggle). Peut désormais porter sur une édition précise
  /// (selectedVersion), exactement comme la collection - même mécanique,
  /// mêmes champs stockés (label/genres/styles/releaseId/...), pour que
  /// cliquer sur une entrée wantlist ou collection affiche toujours les
  /// mêmes infos. Le dédoublonnage reste indexé par masterId (jamais par
  /// releaseId) : un même album ne peut être qu'une seule fois dans la
  /// wantlist, quelle que soit l'édition visée.
  Future<void> toggleWantlist(
    Map<String, dynamic> result,
    Map? selectedVersion,
  ) async {
    final discogsId = result['id'] as int;
    final releaseId = selectedVersion?['id'] as int?;

    if (isInWantlist) {
      await storage.removeWantlistByDiscogsId(discogsId, releaseId: releaseId);
      isInWantlist = false;
      notifyListeners();
      await collectionProvider.reload();
      return;
    }

    final entry = _buildVinylEntry(result, selectedVersion);

    final coverUrl = _coverUrlForEntry(result);

    var coverBytes;
    if (coverUrl != null && coverUrl.isNotEmpty) {
      final resp = await http.get(Uri.parse(coverUrl));
      if (resp.statusCode == 200) coverBytes = resp.bodyBytes;
    }

    await storage.insertWantlist(entry, coverImageBytes: coverBytes);

    isInWantlist = true;
    await collectionProvider.reload();
    notifyListeners();
  }

  Map<String, dynamic>? releaseDetail;
  bool isLoadingRelease = false;
  String? releaseErrorMessage;
  int _releaseRequestId = 0;

  /// Appelé quand l'utilisateur choisit une édition précise dans la modal.
  /// Récupère le détail du release exact (tracklist, notes, etc. peuvent
  /// différer du master — cas des rééditions deluxe).
  Future<void> loadReleaseDetail(int releaseId) async {
    final requestId = ++_releaseRequestId;

    isLoadingRelease = true;
    releaseErrorMessage = null;
    notifyListeners();

    try {
      final detail = await discogsApi.getReleaseDetails(releaseId);

      if (requestId != _releaseRequestId) return;

      releaseDetail = detail;
      isLoadingRelease = false;
      notifyListeners();
    } catch (e) {
      if (requestId != _releaseRequestId) return;

      releaseErrorMessage = e.toString();
      isLoadingRelease = false;
      notifyListeners();
    }
  }

  /// Revient à la tracklist du master (l'utilisateur repasse sur "Master"
  /// ou ferme la modal).
  void clearReleaseDetail() {
    _releaseRequestId++; // invalide toute requête en vol
    releaseDetail = null;
    isLoadingRelease = false;
    releaseErrorMessage = null;
    notifyListeners();
  }

  Future<void> addToCollection(Map<String, dynamic> result) async {
    final selectedVersion = result['selected_version'] as Map?;
    final masterId = result['id'] as int;
    final releaseId = selectedVersion?['id'] as int?;

    if (await storage.vinylExistsByDiscogsId(masterId, releaseId: releaseId)) {
      isInCollection = true;
      notifyListeners();
      return;
    }

    final entry = _buildVinylEntry(result, selectedVersion);

    final coverUrl = _coverUrlForEntry(result);

    var coverBytes;
    if (coverUrl != null && coverUrl.isNotEmpty) {
      final resp = await http.get(Uri.parse(coverUrl));
      if (resp.statusCode == 200) coverBytes = resp.bodyBytes;
    }

    await storage.insertVinyl(entry, coverImageBytes: coverBytes);

    if (isInWantlist) {
      await storage.removeWantlistByDiscogsId(masterId, releaseId: releaseId);
      isInWantlist = false;
    }

    isInCollection = true;
    notifyListeners();
    await collectionProvider.reload();
  }
}
