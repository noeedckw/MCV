import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/explorer_provider.dart';
import 'album_detail_modal.dart';
import 'genre_accent.dart';
import 'vinyl_scroll_band.dart';
import '../../utils/cover_url.dart';

class ExplorerVinylShowcase extends StatefulWidget {
  final GenreAccent genreAccent;
  final FocusNode focusNode;
  final TextEditingController controller;

  const ExplorerVinylShowcase({
    super.key,
    required this.genreAccent,
    required this.focusNode,
    required this.controller,
  });

  @override
  State<ExplorerVinylShowcase> createState() => _ExplorerVinylShowcaseState();
}

class _ExplorerVinylShowcaseState extends State<ExplorerVinylShowcase> {
  static const List<String> _kFeaturedImages = [
    'assets/images/searching_vinyl_1.png',
    'assets/images/searching_vinyl_2.png',
    'assets/images/searching_vinyl_3.png',
    'assets/images/searching_vinyl_4.png',
  ];

  static const double _kTopBandHeight = 95;
  static const double _kBottomBandHeight = 135;

  static const Duration _kSizeDuration = Duration(milliseconds: 400);

  static String? _cachedFeaturedImage;

  late final String _featuredImage;

  bool _showBands = false;

  String? _error;

  List<Map<String, dynamic>> _bandTop = [];
  List<Map<String, dynamic>> _bandBottom = [];

  // Identifie le chargement "courant". Incrémenté à chaque appel de
  // _loadShowcase(). Si un chargement se termine alors que _loadId a déjà
  // changé (widget disposé, ou genre modifié entre-temps via
  // didUpdateWidget), son résultat est ignoré : ça règle à la fois le crash
  // "setState() called after dispose()" et l'écrasement de l'état par une
  // réponse obsolète (genre A qui répond après genre B).
  int _loadId = 0;

  @override
  void initState() {
    super.initState();

    _featuredImage = _cachedFeaturedImage ??=
        _kFeaturedImages[Random().nextInt(_kFeaturedImages.length)];

    widget.focusNode.addListener(_onFocusChanged);

    _loadShowcase();
  }

