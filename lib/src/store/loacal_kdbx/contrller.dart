import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class LocalKdbxFileContrller {
  static const LocalKdbxFileName = "rpass.kdbx";

  late File _localKdbxFile;
  late bool _localKdbxFileExists;

  File get localKdbxFile => _localKdbxFile;
  bool get localKdbxFileExists => _localKdbxFileExists;


  Future<File> _getLocalKdbxFile() async {
    // TODO! 处理这个可能的报错
    final dir = await getApplicationSupportDirectory();
    return File(path.join(dir.path, LocalKdbxFileName));
  }

  Future<void> init() async {
    _localKdbxFile = await _getLocalKdbxFile();
    _localKdbxFileExists = await _localKdbxFile.exists();
  }
}
