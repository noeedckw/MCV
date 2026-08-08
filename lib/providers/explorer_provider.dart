import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/discogs_api.dart';
import '../storage/local_storage_service.dart';
import '../storage/vinyl_entry.dart';
import 'collection_provider.dart';
import '../utils/cover_url.dart';
import '../utils/vinyl_entry_builder.dart';

class ExplorerProvider extends ChangeNotifier {
  DiscogsApi? _discogsApi;
  final LocalStorageService storage;
  final CollectionProvider collectionProvider;

  ExplorerProvider(this.storage, this.collectionProvider);

  /// Appelé une fois l'utilisateur authentifié auprès de Discogs.
  /// Tant que ce n'est pas appelé, tout accès à `discogsApi` lève —
  /// mais _buildContent() ne construit MainNavigationScreen (donc
  /// n'utilise jamais ce provider) qu'une fois configure() déjà fait.
  void configure(DiscogsApi api) {
    _discogsApi = api;
    notifyListeners();
  }

  DiscogsApi get discogsApi {
    final api = _discogsApi;
    assert(api != null, 'ExplorerProvider.configure() doit être appelé avant usage');
    return api!;
  }

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

  void clearMasterDetail() {
    masterDetail = null;
    isLoadingDetail = false;
    detailErrorMessage = null;
    effectiveMasterId = null;
    isInCollection = false;
    isInWishlist = false;
    _statusCheckedForToken = null;
    clearMasterVersions();
    clearReleaseDetail();
  }

  // =====================================================================
  // RECHERCHE
  // =====================================================================

  List<dynamic> results = [];
  bool isLoading = false;
  String? errorMessage;
  String? lastQuery;

  // Incrémenté à chaque nouvelle recherche. Sert à identifier la requête
  // "courante" : si un appel async se termine alors que _requestId a déjà
  // changé (une recherche plus récente a démarré, ou l'utilisateur a vidé
  // le champ), son résultat est ignoré. Ça règle à la fois la concurrence
  // (pas de résultat obsolète qui écrase un résultat plus récent) et évite
  // de manipuler un Completer/Future à annuler manuellement.
  int _requestId = 0;

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

  // =====================================================================
  // DÉTAIL MASTER / RELEASE
  // =====================================================================

  // Versions disponibles pour le master actuellement ouvert (détail au clic
  // sur une card). Séparé de `results` car ce n'est pas une liste de
  // résultats de recherche mais les pressages d'un seul master.
  List<dynamic> masterVersions = [];
  bool isLoadingVersions = false;
  String? versionsErrorMessage;
  int? currentMasterId;

  // Même logique que _requestId, mais dédiée aux appels de versions de
  // master, pour ne pas interférer avec la recherche principale.
  int _versionsRequestId = 0;

  Map<String, dynamic>? masterDetail;
  bool isLoadingDetail = false;
  String? detailErrorMessage;
  int _detailRequestId = 0;

  /// Id "stable" à utiliser pour toute opération de collection/wishlist
  /// (add/remove/check) sur l'album actuellement ouvert dans la modal.
  ///
  /// Les résultats de recherche classique (`search()`, utilisés entre
  /// autres par le showcase à vinyles) peuvent être de type "master" OU
  /// "release" (Discogs distingue via `result['type']`) — contrairement à
  /// `searchMasters()` qui garantit toujours un master id. Une "release"
  /// pointe en général vers un master (`master_id` dans son détail) qui
  /// regroupe toutes ses éditions ; ce master_id est LA clé stable pour
  /// dédupliquer "cet album est déjà dans ma collection" indépendamment du
  /// pressage précis. `effectiveMasterId` est donc résolu une fois dans
  /// `loadDetailForResult` (master id direct, ou master_id extrait de la
  /// release, ou l'id de la release elle-même en dernier recours si elle
  /// n'a vraiment aucun master) puis réutilisé partout ailleurs — jamais
  /// `result['id']` brut, qui pourrait être un id de release non résolu.
  int? effectiveMasterId;

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

