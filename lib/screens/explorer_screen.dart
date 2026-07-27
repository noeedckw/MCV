import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/explorer_provider.dart';
import '../widgets/explorer/explorer_results_container.dart';
import '../widgets/explorer/explorer_search_bar.dart';
import '../widgets/explorer/genre_accent.dart';

class ExplorerScreen extends StatefulWidget {
  const ExplorerScreen({super.key});

  @override
  State<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends State<ExplorerScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  final ValueNotifier<double> _scrollOffset = ValueNotifier(0);

  // Tiré une seule fois à l'ouverture du screen -> seul point commun entre
  // la search bar et le results container (ils sont frères dans le Stack,
  // donc ça ne peut pas se décider dans l'un des deux).
  late final GenreAccent _genreAccent = GenreAccent.random();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      _scrollOffset.value = _scrollController.offset.clamp(0, 200);
    });
  }

  // Ne déclenche plus aucun appel réseau : sert uniquement de point
  // d'extension futur (ex: suggestions locales). L'état visuel de la barre
  // (icône clear, etc.) est déjà géré en interne par ExplorerSearchBar.
  void _onChanged(String value) {}

  // Seul déclencheur d'appel Discogs : validation clavier (Entrée / touche
  // "rechercher") ou clear (voir ExplorerSearchBar._clear).
  void _onSubmitted(String value) {
    context.read<ExplorerProvider>().searchMasters(value);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExplorerProvider>();
    // While the album detail modal is open, slide the search bar up and
    // out instead of leaving it floating on top of the blurred backdrop.
    final hideForModal = provider.isDetailModalOpen;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: const Color.fromARGB(0, 161, 14, 14),
        body: SafeArea(
          child: Stack(
            children: [
              ExplorerResultsContainer(
                provider: provider,
                scrollController: _scrollController,
                scrollOffset: _scrollOffset,
                genreAccent: _genreAccent,
                focusNode: _focusNode,
                controller: _controller,
              ),
              IgnorePointer(
                ignoring: hideForModal,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  offset: hideForModal ? const Offset(0, -0.6) : Offset.zero,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: hideForModal ? 0 : 1,
                    child: ExplorerSearchBar(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: _onChanged,
                      onSubmitted: _onSubmitted,
                      scrollOffset: _scrollOffset,
                      accent: _genreAccent.color,
                      isLoading: provider.isLoading,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
