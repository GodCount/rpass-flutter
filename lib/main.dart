import 'package:flutter/material.dart';

import 'src/context/biometric.dart';
import 'src/old/store/index.dart';
import 'src/rpass.dart';
import 'src/app.dart';
import 'src/store/index.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await RpassInfo.init();

  await Store().loadStore();
  await OldStore().loadStore();

  await BiometricState.initCanAuthenticate();

  runApp(const RpassApp());
}
