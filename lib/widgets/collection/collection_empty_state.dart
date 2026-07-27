import 'dart:math';

import 'package:flutter/material.dart';

enum CollectionEmptyType {
  emptyCollection,
  emptyWantlist,
  noSearchResults,
}

/// Shown when the current view (collection or wantlist) has no items yet,
/// or when a search inside the current view returns nothing.
class CollectionEmptyState extends StatelessWidget {
  CollectionEmptyState({
    super.key,
    required this.type,
    required this.focusNode,
  });

  final CollectionEmptyType type;
  final FocusNode focusNode;

  static final _random = Random();

  @override
  Widget build(BuildContext context) {
    final data = _emptyData(type);
    final image = data.images[_random.nextInt(data.images.length)];

    return Center(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: AnimatedBuilder(
          animation: focusNode,
          builder: (context, _) {
            final isFocused = focusNode.hasFocus;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
              transform: Matrix4.translationValues(
                0,
                isFocused ? -40 : -20,
                0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOutCubic,
                    width: isFocused ? 450 : 650,
                    height: isFocused ? 180 : 300,
                    child: Image.asset(
                      image,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    data.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 280,
                    child: Text(
                      data.subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  _CollectionEmptyData _emptyData(CollectionEmptyType type) {
    switch (type) {
      case CollectionEmptyType.emptyCollection:
        return const _CollectionEmptyData(
          title: "No Records Yet",
          subtitle: "Start collecting by adding your first vinyl.",
          images: [
            "assets/images/empty_collection_vinyl.png",
          ],
        );

      case CollectionEmptyType.emptyWantlist:
        return const _CollectionEmptyData(
          title: "Your Wantlist Is Empty",
          subtitle: "Save albums you'd like to own to see them here.",
          images: [
            "assets/images/empty_wantlist_vinyl.png",
          ],
        );

      case CollectionEmptyType.noSearchResults:
        return const _CollectionEmptyData(
          title: "No Results Found",
          subtitle: "Try searching with different keywords.",
          images: [
            "assets/images/no_results_vinyl_1.png",
            "assets/images/no_results_vinyl_2.png",
          ],
        );
    }
  }
}

class _CollectionEmptyData {
  final String title;
  final String subtitle;
  final List<String> images;

  const _CollectionEmptyData({
    required this.title,
    required this.subtitle,
    required this.images,
  });
}