import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ExplorerSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final ValueListenable<double> scrollOffset;
  final Color accent;
  final bool isLoading;

  const ExplorerSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.scrollOffset,
    required this.accent,
    required this.isLoading,
  });

  @override
  State<ExplorerSearchBar> createState() => _ExplorerSearchBarState();
}

class _ExplorerSearchBarState extends State<ExplorerSearchBar> {
  bool hasText = false;

  static const double _startOffset = 2;
  static const double _transitionDistance = 40;

  @override
  void initState() {
    super.initState();
    hasText = widget.controller.text.isNotEmpty;
    widget.controller.addListener(_updateText);
  }

  void _updateText() {
    final value = widget.controller.text.isNotEmpty;
    if (value != hasText) {
      setState(() {
        hasText = value;
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateText);
    super.dispose();
  }

  void _clear() {
    widget.controller.clear();
    widget.onChanged("");
    // Vider le champ doit aussi vider la recherche en cours (résultats,
    // erreur éventuelle) : on déclenche le même chemin qu'une validation
    // avec une chaîne vide. ExplorerProvider.search("") ne fait aucun appel
    // réseau, il ne fait que réinitialiser l'état.
    widget.onSubmitted("");
    widget.focusNode.requestFocus();
  }

  void _requestFocus() {
    widget.focusNode.requestFocus();

    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: widget.controller.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.focusNode, widget.scrollOffset]),
      builder: (context, child) {
        final focused = widget.focusNode.hasFocus;

        final raw = widget.scrollOffset.value - _startOffset;
        final scrollT = (raw / _transitionDistance).clamp(0.0, 1.0);

        final bgAlphaTop = focused ? .90 : .80;
        final bgAlphaScrolled = focused ? .45 : .30;
        final bgAlpha = lerpDouble(bgAlphaTop, bgAlphaScrolled, scrollT)!;

        final borderAlphaTop = focused ? .4 : .2;
        final borderAlphaScrolled = focused ? .6 : .3;
        final borderAlpha =
            lerpDouble(borderAlphaTop, borderAlphaScrolled, scrollT)!;

        final haloAlphaTop = focused ? .22 : .18;
        final haloAlphaScrolled = focused ? .28 : .14;
        final haloAlpha =
            lerpDouble(haloAlphaTop, haloAlphaScrolled, scrollT)!;

        final haloBlurTop = focused ? 12.0 : 8.0;
        final haloBlur = lerpDouble(haloBlurTop, 5.0, scrollT)!;

        final haloSpread = haloBlur / 2 + 1.0;

        final blurSigma = lerpDouble(16, 11, scrollT)!;
        final height = lerpDouble(54, 48, scrollT)!;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _requestFocus,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: widget.accent.withValues(alpha: borderAlpha),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.accent.withValues(alpha: haloAlpha),
                    blurRadius: haloBlur,
                    spreadRadius: haloSpread,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: blurSigma,
                    sigmaY: blurSigma,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.black.withValues(alpha: bgAlpha),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 18),
                        Icon(
                          Icons.search_rounded,
                          size: 21,
                          color: Color.lerp(
                            Colors.white,
                            widget.accent,
                            .35,
                          )!
                              .withValues(
                                alpha: focused
                                    ? .95
                                    : lerpDouble(.85, .55, scrollT)!,
                              ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: widget.controller,
                            focusNode: widget.focusNode,
                            onChanged: widget.onChanged,
                            onSubmitted: widget.onSubmitted,
                            textInputAction: TextInputAction.search,
                            cursorColor: widget.accent,
                            textAlignVertical: TextAlignVertical.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.0,
                            ),
                            decoration: InputDecoration(
                              isCollapsed: true,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              hintText: "Artist, album...",
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: .45),
                                fontSize: 15,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                        if (widget.isLoading)
                          Padding(
                            padding: const EdgeInsets.only(right: 18),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(widget.accent),
                              ),
                            ),
                          )
                        else if (hasText)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: IconButton(
                              splashRadius: 18,
                              icon: Icon(
                                Icons.close_rounded,
                                size: 19,
                                color: Colors.white.withValues(alpha: .7),
                              ),
                              onPressed: _clear,
                            ),
                          )
                        else
                          const SizedBox(width: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}