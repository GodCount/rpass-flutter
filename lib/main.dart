import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'src/context/biometric.dart';
import 'src/log.dart';
import 'src/old/store/index.dart';
import 'src/rpass.dart';
import 'src/app.dart';
import 'src/store/index.dart';

final _logger = Logger("main");

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Log.setupLogging(true);

  await BiometricState.initCanAuthenticate();

  try {
    await RpassInfo.init();
    await Store().loadStore();
    await OldStore().loadStore();
  } catch (e, s) {
    _logger.severe("init fail!", e, s);
    return runApp(InitAppFail(error: e));
  }

  runApp(const RpassApp());
}

class InitAppFail extends StatelessWidget {
  const InitAppFail({super.key, this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            "Init app fail! \n $error",
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.merge(const TextStyle(fontSize: 32)),
          ),
        ),
      ),
    );
  }
}
