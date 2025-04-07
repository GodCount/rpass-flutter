import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'src/context/biometric.dart';
import 'src/log.dart';
import 'src/rpass.dart';
import 'src/app.dart';
import 'src/store/index.dart';
import 'src/widget/error_widget.dart';

final _logger = Logger("main");

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Log.setupLogging(true);

  // TODO！桌面端未进行测试
  if (Platform.isAndroid || Platform.isIOS) {
    await BiometricState.initCanAuthenticate();
  }

  customErrorWidget();

  try {
    await RpassInfo.init();
    await Store().loadStore();
  } catch (e, s) {
    _logger.severe("init fail!", e, s);
    return runApp(ErrorWidget.builder(FlutterErrorDetails(
      library: "Rpass framework",
      exception: e,
      stack: s,
    )));
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
