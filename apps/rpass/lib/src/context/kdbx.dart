import 'package:flutter/material.dart';

import '../kdbx/kdbx.dart';
import '../util/common.dart';

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

  static KdbxProviderState of(BuildContext context) {
    return _ofState(context);
  }

  @override
  State<KdbxProvider> createState() => KdbxProviderState();
}

mixin KdbxProviderListener {
  void onKdbxChanged(Kdbx? kdbx) {}

  void onSelectedKdbxEntryChanged(KdbxEntry? kdbxEntry) {}
}

class KdbxProviderState extends State<KdbxProvider>
    with SimpleObserverListener<KdbxProviderListener> {
  Kdbx? kdbx;
  KdbxEntry? selectedKdbxEntry;

  void setKdbx(Kdbx? kdbx) {
    this.kdbx?.dispose();
    this.kdbx = kdbx;
    selectedKdbxEntry = null;
    emit((listener) {
      listener.onKdbxChanged(kdbx);
      listener.onSelectedKdbxEntryChanged(null);
    });
  }

  void setSelectedKdbxEntry(KdbxEntry? kdbxEntry) {
    if (kdbxEntry == selectedKdbxEntry) return;

    selectedKdbxEntry = kdbxEntry;
    emit((listener) => listener.onSelectedKdbxEntryChanged(kdbxEntry));
  }

  @override
  void dispose() {
    super.dispose();
    kdbx?.dispose();
    kdbx = selectedKdbxEntry = null;
    removeAllListener();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
