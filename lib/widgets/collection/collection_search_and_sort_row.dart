import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/collection_provider.dart';
import 'collection_sort_dropdown.dart';

/// Search field + sort dropdown trigger, sitting side by side under the
/// view switcher. Same glass language as the pill nav bar: blurred
/// translucent fill, hairline border, soft drop shadow.
class CollectionSearchAndSortRow extends StatelessWidget {
  const CollectionSearchAndSortRow({super.key, this.focusNode});

  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CollectionProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _GlassSurface(
              height: 44,
              borderRadius: 16,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: Colors.white.withValues(alpha: .5),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        focusNode: focusNode,
                        onChanged: provider.setSearchQuery,
                        style: const TextStyle(color: Colors.white, fontSize: 13.5),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: 'Search...',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: .35),
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const CollectionSortDropdown(),
        ],
      ),
    );
  }
}

/// Shared glass surface: blur + translucent fill + hairline border + soft
/// shadow. Matches [PillNavBar]'s look so the whole screen reads as one
/// consistent material.
class _GlassSurface extends StatelessWidget {
  const _GlassSurface({
    required this.height,
    required this.borderRadius,
    required this.child,
  });

  final double height;
  final double borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: radius,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.20),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}