import 'dart:ui';
import 'vinyl_icon.dart';
import 'package:flutter/material.dart';

class PillNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const PillNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<PillNavBar> createState() => _PillNavBarState();
}

class _PillNavBarState extends State<PillNavBar>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _scaleAnimation;

  static const double _width = 170;
  static const double _height = 56;
  static const double _itemWidth = _width / 2;

  @override
  void initState() {
    super.initState();

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _controller = controller;

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant PillNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.currentIndex != widget.currentIndex) {
      _controller?.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaleAnimation = _scaleAnimation;

    return Center(
      child: Container(
        width: _width,
        height: _height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              width: _width,
              height: _height,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.20),
                  width: 1,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOut,
                    alignment: widget.currentIndex == 0
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: scaleAnimation == null
                        ? const SizedBox(width: _itemWidth, height: _height)
                        : AnimatedBuilder(
                            animation: scaleAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: scaleAnimation.value,
                                child: child,
                              );
                            },
                            child: Container(
                              width: _itemWidth,
                              height: _height,
                              padding: const EdgeInsets.all(4),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: Stack(
                                  children: [
                                    Container(
                                      color: Colors.white.withValues(
                                        alpha: 0.22,
                                      ),
                                    ),

                                    Positioned(
                                      top: 0,
                                      left: 0,
                                      right: 0,
                                      height: (_height - 8) * 0.55,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.white.withValues(
                                                alpha: 0.35,
                                              ),
                                              Colors.white.withValues(alpha: 0),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: _NavIcon(
                          iconBuilder: (color) =>
                              SearchVinylIcon(color: color, size: 35),
                          isSelected: widget.currentIndex == 0,
                          onTap: () => widget.onTap(0),
                        ),
                      ),
                      Expanded(
                        child: _NavIcon(
                          iconBuilder: (color) =>
                              VinylIcon(color: color, size: 35),
                          isSelected: widget.currentIndex == 1,
                          onTap: () => widget.onTap(1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final Widget Function(Color color) iconBuilder;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavIcon({
    required this.iconBuilder,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? Colors.white
        : Colors.white.withValues(alpha: 0.55);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(height: 56, child: Center(child: iconBuilder(color))),
    );
  }
}
