import 'dart:io';

import 'package:common_native_channel/common_native_channel.dart';
import 'package:enigo_flutter/enigo_flutter.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:window_manager/window_manager.dart';

import 'src/context/biometric.dart';
import 'src/log.dart';
import 'src/native/channel.dart';
import 'src/rpass.dart';
import 'src/app.dart';
import 'src/store/index.dart';
import 'src/tray.dart';
import 'src/util/common.dart';
import 'src/widget/error_widget.dart';

final _logger = Logger("main");

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  customErrorWidget();

  await Log.setupLogging(true);

  if (kIsDesktop) {
    await windowManager.ensureInitialized();
    await windowManager.setPreventClose(true);

    windowManager.waitUntilReadyToShow(
      WindowOptions(size: Size(900, 640), minimumSize: Size(413, 640)),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

  // TODO！桌面端未进行测试
  if (kIsMobile) {
    await BiometricState.initCanAuthenticate();
  }

  await CommonNativeChannelPlatform.instance.ensureInitialized();
  NativeInstancePlatform.ensureInitialized();

  if (Platform.isMacOS || Platform.isWindows) {
    await RustLib.init();
  }

  try {
    await RpassInfo.init();
    await Store.instance.loadStore();

    if (kIsDesktop) {
      await systemTray.ensureInitialized();
      await windowManager.setTitle(RpassInfo.appName);
    }
  } catch (e, s) {
    _logger.severe("init fail!", e, s);
    return runApp(
      ErrorWidget.builder(
        FlutterErrorDetails(library: "Rpass framework", exception: e, stack: s),
      ),
    );
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
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.merge(const TextStyle(fontSize: 32)),
          ),
        ),
      ),
    );
  }
}
