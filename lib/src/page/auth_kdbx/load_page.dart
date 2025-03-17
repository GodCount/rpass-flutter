import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../context/biometric.dart';
import '../../context/kdbx.dart';
import '../../context/store.dart';
import '../../kdbx/kdbx.dart';
import '../page.dart';
import 'authorized_page.dart';

class LoadKdbxPage extends AuthorizedPage {
  const LoadKdbxPage({super.key});

  static const routeName = "/load_kdbx";

  @override
  LoadKdbxPageState createState() => LoadKdbxPageState();
}

class LoadKdbxPageState extends AuthorizedPageState {
  @override
  AuthorizedType get authType => AuthorizedType.load;

  @override
  bool get enableBiometric => true;

  Uint8List? kdbxFile;

  @override
  void initState() {
    super.initState();
    startBiometric();
  }




  @override
  Future<void> confirm() async {
    if (form.currentState!.validate()) {
      final store = StoreProvider.of(context);
      final passowrd = passwordController.text;
      final keyFile = keyFilecontroller.keyFile;

      if (!isPassword && keyFile == null) {
        throw Exception("Lack of key file.");
      }

      final credentials =
          Kdbx.createCredentials(isPassword ? passowrd : null, keyFile?.$2);

      kdbxFile = kdbxFile ?? await store.localInfo.localKdbxFile.readAsBytes();

      Kdbx kdbx = await Kdbx.loadBytesFromCredentials(
        data: kdbxFile!,
        credentials: credentials,
        filepath: store.localInfo.localKdbxFile.path,
      );

      if (store.settings.enableRecordKeyFilePath) {
        await store.settings.setKeyFilePath(keyFile?.$1);
      }

      KdbxProvider.setKdbx(context, kdbx);
      Navigator.of(context).pushReplacementNamed(Home.routeName);
    }
  }

  @override
  Future<void> verifyBiometric() async {
    final biometric = Biometric.of(context);

    if (!biometric.enable) return;

    final store = StoreProvider.of(context);

    kdbxFile = kdbxFile ?? await store.localInfo.localKdbxFile.readAsBytes();

    final hash = await biometric.getCredentials(context);
    final kdbx = await Kdbx.loadBytesFromHash(
      data: kdbxFile!,
      token: hash,
      filepath: store.localInfo.localKdbxFile.path,
    );

    KdbxProvider.setKdbx(context, kdbx);
    Navigator.of(context).pushReplacementNamed(Home.routeName);
  }

  @override
  void dispose() {
    kdbxFile = null;
    super.dispose();
  }
}

class LoadExternalKdbxPageArguments {
  LoadExternalKdbxPageArguments({
    required this.kdbxFile,
    this.kdbxFilePath,
  });

  final Uint8List kdbxFile;
  final String? kdbxFilePath;
}

class LoadExternalKdbxPage extends AuthorizedPage {
  const LoadExternalKdbxPage({super.key});

  static const routeName = "/load_external_kdbx";

  @override
  LoadExternalKdbxPageState createState() => LoadExternalKdbxPageState();
}

class LoadExternalKdbxPageState extends AuthorizedPageState {
  @override
  AuthorizedType get authType => AuthorizedType.load;

  @override
  bool get enableBack => true;

  @override
  bool get readHistoryKeyFile => false;

  @override
  Future<void> confirm() async {
    if (form.currentState!.validate()) {
      final args = ModalRoute.of(context)!.settings.arguments
          as LoadExternalKdbxPageArguments;

      final passowrd = passwordController.text;
      final keyFile = keyFilecontroller.keyFile;

      if (!isPassword && keyFile == null) {
        throw Exception("Lack of key file.");
      }

      Kdbx kdbx = await Kdbx.loadBytesFromCredentials(
        data: args.kdbxFile,
        credentials:
            Kdbx.createCredentials(isPassword ? passowrd : null, keyFile?.$2),
      );

      Navigator.of(context).pop((kdbx, keyFile?.$1));
    }
  }
}
