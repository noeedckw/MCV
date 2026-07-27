import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/explorer_provider.dart';
import 'genre_accent.dart';
import 'vinyl_scroll_band.dart';

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

  late final String _featuredImage;

  bool _isLoading = true;
  bool _showBands = false;

  String? _error;

  List<String> _bandTop = [];
  List<String> _bandBottom = [];

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

    _featuredImage =
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
      _loadShowcase();
    }
  }

  Future<void> _loadShowcase() async {
    final loadId = ++_loadId;

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final discogsApi = context.read<ExplorerProvider>().discogsApi;

      // Le cache de DiscogsApi garantit qu'un genre déjà recherché ne
      // redéclenche pas d'appel réseau, même si ce widget est reconstruit
      // avec le même genre (ex: retour sur l'écran).
      final results = await discogsApi.search(widget.genreAccent.genre);

      if (!mounted || loadId != _loadId) return;

      final covers = <String>{
        for (final r in results)
          if (r is Map &&
              (r['cover_image'] as String?)?.isNotEmpty == true)
            r['cover_image'] as String,
      }.toList()
        ..shuffle(Random());

      if (covers.isEmpty) {
        if (!mounted || loadId != _loadId) return;

        setState(() {
          _isLoading = false;
          _bandTop = [];
          _bandBottom = [];
        });
        return;
      }

      final splitIndex = covers.length ~/ 2;

      if (!mounted || loadId != _loadId) return;

      setState(() {
        _bandTop = covers.sublist(0, splitIndex);
        _bandBottom = covers.sublist(splitIndex);

        _isLoading = false;

        if (!widget.focusNode.hasFocus &&
            widget.controller.text.trim().isEmpty) {
          _showBands = true;
        }
      });
    } catch (e) {
      if (!mounted || loadId != _loadId) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    final topPadding = screenHeight * 0.15;
    final gap1 = screenHeight * 0.04;
    final gap2 = screenHeight * 0.045;
    final bottomPadding = screenHeight * 0.03;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: widget.genreAccent.color,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          "Impossible de charger les vinyles",
          style: TextStyle(
            color: Colors.white.withValues(alpha: .6),
          ),
        ),
      );
    }

    final accent = widget.genreAccent.color;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        0,
        topPadding,
        0,
        bottomPadding,
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _animatedBand(
              VinylScrollBand(
                coverUrls: _bandTop,
                itemSize: 95,
                spacing: 10,
                speed: 40,
                direction: BandDirection.toRight,
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
                    filter: ImageFilter.blur(
                      sigmaX: 16,
                      sigmaY: 16,
                    ),
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
                                  "Find vinyls to grow your collection.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
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
                coverUrls: _bandBottom,
                itemSize: 135,
                direction: BandDirection.toLeft,
                spacing: 15,
                speed: 35,
              ),
              _kBottomBandHeight,
            ),
          ],
        ),
      ),
    );
  }
}