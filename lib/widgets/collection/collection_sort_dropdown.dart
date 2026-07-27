import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/collection_provider.dart';

/// Sort control. Tapping the button opens a dropdown panel anchored
/// right below/right of it (via [CompositedTransformFollower]). Selections
/// made inside the panel are staged locally and only pushed to the
/// provider when the panel closes — so you can change sort field *and*
/// direction in one go instead of the list re-sorting after every tap.
class CollectionSortDropdown extends StatefulWidget {
  const CollectionSortDropdown({super.key});

  @override
  State<CollectionSortDropdown> createState() => _CollectionSortDropdownState();
}

class _CollectionSortDropdownState extends State<CollectionSortDropdown>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  late final AnimationController _animController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  );

  // Staged selection — only committed to the provider when the panel closes.
  late CollectionSort _pendingSort;
  late bool _pendingDescending;

  @override
  void dispose() {
    _removeOverlay();
    _animController.dispose();
    super.dispose();
  }

  void _toggle() => _overlayEntry != null ? _close() : _open();

  void _open() {
    final provider = context.read<CollectionProvider>();
    _pendingSort = provider.sort;
    _pendingDescending = provider.sortDescending;

    _overlayEntry = _buildOverlay();
    Overlay.of(context).insert(_overlayEntry!);
    _animController.forward(from: 0);
    setState(() {});
  }

  Future<void> _close() async {
    // Commit the staged selection once, on close — not per tap.
    final provider = context.read<CollectionProvider>();
    if (provider.sort != _pendingSort) {
      provider.setSort(_pendingSort);
    }
    if (provider.sortDescending != _pendingDescending) {
      provider.toggleSortDirection();
    }

    await _animController.reverse();
    _removeOverlay();
    if (mounted) setState(() {});
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _buildOverlay() {
    final renderBox = context.findRenderObject() as RenderBox;
    final buttonSize = renderBox.size;
    const panelWidth = 180.0;

    return OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _close,
                child: const SizedBox.shrink(),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(
                buttonSize.width - panelWidth,
                buttonSize.height + 8,
              ),
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _animController,
                  curve: Curves.easeOut,
                ),
                child: ScaleTransition(
                  scale: Tween(begin: 0.94, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _animController,
                      curve: Curves.easeOut,
                    ),
                  ),
                  alignment: Alignment.topRight,
                  child: Material(
                    type: MaterialType.transparency,
                    child: StatefulBuilder(
                      builder: (context, setPanelState) {
                        return _SortDropdownPanel(
                          width: panelWidth,
                          selectedSort: _pendingSort,
                          descending: _pendingDescending,
                          onSortChanged: (s) =>
                              setPanelState(() => _pendingSort = s),
                          onDirectionChanged: (d) =>
                              setPanelState(() => _pendingDescending = d),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CollectionProvider>();
    final isOpen = _overlayEntry != null;
    const radius = BorderRadius.all(Radius.circular(12));

    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: isOpen
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: isOpen ? .14 : .08),
                borderRadius: radius,
                border: Border.all(
                  color: Colors.white.withValues(alpha: isOpen ? .28 : .20),
                  width: 1,
                ),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: radius,
                  onTap: _toggle,
                  child: SizedBox(
                    height: 44,
                    width: 44,
                    child: Icon(
                      provider.sortDescending
                          ? Icons.south_rounded
                          : Icons.north_rounded,
                      size: 18,
                      color: Colors.white.withValues(alpha: .75),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SortDropdownPanel extends StatelessWidget {
  final double width;
  final CollectionSort selectedSort;
  final bool descending;
  final ValueChanged<CollectionSort> onSortChanged;
  final ValueChanged<bool> onDirectionChanged;

  const _SortDropdownPanel({
    required this.width,
    required this.selectedSort,
    required this.descending,
    required this.onSortChanged,
    required this.onDirectionChanged,
  });

  String _label(CollectionSort s) => switch (s) {
    CollectionSort.dateAdded => 'Date added',
    CollectionSort.artist => 'Artist',
    CollectionSort.album => 'Album',
    CollectionSort.releaseDate => 'Release date',
  };

  IconData _icon(CollectionSort s) => switch (s) {
    CollectionSort.dateAdded => Icons.schedule_rounded,
    CollectionSort.artist => Icons.person_rounded,
    CollectionSort.album => Icons.album_outlined,
    CollectionSort.releaseDate => Icons.calendar_today_rounded,
  };

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(16));

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            width: width,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .10),
              borderRadius: radius,
              border: Border.all(color: Colors.white.withValues(alpha: .20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SORT BY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: Colors.white.withValues(alpha: .40),
                        ),
                      ),
                      Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => onDirectionChanged(!descending),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  descending
                                      ? Icons.south_rounded
                                      : Icons.north_rounded,
                                  size: 14,
                                  color: Colors.white.withValues(alpha: .75),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  descending ? 'Descending' : 'Ascending',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: .75),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.white.withValues(alpha: .12)),
                for (final s in CollectionSort.values)
                  _SortOption(
                    icon: _icon(s),
                    label: _label(s),
                    selected: selectedSort == s,
                    onTap: () => onSortChanged(s),
                  ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? Colors.white
                    : Colors.white.withValues(alpha: .5),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: .75),
                  ),
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: Colors.white.withValues(alpha: .85),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
