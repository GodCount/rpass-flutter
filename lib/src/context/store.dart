import 'package:flutter/material.dart';

import '../store/index.dart';
import 'biometric.dart';
import 'kdbx.dart';

class StoreProvider extends StatelessWidget {
  const StoreProvider({super.key, required this.child});

  final Widget child;

  @Deprecated(
    'Use Store.instance instead.'
    'Deprecated Store of.',
  )
  static Store of(BuildContext context) {
    return Store.instance;
  }

  @override
  Widget build(BuildContext context) {
    return KdbxProvider(
      child: Biometric(
        child: child,
      ),
    );
  }
}
