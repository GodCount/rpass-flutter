import 'package:flutter/material.dart';
import 'package:rpass/src/store/index.dart';

import 'src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = Store();
  await store.loadStore();

  runApp(RpassApp(
    store: store,
  ));
}
