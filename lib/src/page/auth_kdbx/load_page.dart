import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../context/biometric.dart';
import '../../context/kdbx.dart';
import '../../kdbx/kdbx.dart';
import '../../native/channel.dart';
import '../../native/platform/android.dart';
import '../../store/index.dart';
import '../../util/route.dart';
import '../../widget/common.dart';
import '../route.dart';
import 'authorized_page.dart';

class _LoadKdbxArgs extends PageRouteArgs {
  _LoadKdbxArgs({super.key});
}

class LoadKdbxRoute extends PageRouteInfo<_LoadKdbxArgs> {
  LoadKdbxRoute({
    Key? key,
  }) : super(
          name,
          args: _LoadKdbxArgs(key: key),
        );

  static const name = "LoadKdbxRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_LoadKdbxArgs>(orElse: () => _LoadKdbxArgs());
      return LoadKdbxPage(key: args.key);
    },
  );
}

class LoadKdbxPage extends AuthorizedPage {
  const LoadKdbxPage({super.key});

  @override
  AuthorizedPageState<LoadKdbxPage> createState() => _LoadKdbxPageState();
}

class _LoadKdbxPageState extends AuthorizedPageState<LoadKdbxPage> {
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
      final store = Store.instance;
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

      if (!(await _isAutoFill(kdbx))) {
        context.router.replace(HomeRoute());
      }
    }
  }

  Future<bool> _isAutoFill(Kdbx kdbx) async {
    final metadata =
        await NativeInstancePlatform.instance.autofillService.metadata();

    if (metadata == null) return false;

    List<AutofillDataset> result = await kdbx.autofillSearch(metadata);

    if (result.isEmpty && Store.instance.settings.manualSelectFillItem) {
      final kdbxEntry = await KdbxEntrySelectorDialog.openDialog(context);
      final dataset = kdbxEntry?.toAutofillDataset(metadata.fieldTypes);

      if (dataset != null) result.add(dataset);
    }

    await NativeInstancePlatform.instance.autofillService.responseDataset(result);

    return true;
  }

  @override
  Future<void> verifyBiometric() async {
    final biometric = Biometric.of(context);

    if (!biometric.enable) return;

    final store = Store.instance;

    kdbxFile = kdbxFile ?? await store.localInfo.localKdbxFile.readAsBytes();

    final hash = await biometric.getCredentials(context);
    final kdbx = await Kdbx.loadBytesFromHash(
      data: kdbxFile!,
      token: hash,
      filepath: store.localInfo.localKdbxFile.path,
    );

    KdbxProvider.setKdbx(context, kdbx);

    if (!(await _isAutoFill(kdbx))) {
      context.router.replace(HomeRoute());
    }
  }

  @override
  void dispose() {
    kdbxFile = null;
    super.dispose();
  }
}
