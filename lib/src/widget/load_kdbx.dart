import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import '../context/biometric.dart';
import '../kdbx/kdbx.dart';
import 'verify_password.dart';

// ignore: unused_element
final _logger = Logger("widget:load_kdbx");

typedef OnLoadedKdbx = void Function(Kdbx kdbx);

typedef ReadKdbxFile = Future<(String, Uint8List)> Function();

class LoadKdbx extends StatefulWidget {
  const LoadKdbx({
    super.key,
    required this.readKdbxFile,
    this.biometric = false,
    required this.onLoadedKdbx,
  });

  final OnLoadedKdbx onLoadedKdbx;
  final ReadKdbxFile readKdbxFile;
  final bool biometric;

  @override
  State<LoadKdbx> createState() => _LoadKdbxState();
}

class _LoadKdbxState extends State<LoadKdbx> {
  (String, Uint8List)? _kdbxFile;

  Future<(String, Uint8List)> _readKdbxFile() async {
    if (_kdbxFile != null) return _kdbxFile!;
    _kdbxFile = await widget.readKdbxFile();
    return _kdbxFile!;
  }

  Future<void> _verifyPassword(OnVerifyPasswordParam param) async {
    if (param.password == null && param.keyFile == null) {
      throw Exception("password is empty and key file is empty");
    }

    final (filepath, data) = await _readKdbxFile();

    Kdbx kdbx = await Kdbx.loadBytesFromCredentials(
      data: data,
      credentials: Kdbx.createCredentials(param.password, param.keyFile),
    );

    widget.onLoadedKdbx(kdbx);
  }

  Future<void> _verifyBiometric() async {
    final biometric = Biometric.of(context);
    final (filepath, data) = await _readKdbxFile();

    final hash = await biometric.getCredentials(context);
    final kdbx = await Kdbx.loadBytesFromHash(
      data: data,
      token: hash,
      filepath: filepath,
    );
    widget.onLoadedKdbx(kdbx);
  }

  @override
  Widget build(BuildContext context) {
    return VerifyPassword(
      biometric: widget.biometric,
      autoPopUpBiometric: true,
      onVerifyPassword: (param) async {
        switch (param.type) {
          case VerifyType.password:
            return _verifyPassword(param);
          case VerifyType.biometric:
            return _verifyBiometric();
        }
      },
    );
  }
}
