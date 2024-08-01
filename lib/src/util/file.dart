import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class SimpleFile {
  static Future<Directory> applicationDocumentsDirectory =
      getApplicationDocumentsDirectory();

  static Future<String> saveText({
    required String data,
    required String name,
    String ext = "txt",
    String? dialogTitle,
  }) async {
    final filename = "$name.$ext";

    final Uint8List fileData = utf8.encode(data);

    String? filepath = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      type: FileType.custom,
      allowedExtensions: [ext],
      initialDirectory: (await applicationDocumentsDirectory).path,
      bytes: fileData,
      fileName: filename,
    );

    if (filepath == null) {
      throw Exception("user cancel");
    }

    if (Platform.isMacOS || Platform.isWindows) {
      File file = File(filepath);
      await file.writeAsBytes(fileData, flush: true);
    }

    return filepath;
  }

  static Future<String> openText({
    String? dialogTitle,
    List<String>? allowedExtensions,
  }) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: dialogTitle,
      type: FileType.custom,
      initialDirectory: (await applicationDocumentsDirectory).path,
      allowedExtensions: allowedExtensions,
    );
    if (result == null || result.xFiles.isEmpty) {
      throw Exception("user cancel");
    }
    return await result.xFiles[0].readAsString();
  }
}
