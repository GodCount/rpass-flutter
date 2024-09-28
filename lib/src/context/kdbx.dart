import 'package:flutter/material.dart';

import '../kdbx/kdbx.dart';

class KdbxProvider extends StatefulWidget {
  const KdbxProvider({super.key, required this.child});

  final Widget child;

  static KdbxProviderState _ofState(BuildContext context) {
    KdbxProviderState? kdbxProvider;
    if (context is StatefulElement && context.state is KdbxProviderState) {
      kdbxProvider = context.state as KdbxProviderState;
    }

    kdbxProvider =
        kdbxProvider ?? context.findAncestorStateOfType<KdbxProviderState>();

    assert(() {
      if (kdbxProvider == null) {
        throw FlutterError(
          'KdbxProvider operation requested with a context that does not include a KdbxProvider.\n'
          'The context used to kdbx from the KdbxProvider must be that of a '
          'widget that is a descendant of a KdbxProvider widget.',
        );
      }
      return true;
    }());

    return kdbxProvider!;
  }

  static void setKdbx(BuildContext context, Kdbx kdbx) {
    _ofState(context).setKdbx(kdbx);
  }

  static Kdbx? of(BuildContext context) {
    return _ofState(context).kdbx;
  }

  @override
  State<KdbxProvider> createState() => KdbxProviderState();
}

class KdbxProviderState extends State<KdbxProvider> {
  Kdbx? kdbx;

  void setKdbx(Kdbx kdbx) {
    this.kdbx = kdbx;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
