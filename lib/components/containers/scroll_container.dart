import 'package:flutter/material.dart';

// Equivalente a client/src/components/Containers/ScrollContainer.jsx
// Scroll con soporte para infinite scroll (onEndReached).

class ScrollContainer extends StatefulWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onEndReached;
  final double onEndReachedThreshold;
  final bool loadingMore;
  final Widget? listFooter;

  const ScrollContainer({
    super.key,
    required this.children,
    this.padding,
    this.onEndReached,
    this.onEndReachedThreshold = 0.5,
    this.loadingMore = false,
    this.listFooter,
  });

  @override
  State<ScrollContainer> createState() => _ScrollContainerState();
}

class _ScrollContainerState extends State<ScrollContainer> {
  final ScrollController _controller = ScrollController();
  bool _called = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (widget.onEndReached == null) return;

    final pos = _controller.position;
    final distanceFromBottom = pos.maxScrollExtent - pos.pixels;
    final thresholdPx = pos.viewportDimension * widget.onEndReachedThreshold;

    if (distanceFromBottom > thresholdPx + 50) {
      _called = false;
    }

    if (distanceFromBottom <= thresholdPx && !widget.loadingMore && !_called) {
      _called = true;
      widget.onEndReached!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _controller,
      padding: widget.padding ??
          const EdgeInsets.only(bottom: 30, left: 16, right: 16, top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ...widget.children,
          if (widget.loadingMore || widget.listFooter != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: widget.listFooter ?? const CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
