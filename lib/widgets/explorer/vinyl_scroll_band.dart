import 'package:flutter/material.dart';
import '../../utils/cover_url.dart';

enum BandDirection { toLeft, toRight }

/// Bande horizontale de covers qui défile en boucle, dans un sens donné.
class VinylScrollBand extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final double itemSize;

  /// Espacement entre les covers.
  final double spacing;

  /// Vitesse en pixels/seconde.
  final double speed;

  final BandDirection direction;

  /// Appelé au tap sur une cover, avec le résultat Discogs complet.
  final ValueChanged<Map<String, dynamic>>? onTapItem;

  const VinylScrollBand({
    super.key,
    required this.items,
    required this.itemSize,
    this.spacing = 14,
    this.speed = 40,
    this.direction = BandDirection.toLeft,
    this.onTapItem,
  });

  @override
  State<VinylScrollBand> createState() => _VinylScrollBandState();
}

class _VinylScrollBandState extends State<VinylScrollBand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final ScrollController _scrollController = ScrollController();

  static const _repeatCount = 4;

  double get _loopWidth =>
      widget.items.length * (widget.itemSize + widget.spacing);

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(
            vsync: this,
            duration: Duration(
              milliseconds: ((_loopWidth / widget.speed) * 1000).round(),
            ),
          )
          ..addListener(_onTick)
          ..repeat();
  }

  void _onTick() {
    if (!_scrollController.hasClients || widget.items.isEmpty) return;

    final raw = _controller.value * _loopWidth;

    final offset = widget.direction == BandDirection.toLeft
        ? raw
        : (_loopWidth - raw);

    _scrollController.jumpTo(offset);
  }

  @override
  void didUpdateWidget(covariant VinylScrollBand oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.speed != widget.speed ||
        oldWidget.spacing != widget.spacing ||
        oldWidget.itemSize != widget.itemSize ||
        oldWidget.items.length != widget.items.length) {
      _controller
        ..stop()
        ..duration = Duration(
          milliseconds: ((_loopWidth / widget.speed) * 1000).round(),
        )
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return SizedBox(height: widget.itemSize);
    }

    final displayList = List.generate(
      widget.items.length * _repeatCount,
      (i) => widget.items[i % widget.items.length],
    );

    return SizedBox(
      height: widget.itemSize,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: displayList.length,
        itemBuilder: (context, index) {
          final item = displayList[index];
          final url = item['cover_image'] as String;

          return Padding(
            padding: EdgeInsets.only(right: widget.spacing),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTapItem == null
                    ? null
                    : () => widget.onTapItem!(item),
                child: Image.network(
                  resolveCoverUrl(url)!,
                  width: widget.itemSize,
                  height: widget.itemSize,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: widget.itemSize,
                    height: widget.itemSize,
                    color: Colors.white10,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}