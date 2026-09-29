library;

export 'package:flutter_rust_bridge/flutter_rust_bridge.dart'
    show RustStreamSink;

import 'src/rust/api/enigo.dart';
import 'src/rust/frb_generated.dart' show RustLib;

export 'src/rust/api/enigo.dart';
export 'src/rust/api/kdbx.dart';

Future<void> initRustLib() async {
  await RustLib.init();
}

Enigo? _enigo;

Enigo get enigo {
  _enigo ??= Enigo.preset();
  return _enigo!;
}
