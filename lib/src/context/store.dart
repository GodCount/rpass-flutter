import 'package:flutter/material.dart';

import '../store/index.dart';
import 'biometric.dart';

class StoreProvider extends StatefulWidget {
  const StoreProvider({super.key, required this.store, required this.child});

  final Store store;
  final Widget child;

  static Store of(BuildContext context) {
    StoreProviderState? storeProvider;
    if (context is StatefulElement && context.state is StoreProviderState) {
      storeProvider = context.state as StoreProviderState;
    }

    storeProvider =
        storeProvider ?? context.findAncestorStateOfType<StoreProviderState>();

    assert(() {
      if (storeProvider == null) {
        throw FlutterError(
          'StoreProvider operation requested with a context that does not include a StoreProvider.\n'
          'The context used to store from the StoreProvider must be that of a '
          'widget that is a descendant of a StoreProvider widget.',
        );
      }
      return true;
    }());

    return storeProvider!.widget.store;
  }

  @override
  State<StoreProvider> createState() => StoreProviderState();
}

class StoreProviderState extends State<StoreProvider> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store.settings,
      builder: (context, child) => child!,
      child: Biometric(
        child: widget.child,
      ),
    );
  }
}
