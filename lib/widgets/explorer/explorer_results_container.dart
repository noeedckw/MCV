import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/explorer_provider.dart';
import '../../providers/connectivity_provider.dart';

import 'album_detail_modal.dart';
import 'explorer_error.dart';
import 'explorer_results_grid.dart';
import 'explorer_vinyl_showcase.dart';
import 'genre_accent.dart';

class ExplorerResultsContainer extends StatelessWidget {
  final ExplorerProvider provider;
  final ScrollController scrollController;
  final ValueNotifier<double> scrollOffset;
  final GenreAccent genreAccent;
  final FocusNode focusNode;
  final TextEditingController controller;

  const ExplorerResultsContainer({
    super.key,
    required this.provider,
    required this.scrollController,
    required this.scrollOffset,
    required this.genreAccent,
    required this.focusNode,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final hasInternet = context.watch<ConnectivityProvider>().hasInternet;
    final hasSearched = provider.lastQuery?.isNotEmpty ?? false;

    if (!hasInternet) {
      return ExplorerErrorState(
        type: ExplorerErrorType.noInternet,
        focusNode: focusNode,
      );
    }

    if (provider.results.isNotEmpty) {
      return ExplorerResultsGrid(
        results: provider.results,
        scrollController: scrollController,
        onTapResult: (result) => showAlbumDetailModal(
          context,
          result: result.cast<String, dynamic>(),
        ),
      );
    }

    if (hasSearched && !provider.isLoading) {
      return ExplorerErrorState(
        type: ExplorerErrorType.noResults,
        focusNode: focusNode,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollOffset.value != 0) scrollOffset.value = 0;
    });

    return ExplorerVinylShowcase(
      genreAccent: genreAccent,
      focusNode: focusNode,
      controller: controller,
    );
  }
}
