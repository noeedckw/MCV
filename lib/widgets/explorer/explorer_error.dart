import 'dart:math';

import 'package:flutter/material.dart';

enum ExplorerErrorType {
  noInternet,
  noResults,
}

class ExplorerErrorState extends StatelessWidget {
  ExplorerErrorState({
    super.key,
    required this.type,
    required this.focusNode,
  });

  final ExplorerErrorType type;
  final FocusNode focusNode;

  static final _random = Random();

  @override
  Widget build(BuildContext context) {
    final data = _errorData(type);

    final image = data.images[_random.nextInt(data.images.length)];

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              image,
              width: 650,
              height: 300,
              fit: BoxFit.contain,
            ),

            AnimatedBuilder(
              animation: focusNode,
              builder: (context, _) {
                final isFocused = focusNode.hasFocus;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  transform: Matrix4.translationValues(
                    0,
                    isFocused ? -50 : 0,
                    0,
                  ),
                  child: Column(
                    children: [
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
          ],
        ),
      ),
    );
  }

  _ExplorerErrorData _errorData(ExplorerErrorType type) {
    switch (type) {
      case ExplorerErrorType.noInternet:
        return const _ExplorerErrorData(
          title: "No Internet Connection",
          subtitle: "Check your connection and try again.",
          images: [
            "assets/images/no_internet_vinyl_1.png",
            "assets/images/no_internet_vinyl_2.png",
          ],
        );

      case ExplorerErrorType.noResults:
        return const _ExplorerErrorData(
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

class _ExplorerErrorData {
  final String title;
  final String subtitle;
  final List<String> images;

  const _ExplorerErrorData({
    required this.title,
    required this.subtitle,
    required this.images,
  });
}