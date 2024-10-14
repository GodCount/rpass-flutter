import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

export 'package:file_picker/file_picker.dart' show FileType;

class CancelException implements Exception {}

class SimpleFile {
  static Future<Directory> applicationDocumentsDirectory =
      getApplicationDocumentsDirectory();

  static Future<String> saveFile({
    required Uint8List data,
    required String filename,
    String? dialogTitle,
  }) async {
    String? filepath = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      type: FileType.custom,
      initialDirectory: (await applicationDocumentsDirectory).path,
      allowedExtensions: [path.extension(filename).replaceAll(".", "")],
      bytes: data,
      fileName: filename,
    );

    if (filepath == null) {
      throw CancelException();
    }

    if (Platform.isMacOS || Platform.isWindows) {
      File file = File(filepath);
      await file.writeAsBytes(data, flush: true);
    }

    return filepath;
  }

  static Future<(String, Uint8List)> openFile({
    String? dialogTitle,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: dialogTitle,
      type: allowedExtensions != null ? FileType.custom : type,
      initialDirectory: (await applicationDocumentsDirectory).path,
      allowedExtensions: allowedExtensions,
    );
    if (result == null || result.xFiles.isEmpty) {
      throw CancelException();
    }
    return (result.xFiles[0].path, await result.xFiles[0].readAsBytes());
  }

  static Future<String> saveText({
    required String data,
    required String filename,
    String? dialogTitle,
  }) {
    return saveFile(
      data: utf8.encode(data),
      filename: filename,
      dialogTitle: dialogTitle,
    );
  }

  static Future<String> openText({
    String? dialogTitle,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: dialogTitle,
      type: allowedExtensions != null ? FileType.custom : type,
      initialDirectory: (await applicationDocumentsDirectory).path,
      allowedExtensions: allowedExtensions,
    );
    if (result == null || result.xFiles.isEmpty) {
      throw CancelException();
    }
    return await result.xFiles[0].readAsString();
  }
}