  /// Point d'entrée unique pour ouvrir la modal de détail depuis un
  /// résultat de recherche, qu'il soit de type "master" ou "release" —
  /// ne modifie ni loadMasterDetail ni loadMasterVersions : elle se
  /// contente de résoudre le bon masterId en amont puis délègue
  /// entièrement à ces méthodes existantes, pour un comportement identique
  /// (toutes les éditions listées) peu importe d'où vient le clic.
  ///
  /// Résout aussi `effectiveMasterId` et lance `checkCollectionStatus`
  /// dessus une fois connu — plus la peine d'appeler checkCollectionStatus
  /// séparément avec un id potentiellement pas encore résolu.
  Future<void> loadDetailForResult(Map<String, dynamic> result) async {
    final id = result['id'] as int;
    final isMaster = result['type'] == 'master';

    if (isMaster) {
      effectiveMasterId = id;
      await loadMasterDetail(id);
      await loadMasterVersions(id);
      checkCollectionStatus(id);
      return;
    }

    // C'est une release (ou un type inconnu/absent, traité comme tel par
    // prudence) : on la charge d'abord pour en extraire master_id, présent
    // dans la réponse /releases/{id} quand un master existe pour cet
    // album, puis on délègue aux méthodes master existantes.
    final requestId = ++_detailRequestId;

    isLoadingDetail = true;
    detailErrorMessage = null;
    masterDetail = null;
    effectiveMasterId = null;
    notifyListeners();

    try {
      final release = await discogsApi.getReleaseDetails(id);

      if (requestId != _detailRequestId) return;

      final masterId = release['master_id'] as int?;

      if (masterId != null) {
        effectiveMasterId = masterId;
        // Délégation complète : loadMasterDetail/loadMasterVersions gèrent
        // elles-mêmes leur propre requestId, loading state, etc.
        await loadMasterDetail(masterId);
        await loadMasterVersions(masterId);
        checkCollectionStatus(masterId);
      } else {
        // Pas de master pour cette release (pressage isolé) : on
        // l'affiche telle quelle, sans liste d'éditions, et on utilise
        // son propre id comme clé stable de collection à défaut de mieux.
        effectiveMasterId = id;
        masterDetail = release;
        isLoadingDetail = false;
        masterVersions = [];
        versionsErrorMessage = null;
        notifyListeners();
        checkCollectionStatus(id);
      }
    } catch (e) {
      if (requestId != _detailRequestId) return;

      detailErrorMessage = "Impossible de charger les détails de cet album.";
      isLoadingDetail = false;
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

  // =====================================================================
  // COLLECTION & WISHLIST
  // =====================================================================

  bool isInCollection = false;
  bool isInWishlist = false;

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
    final inWishlist = await storage.wishlistExistsByDiscogsId(
      masterId,
      releaseId: releaseId,
    );

    // Si l'utilisateur a changé d'édition (ou fermé la modal) entre-temps,
    // ce résultat est obsolète.
    if (_statusCheckedForToken != token) return;

    isInCollection = inCollection;
    isInWishlist = inWishlist;
    notifyListeners();
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
  ///
  /// IMPORTANT : `result['id']` doit déjà être l'id résolu
  /// (effectiveMasterId) — c'est la responsabilité de l'appelant (la modal)
  /// de le garantir, cette méthode ne re-résout rien elle-même.
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

  /// Ajoute ou retire de la wishlist le master actuellement affiché dans la
  /// modal (toggle). Peut désormais porter sur une édition précise
  /// (selectedVersion), exactement comme la collection - même mécanique,
  /// mêmes champs stockés (label/genres/styles/releaseId/...), pour que
  /// cliquer sur une entrée wishlist ou collection affiche toujours les
  /// mêmes infos. Le dédoublonnage reste indexé par masterId (jamais par
  /// releaseId) : un même album ne peut être qu'une seule fois dans la
  /// wishlist, quelle que soit l'édition visée.
  ///
  /// IMPORTANT : `result['id']` doit déjà être l'id résolu
  /// (effectiveMasterId) — c'est la responsabilité de l'appelant (la modal)
  /// de le garantir, cette méthode ne re-résout rien elle-même.
  Future<void> toggleWishlist(
    Map<String, dynamic> result,
    Map? selectedVersion,
  ) async {
    final discogsId = result['id'] as int;
    final releaseId = selectedVersion?['id'] as int?;

    if (isInWishlist) {
      await storage.removeWishlistByDiscogsId(discogsId, releaseId: releaseId);
      isInWishlist = false;
      notifyListeners();
      await collectionProvider.reload();
      return;
    }

    final entry = VinylEntryBuilder.build(
      result: result,
      selectedVersion: selectedVersion,
      masterDetail: masterDetail,
      releaseDetail: releaseDetail,
    );

    final coverUrl = VinylEntryBuilder.coverUrlFor(
      result: result,
      masterDetail: masterDetail,
      releaseDetail: releaseDetail,
    );

    Uint8List? coverBytes;
    if (coverUrl != null && coverUrl.isNotEmpty) {
      final resp = await http.get(Uri.parse(resolveCoverUrl(coverUrl)!));
      if (resp.statusCode == 200) coverBytes = resp.bodyBytes;
    }

    await storage.insertWishlist(entry, coverImageBytes: coverBytes);

    isInWishlist = true;
    await collectionProvider.reload();
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

    final entry = VinylEntryBuilder.build(
      result: result,
      selectedVersion: selectedVersion,
      masterDetail: masterDetail,
      releaseDetail: releaseDetail,
    );

    final coverUrl = VinylEntryBuilder.coverUrlFor(
      result: result,
      masterDetail: masterDetail,
      releaseDetail: releaseDetail,
    );

    var coverBytes;
    if (coverUrl != null && coverUrl.isNotEmpty) {
      final resp = await http.get(Uri.parse(resolveCoverUrl(coverUrl)!));
      if (resp.statusCode == 200) coverBytes = resp.bodyBytes;
    }

    await storage.insertVinyl(entry, coverImageBytes: coverBytes);

    if (isInWishlist) {
      await storage.removeWishlistByDiscogsId(masterId, releaseId: releaseId);
      isInWishlist = false;
    }

    isInCollection = true;
    notifyListeners();
    await collectionProvider.reload();
  }
}