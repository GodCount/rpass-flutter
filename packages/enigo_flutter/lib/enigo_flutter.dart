library enigo_flutter;

import 'src/rust/api/enigo.dart';
export 'src/rust/api/enigo.dart' hide testKey2Key;
export 'src/rust/frb_generated.dart' show RustLib;

Enigo? _enigo;

Enigo get enigo {
  _enigo ??= Enigo.preset();
  return _enigo!;
}