  void _onFocusChanged() {
    if (!mounted) return;

    if (widget.focusNode.hasFocus) {
      setState(() {
        _showBands = false;
      });
    } else {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted || widget.focusNode.hasFocus) return;

        if (widget.controller.text.trim().isNotEmpty) return;

        setState(() {
          _showBands = true;
        });
      });
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    // Invalide tout chargement en cours : s'il se termine après ce point,
    // le check `loadId != _loadId` dans _loadShowcase() le neutralisera.
    _loadId++;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ExplorerVinylShowcase oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.genreAccent.genre != widget.genreAccent.genre) {
      // On repart d'un état "pas encore de bandes" pour ce nouveau genre —
      // sinon les anciennes covers resteraient affichées pendant le fetch.
      _showBands = false;
      _loadShowcase();
    }
  }

  /// Tente de charger réellement l'image (fetch + decode via precacheImage,
  /// donc elle finit dans l'ImageCache si ça réussit — VinylScrollBand
  /// l'affichera donc instantanément, sans refetch). Retry avec backoff
  /// avant d'abandonner.
  ///
  /// IMPORTANT : precacheImage() ne fait PAS échouer son Future en cas
  /// d'erreur réseau/décodage — elle complète "normalement" et envoie
  /// l'exception à FlutterError.onError, sauf si on lui passe un callback
  /// onError explicite. Un simple try/catch autour de l'await ne détecte
  /// donc rien : il faut piloter l'échec via ce callback.
  ///
  /// IMPORTANT #2 : precacheImage() n'a AUCUN timeout intégré. Sans borne
  /// de temps, une seule requête réseau lente (typiquement juste après le
  /// lancement de l'app, connexion pas encore stabilisée) peut rester en
  /// attente indéfiniment — et comme _loadShowcase() attend TOUTES les
  /// covers via Future.wait, ça bloque l'écran entier en chargement pour
  /// toujours. D'où le `.timeout(...)` ci-dessous : une image trop lente
  /// est traitée comme un échec normal (→ retry, puis exclusion), jamais
  /// comme un blocage.
  static const Duration _kImageTimeout = Duration(seconds: 6);

  Future<bool> _isImageLoadable(String url, {int maxAttempts = 3}) async {
    final resolved = resolveCoverUrl(url);
    if (resolved == null) return false;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (!mounted) return false;

      var failed = false;
      try {
        await precacheImage(
          NetworkImage(resolved),
          context,
          onError: (exception, stackTrace) {
            // Callback fiable, contrairement au Future qui se complète
            // "avec succès" même quand l'image n'a pas pu être chargée.
            failed = true;
          },
        ).timeout(
          _kImageTimeout,
          onTimeout: () {
            // Requête trop lente : on la traite comme un échec plutôt
            // que de laisser Future.wait attendre indéfiniment.
            failed = true;
          },
        );
      } catch (_) {
        // Filet de sécurité pour une exception synchrone éventuelle
        // (ex: provider mal formé).
        failed = true;
      }

      if (!failed) return true;

      if (attempt < maxAttempts - 1) {
        await Future.delayed(Duration(milliseconds: 400 * (attempt + 1)));
      }
    }
    return false;
  }

  Future<void> _loadShowcase() async {
    final loadId = ++_loadId;

    if (!mounted) return;

    setState(() {
      _error = null;
    });

    try {
      final discogsApi = context.read<ExplorerProvider>().discogsApi;

      // Le cache de DiscogsApi garantit qu'un genre déjà recherché ne
      // redéclenche pas d'appel réseau, même si ce widget est reconstruit
      // avec le même genre (ex: retour sur l'écran).
      final results = await discogsApi.searchByAccent(widget.genreAccent);

      if (!mounted || loadId != _loadId) return;

      // On garde le Map complet (pas juste l'URL) afin de pouvoir ouvrir
      // le modal de détail au tap sur une cover.
      final seenUrls = <String>{};
      final covers = <Map<String, dynamic>>[
        for (final r in results)
          if (r is Map &&
              (r['cover_image'] as String?)?.isNotEmpty == true &&
              !(r['cover_image'] as String)
                  .toLowerCase()
                  .contains('spacer.gif') &&
              seenUrls.add(r['cover_image'] as String))
            r.cast<String, dynamic>(),
      ]..shuffle(Random());

      if (covers.isEmpty) {
        if (!mounted || loadId != _loadId) return;

        setState(() {
          _bandTop = [];
          _bandBottom = [];
        });
        return;
      }

      // Vérifie en parallèle que chaque cover charge vraiment (avec
      // retry), et ne garde que celles qui passent — les échecs restants
      // (rate-limit persistant, URL cassée côté Discogs, etc.) sont
      // simplement exclues de la bande plutôt que d'afficher un carré gris.
      final validityChecks = await Future.wait(
        covers.map((r) => _isImageLoadable(r['cover_image'] as String)),
      );

      if (!mounted || loadId != _loadId) return;

      final validCovers = [
        for (var i = 0; i < covers.length; i++)
          if (validityChecks[i]) covers[i],
      ];

      if (validCovers.isEmpty) {
        setState(() {
          _bandTop = [];
          _bandBottom = [];
        });
        return;
      }

      final splitIndex = validCovers.length ~/ 2;

      setState(() {
        _bandTop = validCovers.sublist(0, splitIndex);
        _bandBottom = validCovers.sublist(splitIndex);


        if (!widget.focusNode.hasFocus &&
            widget.controller.text.trim().isEmpty) {
          _showBands = true;
        }
      });
    } catch (e) {
      if (!mounted || loadId != _loadId) return;

      setState(() {
        _error = e.toString();
      });
    }
  }

  Widget _animatedBand(Widget child, double height) {
    return ClipRect(
      child: AnimatedContainer(
        duration: _kSizeDuration,
        curve: Curves.easeInOut,
        height: _showBands ? height : 0,
        child: OverflowBox(
          maxHeight: height,
          alignment: Alignment.center,
          child: AnimatedOpacity(
            opacity: _showBands ? 1 : 0,
            duration: _showBands
                ? const Duration(milliseconds: 800)
                : const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: child,
          ),
        ),
      ),
    );
  }

  void _openAlbumDetail(Map<String, dynamic> item) {
    showAlbumDetailModal(context, result: item);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    final topPadding = screenHeight * 0.15;
    final gap1 = screenHeight * 0.04;
    final gap2 = screenHeight * 0.045;
    final bottomPadding = screenHeight * 0.03;

    final accent = widget.genreAccent.color;

    return Padding(
      padding: EdgeInsets.fromLTRB(0, topPadding, 0, bottomPadding),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // La bande du haut reste pilotée par _showBands (collapse à 0
            // tant que le chargement n'est pas fini) — mais elle n'empêche
            // plus jamais la carte ci-dessous de s'afficher.
            _animatedBand(
              VinylScrollBand(
                items: _bandTop,
                itemSize: 95,
                spacing: 10,
                speed: 40,
                direction: BandDirection.toRight,
                onTapItem: _openAlbumDetail,
              ),
              _kTopBandHeight,
            ),
            SizedBox(height: gap1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: accent.withValues(alpha: .3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: .18),
                      blurRadius: 10,
                      spreadRadius: 6,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: Colors.black,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.asset(
                              _featuredImage,
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Column(
                              children: [
                                const Text(
                                  "Discover",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _error != null
                                      ? "Certains vinyles n'ont pas pu être chargés."
                                      : "Find vinyls to grow your collection.",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 13,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: gap2),
            _animatedBand(
              VinylScrollBand(
                items: _bandBottom,
                itemSize: 135,
                direction: BandDirection.toLeft,
                spacing: 15,
                speed: 35,
                onTapItem: _openAlbumDetail,
              ),
              _kBottomBandHeight,
            ),
          ],
        ),
      ),
    );
  }
}