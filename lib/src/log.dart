import 'dart:io';

import 'package:logging/logging.dart';
import 'package:logging_appenders/logging_appenders.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

final _logger = Logger("Logger");

class Log {
  static RotatingFileAppender? _rotatingFileAppender;

  static Future<Directory> getLogDirectory() async {
    Directory? dir = await switch (Platform.operatingSystem) {
      "android" => getExternalStorageDirectory(),
      _ => getApplicationSupportDirectory(),
    };
    assert(dir != null, "get logs dir is null!");
    return Directory(path.join(dir!.path, "logs"));
  }

  static Future<RotatingFileAppender> _genRotatingFileAppender() async {
    final logs = await getLogDirectory();
    if (!(await logs.exists())) {
      logs.create(recursive: true);
    }
    return RotatingFileAppender(
      rotateAtSizeBytes: 10 * 1024 * 1024,
      baseFilePath: path.join(logs.path, "log.log"),
    );
  }

  static Future<void> setupLogging([bool isMainIsolate = false]) async {
    Logger.root.level = Level.ALL;
    PrintAppender().attachToLogger(Logger.root);
    if (isMainIsolate) {
      try {
        _rotatingFileAppender ??= await _genRotatingFileAppender();
        _rotatingFileAppender!.attachToLogger(Logger.root);
      } catch (e, s) {
        _logger.severe("log write attach", e, s);
      }
    }
  }
}
