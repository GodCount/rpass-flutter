import 'package:flutter/material.dart';
import 'package:rpass/src/widget/shake_widget.dart';

class ShakeTestPage extends StatefulWidget {
  const ShakeTestPage({super.key});

  static const routeName = "/Shake_Test";

  @override
  State<ShakeTestPage> createState() => ShakeTestPageState();
}

class ShakeTestPageState extends State<ShakeTestPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [],
      ),
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
