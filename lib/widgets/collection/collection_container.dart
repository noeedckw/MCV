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

class CollectionContainer extends StatefulWidget {
  final ValueChanged<VinylEntry>? onTapEntry;

  const CollectionContainer({super.key, this.onTapEntry});

  @override
  State<CollectionContainer> createState() => _CollectionContainerState();
}

class _CollectionContainerState extends State<CollectionContainer> {
  final _searchFocusNode = FocusNode();
  late final PageController _pageController;

  double _headerHeight = 132;
  static const double _headerGap = 12;

  // Piste la dernière vue connue pour ne réagir qu'aux VRAIS changements
  // de `provider.view` (ex: tap sur le switcher), et ignorer ceux qu'on
  // vient de déclencher nous-même via le swipe (onPageChanged).
  CollectionView? _lastView;
  bool _viewChangeFromSwipe = false;

  bool _emptyImagesPrecached = false;

  static const _emptyStateAssets = [
    "assets/images/empty_collection_vinyl.png",
    "assets/images/empty_wantlist_vinyl.png",
    "assets/images/no_results_vinyl_1.png",
    "assets/images/no_results_vinyl_2.png",
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_emptyImagesPrecached) {
      _emptyImagesPrecached = true;
      for (final path in _emptyStateAssets) {
        precacheImage(AssetImage(path), context);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onFocusChange);
    _pageController = PageController();
  }

  void _onFocusChange() {
    context.read<NavBarVisibilityProvider>().setHidden(_searchFocusNode.hasFocus);
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onFocusChange);
    _searchFocusNode.dispose();
    _pageController.dispose();
    super.dispose();
  }

  static int _indexForView(CollectionView view) =>
      view == CollectionView.owned ? 0 : 1;

  static CollectionView _viewForIndex(int index) =>
      index == 0 ? CollectionView.owned : CollectionView.wantlist;

  void _onPageChanged(int index, CollectionProvider provider) {
    final newView = _viewForIndex(index);
    if (newView == provider.view) return;

    _viewChangeFromSwipe = true;
    provider.setView(newView);
  }

  CollectionEmptyType _resolveEmptyType(
    CollectionProvider provider,
    CollectionView view,
  ) {
    final isWantlist = view == CollectionView.wantlist;
    final isSearching = provider.searchQuery.isNotEmpty;

    if (isSearching) return CollectionEmptyType.noSearchResults;
    return isWantlist
        ? CollectionEmptyType.emptyWantlist
        : CollectionEmptyType.emptyCollection;
  }

  Widget _buildPage(CollectionView view, CollectionProvider provider) {
    final vinyls = provider.filteredVinylsFor(view);

    return vinyls.isEmpty
        ? Padding(
            padding: EdgeInsets.only(top: _headerHeight + _headerGap),
            child: CollectionEmptyState(
              type: _resolveEmptyType(provider, view),
              focusNode: _searchFocusNode,
            ),
          )
        : CollectionGrid(
            entries: vinyls,
            topPadding: _headerHeight + _headerGap,
            onTapEntry: widget.onTapEntry ?? (_) {},
          );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CollectionProvider>();

    if (_lastView != provider.view) {
      if (_viewChangeFromSwipe) {
        _viewChangeFromSwipe = false;
      } else {
        final targetIndex = _indexForView(provider.view);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.animateToPage(
              targetIndex,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
            );
          }
        });
      }
      _lastView = provider.view;
    }

    return Stack(
      children: [
        Positioned.fill(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) => _onPageChanged(index, provider),
            children: [
              _buildPage(CollectionView.owned, provider),
              _buildPage(CollectionView.wantlist, provider),
            ],
          ),
        ),

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