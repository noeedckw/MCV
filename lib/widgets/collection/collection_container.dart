import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../../providers/collection_provider.dart';
import '../../storage/vinyl_entry.dart';
import '../../providers/nav_bar_visibility_provider.dart';
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

  double _headerHeight = 132;
  static const double _headerGap = 12;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    context.read<NavBarVisibilityProvider>().setHidden(_searchFocusNode.hasFocus);
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onFocusChange);
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

    return Stack(
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

        // Voile qui absorbe le tap pour fermer le clavier, sans laisser
        // le tap atteindre une cover en dessous. Écoute directement le
        // FocusNode via AnimatedBuilder -> ne rebuild que ce voile,
        // jamais tout le container, donc aucun conflit avec les rebuilds
        // du CollectionProvider pendant la frappe.
        AnimatedBuilder(
          animation: _searchFocusNode,
          builder: (context, _) {
            final hasFocus = _searchFocusNode.hasFocus;
            return Positioned.fill(
              child: IgnorePointer(
                ignoring: !hasFocus,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _searchFocusNode.unfocus(),
                ),
              ),
            );
          },
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
    );
  }
}

/// Reports the size of [child] via [onChange] whenever it actually
/// changes, using the render object's own layout pass instead of a
/// per-build postFrameCallback — avoids the rebuild loop that comes from
/// scheduling a measurement on every single build.
class MeasureSize extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onChange;

  const MeasureSize({
    super.key,
    required this.onChange,
    required Widget super.child,
  });

  @override
  _MeasureSizeRenderObject createRenderObject(BuildContext context) {
    return _MeasureSizeRenderObject(onChange);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _MeasureSizeRenderObject renderObject,
  ) {
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
