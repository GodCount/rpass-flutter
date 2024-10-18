import 'dart:math';

import 'package:flutter/material.dart';

abstract class AnimationControllerState<T extends StatefulWidget>
    extends State<T> with SingleTickerProviderStateMixin {
  Duration? _duration;

  late final AnimationController animationController;

  @override
  void initState() {
    animationController = AnimationController(
        vsync: this, duration: _duration ?? const Duration(milliseconds: 400));
    super.initState();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }
}

class ShakeWidget extends StatefulWidget {
  const ShakeWidget({
    super.key,
    this.offset = 10,
    this.count = 3,
    this.duration = const Duration(milliseconds: 400),
    required this.child,
  });
  final double offset;
  final int count;
  final Duration duration;
  final Widget child;

  @override
  ShakeWidgetState createState() => ShakeWidgetState();
}

class ShakeWidgetState extends AnimationControllerState<ShakeWidget> {
  @override
  void initState() {
    _duration = widget.duration;
    super.initState();
    animationController.addStatusListener(_updateAnimationStatus);
  }

  @override
  void dispose() {
    animationController.removeStatusListener(_updateAnimationStatus);
    super.dispose();
  }

  void _updateAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      animationController.reset();
    }
  }

  void shakeWidget() {
    animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      child: widget.child,
      builder: (context, child) {
        final sineValue =
            sin(widget.count * 2 * pi * animationController.value);
        return Transform.translate(
          offset: Offset(sineValue * widget.offset, 0),
          child: child,
        );
      },
    );
  }
}

typedef ShakeFormFieldBuilder<T> = Widget Function(
  BuildContext context,
  FormFieldValidator<T>? validator,
);

class ShakeFormField<T> extends StatefulWidget {
  const ShakeFormField({
    super.key,
    this.validator,
    required this.builder,
    this.shakeOffset = 10,
    this.shakeCount = 3,
    this.shakeDuration = const Duration(milliseconds: 400),
  });

  final FormFieldValidator<T>? validator;
  final ShakeFormFieldBuilder<T> builder;

  final double shakeOffset;
  final int shakeCount;
  final Duration shakeDuration;

  @override
  State<ShakeFormField<T>> createState() => ShakeFormFieldState<T>();
}

class ShakeFormFieldState<T> extends State<ShakeFormField<T>> {
  final GlobalKey<ShakeWidgetState> _shakeKey = GlobalKey();

  String? _validator(T? value) {
    if (widget.validator != null) {
      final result = widget.validator!.call(value);
      if (result != null) {
        _shakeKey.currentState?.shakeWidget();
      }
      return result;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ShakeWidget(
      key: _shakeKey,
      count: widget.shakeCount,
      offset: widget.shakeOffset,
      duration: widget.shakeDuration,
      child: widget.builder(
        context,
        widget.validator != null ? _validator : null,
      ),
    );
  }
}
