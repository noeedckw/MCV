import 'package:flutter/material.dart';

/// Full-screen cover viewer: pinch (two fingers) to zoom. Tap outside to close.
Future<void> showCoverViewer(
  BuildContext context, {
  required Widget cover,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: .9),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, anim1, anim2) => _CoverViewerModal(cover: cover),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: .9, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _CoverViewerModal extends StatefulWidget {
  final Widget cover;
  const _CoverViewerModal({required this.cover});

  @override
  State<_CoverViewerModal> createState() => _CoverViewerModalState();
}

class _CoverViewerModalState extends State<_CoverViewerModal> {
  final TransformationController _transformController = TransformationController();

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).maybePop(),
      child: Center(
        child: GestureDetector(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: InteractiveViewer(
              transformationController: _transformController,
              clipBehavior: Clip.none,
              panEnabled: false,
              minScale: 1.0,
              maxScale: 4.0,
              child: widget.cover,
            ),
          ),
        ),
      ),
    );
  }
}