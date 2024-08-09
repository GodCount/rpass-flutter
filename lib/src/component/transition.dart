import 'package:flutter/material.dart';

class ScaleRebound extends StatefulWidget {
  const ScaleRebound({
    super.key,
    this.duration = const Duration(milliseconds: 300),
    required this.child,
  });

  final Duration duration;
  final Widget child;

  @override
  State<ScaleRebound> createState() => ScaleReboundState();
}

class ScaleReboundState extends State<ScaleRebound>
    with SingleTickerProviderStateMixin {
  static final TweenSequence<double> _scaleIn = TweenSequence(
    [
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.92),
        weight: 0.4,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.92, end: 1.0),
        weight: 0.6,
      ),
    ],
  );

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = _scaleIn.animate(_controller);

    super.initState();
  }

  void rebound() {
    _controller.reset();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}
