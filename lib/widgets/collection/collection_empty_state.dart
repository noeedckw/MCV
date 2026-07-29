import 'dart:math';

import 'package:flutter/material.dart';

enum CollectionEmptyType { emptyCollection, emptyWantlist, noSearchResults }

/// Shown when the current view (collection or wantlist) has no items yet,
/// or when a search inside the current view returns nothing.
class CollectionEmptyState extends StatelessWidget {
  CollectionEmptyState({
    super.key,
    required this.type,
    required this.focusNode, // gardé si tu t'en sers ailleurs, plus utilisé pour la taille
  });

  final CollectionEmptyType type;
  final FocusNode focusNode;

  static final _random = Random();

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    final data = _emptyData(type);
    final image = data.images[_random.nextInt(data.images.length)];

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;

        final scale = ((availableHeight - 250) / (500 - 250)).clamp(0.0, 1.0);

        final imageWidth = _lerp(280, 650, scale);
        final imageHeight = _lerp(110, 300, scale);
        final titleSize = _lerp(15, 18, scale);
        final subtitleSize = _lerp(11, 12, scale);
        final spacing1 = _lerp(10, 20, scale);
        final spacing2 = _lerp(4, 6, scale);

        // scale = 1 -> plein espace -> peu/pas de décalage
        // scale = 0 -> espace minimal (clavier ouvert) -> ça monte plus
        final offsetY = _lerp(-40, -10, scale);

        return Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOutCubic,
              transform: Matrix4.translationValues(0, offsetY, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOutCubic,
                    width: imageWidth,
                    height: imageHeight,
                    child: Image.asset(image, fit: BoxFit.contain),
                  ),
                  SizedBox(height: spacing1),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: titleSize,
                      fontWeight: FontWeight.w700,
                    ),
                    child: Text(data.title, textAlign: TextAlign.center),
                  ),
                  SizedBox(height: spacing2),
                  SizedBox(
                    width: 280,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: subtitleSize,
                        height: 1.55,
                      ),
                      child: Text(data.subtitle, textAlign: TextAlign.center),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  _CollectionEmptyData _emptyData(CollectionEmptyType type) {
    switch (type) {
      case CollectionEmptyType.emptyCollection:
        return const _CollectionEmptyData(
          title: "No Records Yet",
          subtitle: "Start collecting by adding your first vinyl.",
          images: ["assets/images/empty_collection_vinyl.png"],
        );
      case CollectionEmptyType.emptyWantlist:
        return const _CollectionEmptyData(
          title: "Your Wantlist Is Empty",
          subtitle: "Save albums you'd like to own to see them here.",
          images: ["assets/images/empty_wantlist_vinyl.png"],
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