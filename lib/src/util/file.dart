import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class SimpleFile {
  static Future<Directory> applicationDocumentsDirectory =
      getApplicationDocumentsDirectory();

  static Future<void> saveText({
    required String data,
    required String name,
    String ext = ".txt",
    String dialogTitle = "导出文件:",
  }) async {
    final filename = "$name$ext";

    final Uint8List fileData = utf8.encode(data);

    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      initialDirectory: (await applicationDocumentsDirectory).path,
      bytes: fileData,
      fileName: filename,
    );

    if (outputFile == null) {
      throw Exception("user cancel");
    }
  }

  static Future<String> openText({
    String dialogTitle = "导入文件:",
  }) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: dialogTitle,
        type: FileType.custom,
        initialDirectory: (await applicationDocumentsDirectory).path,
        allowedExtensions: ["json", "txt"]);
    if (result == null || result.xFiles.isEmpty) {
      throw Exception("user cancel");
    }
    return await result.xFiles[0].readAsString();
  }
}
