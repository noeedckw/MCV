import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../storage/grid_columns_store.dart';
import '../../storage/vinyl_entry.dart';
import '../explorer/explorer_results_grid.dart' show GridFormatStyle;
import 'cards/collection_result_card.dart';

/// The scrollable grid of vinyl covers for the active view — same masonry
/// layout and pinch-to-zoom column switching (1 to 4 columns) as
/// `ExplorerResultsGrid`, just fed from local [VinylEntry] objects instead
/// of Discogs search results.
///
/// [collectionKey] identifies which list this grid belongs to (e.g.
/// `'collection'` or `'wantlist'`) so each keeps its own persisted column
/// count, independent of the other, via [GridColumnsStore].
///
/// Pure presentation: it just lays out [entries]. Deciding whether to show
/// this or `CollectionEmptyState` is `CollectionContainer`'s job.
class CollectionGrid extends StatefulWidget {
  final List<VinylEntry> entries;
  final ValueChanged<VinylEntry> onTapEntry;
  final double topPadding;
  final String collectionKey;

  const CollectionGrid({
    super.key,
    required this.entries,
    required this.onTapEntry,
    required this.collectionKey,
    this.topPadding = 4,
  });

  @override
  State<CollectionGrid> createState() => _CollectionGridState();
}

class _CollectionGridState extends State<CollectionGrid> {
  static const int _minColumns = 1;
  static const int _maxColumns = 4;
  static const int _defaultColumns = 2;

  late int _crossAxisCount;
  late int _baseCrossAxisCount;

  @override
  void initState() {
    super.initState();
    // Lecture SYNCHRONE du cache — dispo immédiatement, même si ce State
    // vient d'être recréé après un switch de vue. Plus de flash, plus de
    // SizedBox.shrink() à attendre.
    _crossAxisCount = _restoreColumnCount();
    _baseCrossAxisCount = _crossAxisCount;
  }

  @override
  void didUpdateWidget(covariant CollectionGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the same widget instance gets reused for a different list
    // (e.g. key changes), reload the right saved value.
    if (oldWidget.collectionKey != widget.collectionKey) {
      setState(() {
        _crossAxisCount = _restoreColumnCount();
        _baseCrossAxisCount = _crossAxisCount;
      });
    }
  }

  int _restoreColumnCount() {
    final saved = GridColumnsStore.get(widget.collectionKey);
    if (saved != null && saved >= _minColumns && saved <= _maxColumns) {
      return saved;
    }
    return _defaultColumns;
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
    // Save once the gesture settles, not on every frame of the pinch.
    GridColumnsStore.set(widget.collectionKey, _crossAxisCount);
  }

  // Same scale table as ExplorerResultsGrid, so switching tabs doesn't feel
  // like a different app.
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
        22.0,
        16.0,
        14.0,
        16.0,
        40.0,
        40.0,
        40.0,
        150.0,
        const EdgeInsets.fromLTRB(16, 14, 16, 14),
        700.0,
      ),
      2 => (
        16.5,
        15.5,
        14.5,
        14.0,
        12.0,
        14.0,
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
    final bottomSafeArea = MediaQuery.of(context).viewPadding.bottom;

    return LayoutBuilder(
      builder: (context, constraints) {
        final style = _getGridStyle(_crossAxisCount, constraints.maxWidth);

        final grid = MasonryGridView.count(
          key: ValueKey(_crossAxisCount),
          padding: EdgeInsets.fromLTRB(
            style.horizontalPadding,
            widget.topPadding,
            style.horizontalPadding,
            95 + bottomSafeArea,
          ),
          crossAxisCount: _crossAxisCount,
          mainAxisSpacing: style.spacingV,
          crossAxisSpacing: style.spacingH,
          itemCount: widget.entries.length,
          itemBuilder: (context, index) {
            final entry = widget.entries[index];
            return CollectionResultCard(
              entry: entry,
              columns: _crossAxisCount,
              style: style,
              onTap: () => widget.onTapEntry(entry),
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
    );
  }
}