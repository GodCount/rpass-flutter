import 'package:flutter/material.dart';

class InfiniteRotateWidget extends StatefulWidget {
  const InfiniteRotateWidget({
    super.key,
    this.child,
    this.duration = const Duration(seconds: 2),
    this.enabled = true,
  });

  final Widget? child;
  final Duration duration;
  final bool enabled;

  @override
  State<InfiniteRotateWidget> createState() => _InfiniteRotateWidgetState();
}

class _InfiniteRotateWidgetState extends State<InfiniteRotateWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void didUpdateWidget(covariant InfiniteRotateWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: widget.child,
    );
  }
}
