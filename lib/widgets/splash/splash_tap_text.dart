import 'package:flutter/material.dart';

/// Texte "my collection of vinyl" / "tap to enter", qui reste invisible
/// pendant les 10 premières secondes du splash puis apparaît en fondu,
/// comme une pensée qui émerge. Se recache instantanément dès que la
/// séquence de sortie démarre (`exiting == true`).
class SplashTapText extends StatelessWidget {
  final Animation<double> textController;
  final bool showText;
  final bool exiting;

  const SplashTapText({
    super.key,
    required this.textController,
    required this.showText,
    required this.exiting,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: textController,
        builder: (context, _) {
          final textOpacity = showText && !exiting
              ? Curves.easeOut.transform(textController.value) * 0.55
              : 0.0;

          return Opacity(
            opacity: textOpacity,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'my collection of vinyl',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w300,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.5,
                    decoration: TextDecoration.none,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'tap to enter',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}