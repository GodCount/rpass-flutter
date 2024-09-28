import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../rpass.dart';
import '../index.dart';

class LocalInfoContrller {
  late String _applicationPath;

  late File _localKdbxFile;
  late bool _localKdbxFileExists;

  File get localKdbxFile => _localKdbxFile;
  bool get localKdbxFileExists => _localKdbxFileExists;

  Future<File> _getLocalKdbxFile() async {
    final baseDir = Directory(path.join(_applicationPath, "kdbx"));
    if(!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }
    return File(path.join(baseDir.path, RpassInfo.defaultKdbxFileName));
  }

  Future<void> init(Store store) async {
    _applicationPath = (await getApplicationSupportDirectory()).path;
    _localKdbxFile = await _getLocalKdbxFile();
    _localKdbxFileExists = await _localKdbxFile.exists();
  }
}
