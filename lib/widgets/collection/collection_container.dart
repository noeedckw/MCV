import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../../providers/collection_provider.dart';
import '../../storage/vinyl_entry.dart';
import 'collection_empty_state.dart';
import 'collection_grid.dart';
import 'collection_search_and_sort_row.dart';
import 'collection_view_switcher.dart';

/// Top-level orchestrator for the Collection tab.
///
/// The header (view switcher + search/sort row) floats above the grid —
/// no full-width glass strip behind it. Each control (switcher, search
/// bar, sort button) carries its own localized frosted-glass background
/// clipped to its own pill shape, so only those shapes blur what's behind
/// them instead of one big blurred band across the whole top of the
/// screen.
class CollectionContainer extends StatefulWidget {
  final ValueChanged<VinylEntry>? onTapEntry;

  const CollectionContainer({super.key, this.onTapEntry});

  @override
  State<CollectionContainer> createState() => _CollectionContainerState();
}

class _CollectionContainerState extends State<CollectionContainer> {
  final _searchFocusNode = FocusNode();

  // Only ever set from MeasureSize's onChange, which itself only fires
  // when the header's real size actually changes -> no rebuild loop.
  double _headerHeight = 132;

  // Extra breathing room between the bottom of the header and the first
  // row of covers, so the grid doesn't start flush against it.
  static const double _headerGap = 12;

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  CollectionEmptyType _resolveEmptyType(CollectionProvider provider) {
    final isWantlist = provider.view == CollectionView.wantlist;
    final isSearching = provider.searchQuery.isNotEmpty;

    if (isSearching) return CollectionEmptyType.noSearchResults;
    return isWantlist
        ? CollectionEmptyType.emptyWantlist
        : CollectionEmptyType.emptyCollection;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CollectionProvider>();
    final vinyls = provider.filteredVinyls;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _searchFocusNode.unfocus(),
      child: Stack(
        children: [
          Positioned.fill(
            child: vinyls.isEmpty
                ? Padding(
                    padding: EdgeInsets.only(top: _headerHeight + _headerGap),
                    child: CollectionEmptyState(
                      type: _resolveEmptyType(provider),
                      focusNode: _searchFocusNode,
                    ),
                  )
                : CollectionGrid(
                    entries: vinyls,
                    topPadding: _headerHeight + _headerGap,
                    onTapEntry: widget.onTapEntry ?? (_) {},
                  ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: MeasureSize(
              onChange: (size) {
                if ((size.height - _headerHeight).abs() > 0.5) {
                  setState(() => _headerHeight = size.height);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  const CollectionViewSwitcher(),
                  const SizedBox(height: 12),
                  CollectionSearchAndSortRow(focusNode: _searchFocusNode),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reports the size of [child] via [onChange] whenever it actually
/// changes, using the render object's own layout pass instead of a
/// per-build postFrameCallback — avoids the rebuild loop that comes from
/// scheduling a measurement on every single build.
class MeasureSize extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onChange;

  const MeasureSize({super.key, required this.onChange, required Widget super.child});

  @override
  _MeasureSizeRenderObject createRenderObject(BuildContext context) {
    return _MeasureSizeRenderObject(onChange);
  }

  @override
  void updateRenderObject(BuildContext context, _MeasureSizeRenderObject renderObject) {
    renderObject.onChange = onChange;
  }
}

class _MeasureSizeRenderObject extends RenderProxyBox {
  ValueChanged<Size> onChange;
  Size? _oldSize;

  _MeasureSizeRenderObject(this.onChange);

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child?.size;
    if (newSize != null && newSize != _oldSize) {
      _oldSize = newSize;
      WidgetsBinding.instance.addPostFrameCallback((_) => onChange(newSize));
    }
  }
}