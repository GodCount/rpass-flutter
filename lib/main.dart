import 'package:flutter/material.dart';
import 'package:rpass/rpass.dart';
import 'package:rpass/src/store/index.dart';

import 'src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await RpassInfo.init();

  final store = Store();
  await store.loadStore();

  runApp(RpassApp(
    store: store,
  ));
}
