import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../storage/grid_columns_store.dart';
import 'cards/result_card.dart';
import 'page_nav.dart';

class GridFormatStyle {
  final double textContainerHeight;
  final double spacingH;
  final double spacingV;
  final double titleFontSize;
  final double subtitleFontSize;
  final double metaFontSize;
  final double yearFontSize;
  final EdgeInsets textPadding;
  final double horizontalPadding;
  final double? maxGridWidth;

  const GridFormatStyle({
    required this.textContainerHeight,
    required this.spacingH,
    required this.spacingV,
    required this.titleFontSize,
    required this.subtitleFontSize,
    required this.metaFontSize,
    required this.yearFontSize,
    required this.textPadding,
    required this.horizontalPadding,
    this.maxGridWidth,
  });
}

class ExplorerResultsGrid extends StatefulWidget {
  final List<dynamic> results;
  final ScrollController scrollController;
  final ValueChanged<Map>? onTapResult;

  const ExplorerResultsGrid({
    super.key,
    required this.results,
    required this.scrollController,
    this.onTapResult,
  });

  @override
  State<ExplorerResultsGrid> createState() => _ExplorerResultsGridState();
}

class _ExplorerResultsGridState extends State<ExplorerResultsGrid> {
  static const int _minColumns = 1;
  static const int _maxColumns = 4;
  static const int _defaultColumns = 2;
  static const int _itemsPerPage = 40;

  late int _crossAxisCount;
  late int _baseCrossAxisCount;
  int _currentPage = 0;

  int get _pageCount => widget.results.isEmpty
      ? 1
      : (widget.results.length / _itemsPerPage).ceil();

  List<dynamic> get _currentPageItems {
    final start = _currentPage * _itemsPerPage;
    if (start >= widget.results.length) return const [];
    final end = (start + _itemsPerPage).clamp(0, widget.results.length).toInt();
    return widget.results.sublist(start, end);
  }

  @override
  void initState() {
    super.initState();
    // Lecture SYNCHRONE du cache — dispo immédiatement, même si ce State
    // vient d'être recréé après une recherche vide. Plus de flash.
    final saved = GridColumnsStore.get('explorer');
    final initial = (saved != null && saved >= _minColumns && saved <= _maxColumns)
        ? saved
        : _defaultColumns;
    _crossAxisCount = initial;
    _baseCrossAxisCount = initial;
  }

  @override
  void didUpdateWidget(covariant ExplorerResultsGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.results != widget.results) {
      setState(() => _currentPage = 0);
    }
  }

  void _goToPage(int page) {
    if (page < 0 || page >= _pageCount) return;
    setState(() => _currentPage = page);
    if (widget.scrollController.hasClients) {
      widget.scrollController.jumpTo(0);
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final delta = ((details.scale - 1) * 3).round();
    final target = (_baseCrossAxisCount - delta).clamp(
      _minColumns,
      _maxColumns,
    );
    if (target != _crossAxisCount) {
      setState(() => _crossAxisCount = target);
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    // Sauvegarde une seule fois le geste terminé, pas à chaque frame.
    GridColumnsStore.set('explorer', _crossAxisCount);
  }

  double _scaleFor(int columns, bool isLarge) {
    return switch (columns) {
      1 => isLarge ? 1.0 : 0.85,
      2 => isLarge ? 1.0 : 0.74,
      3 => isLarge ? 1.0 : 0.9,
      _ => isLarge ? 1.0 : 0.9,
    };
  }

  GridFormatStyle _getGridStyle(int columns, double maxWidth) {
    final isLarge = maxWidth > 600;
    final scale = _scaleFor(columns, isLarge);

    final (
      title,
      sub,
      meta,
      year,
      spH,
      spV,
      hPad,
      textH,
      pad,
      maxGrid,
    ) = switch (columns) {
      1 => (
        22.0, 16.0, 14.0,
        16.0,
        40.0, 40.0,
        40.0,
        150.0,
        const EdgeInsets.fromLTRB(16, 14, 16, 14),
        700.0,
      ),
      2 => (
        16.5, 15.5, 14.5,
        14.0,
        12.0, 14.0,
        36.0,
        74.0,
        const EdgeInsets.fromLTRB(10, 10, 10, 8),
        null,
      ),
      3 => (
        13.0,
        11.0,
        10.0,
        10.0,
        8.0,
        12.0,
        34.0,
        56.0,
        const EdgeInsets.fromLTRB(8, 6, 8, 4),
        null,
      ),
      _ => (
        12.0,
        0.0,
        0.0,
        0.0,
        6.0,
        10.0,
        28.0,
        0.0,
        const EdgeInsets.fromLTRB(3, 1, 3, 4),
        null,
      ),
    };

    return GridFormatStyle(
      titleFontSize: title * scale,
      subtitleFontSize: sub * scale,
      metaFontSize: meta * scale,
      yearFontSize: year * scale,
      spacingH: spH * scale,
      spacingV: spV * scale,
      horizontalPadding: hPad * scale,
      textContainerHeight: textH * scale,
      textPadding: EdgeInsets.fromLTRB(
        pad.left * scale,
        pad.top * scale,
        pad.right * scale,
        pad.bottom * scale,
      ),
      maxGridWidth: maxGrid != null ? maxGrid * scale : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _currentPageItems;
    final bottomSafeArea = MediaQuery.of(context).viewPadding.bottom;

    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final style = _getGridStyle(_crossAxisCount, constraints.maxWidth);

            final grid = MasonryGridView.count(
              key: ValueKey('$_crossAxisCount-$_currentPage'),
              controller: widget.scrollController,
              padding: EdgeInsets.fromLTRB(
                style.horizontalPadding,
                90,
                style.horizontalPadding,
                _pageCount > 1 ? 96 + bottomSafeArea : 72 + bottomSafeArea,
              ),
              crossAxisCount: _crossAxisCount,
              mainAxisSpacing: style.spacingV,
              crossAxisSpacing: style.spacingH,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final result = items[index] as Map;
                return ResultCard(
                  result: result,
                  columns: _crossAxisCount,
                  style: style,
                  onTap: () => widget.onTapResult?.call(result),
                );
              },
            );

            return GestureDetector(
              onScaleStart: (_) => _baseCrossAxisCount = _crossAxisCount,
              onScaleUpdate: _onScaleUpdate,
              onScaleEnd: _onScaleEnd,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween(begin: .94, end: 1.0).animate(animation),
                    child: child,
                  ),
                ),
                child: style.maxGridWidth != null
                    ? Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: style.maxGridWidth!,
                          ),
                          child: grid,
                        ),
                      )
                    : grid,
              ),
            );
          },
        ),
        if (_pageCount > 1) ...[
          Positioned(
            left: 8,
            bottom: 16,
            child: PageNav(
              icon: Icons.chevron_left,
              iconFirst: true,
              label: '${_currentPage + 1}',
              onTap: _currentPage > 0
                  ? () => _goToPage(_currentPage - 1)
                  : null,
            ),
          ),
          Positioned(
            right: 8,
            bottom: 16,
            child: PageNav(
              icon: Icons.chevron_right,
              iconFirst: false,
              label: '$_pageCount',
              onTap: _currentPage < _pageCount - 1
                  ? () => _goToPage(_currentPage + 1)
                  : null,
            ),
          ),
        ],
      ],
    );
  }
}