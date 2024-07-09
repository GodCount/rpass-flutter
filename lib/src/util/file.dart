import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class SimpleFile {
  static Future<Directory> applicationDocumentsDirectory =
      getApplicationDocumentsDirectory();

  static Future<String> _getSaveLocation(String fileName) async {
    final initialDirectory = (await applicationDocumentsDirectory).path;

    final result = await getSaveLocation(
      initialDirectory: initialDirectory,
      suggestedName: fileName,
    );

    if (result == null) throw Exception("user cancel");

    return result.path;
  }

  static Future<void> saveText({
    required String data,
    required String name,
    String ext = ".txt",
  }) async {
    final filename = "$name$ext";
    final filepath = await _getSaveLocation(filename);
    final Uint8List fileData = utf8.encode(data);
    final XFile textFile =
        XFile.fromData(fileData, mimeType: "text/plain", name: filename);

    await textFile.saveTo(filepath);
  }

  static Future<String> openText() async {
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'text',
      extensions: ['txt', 'json'],
    );

    final XFile? file = await openFile(
      acceptedTypeGroups: <XTypeGroup>[typeGroup],
      initialDirectory: (await applicationDocumentsDirectory).path,
    );

    if (file == null) {
      throw Exception("user cancel");
    }
    return await file.readAsString();
  }
}
