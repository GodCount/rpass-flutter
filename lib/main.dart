import 'package:flutter/material.dart';

import 'src/page/widget/biometric.dart';
import 'src/rpass.dart';
import 'src/app.dart';
import 'src/store/index.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await RpassInfo.init();

  final store = Store();
  await store.loadStore();

  await BiometricState.initCanAuthenticate();

  runApp(RpassApp(
    store: store,
  ));
}
