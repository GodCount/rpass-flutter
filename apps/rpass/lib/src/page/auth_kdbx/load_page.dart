import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:keepass_core/keepass_core.dart';

import '../../context/biometric.dart';
import '../../i18n.dart';
import '../../native/channel.dart';
import '../../store/index.dart';
import '../../util/route.dart';
import '../../widget/common.dart';
import '../route.dart';
import 'authorized_page.dart';

class _LoadKdbxArgs extends PageRouteArgs {
  _LoadKdbxArgs({super.key});
}

class LoadKdbxRoute extends PageRouteInfo<_LoadKdbxArgs> {
  LoadKdbxRoute({Key? key}) : super(name, args: _LoadKdbxArgs(key: key));

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
      final password = passwordController.text;
      final keyFile = keyFilecontroller.keyFile;

      if (!isPassword && keyFile == null) {
        throw Exception("Lack of key file.");
      }

      final credentials = Credentials.from(
        password: isPassword ? password : null,
        keyfile: keyFile?.$2,
      );

      kdbxFile = kdbxFile ?? await Store.localInfo.localKdbxFile.readAsBytes();

      Kdbx kdbx = await Kdbx.openBytes(
        bytes: kdbxFile!,
        credentials: credentials,
        filepath: Store.localInfo.localKdbxFile.path,
      );

      if (Store.settings.enableRecordKeyFilePath) {
        await Store.settings.setKeyFilePath(keyFile?.$1);
      }

      Store.kdbx.setKdbx(kdbx);

      await _responseAutoFill(kdbx);

      context.router.replace(HomeRoute());
    }
  }

  Future<void> _responseAutoFill(Kdbx kdbx) async {
    final metadata = await NativeInstancePlatform.instance.autofillService
        .metadata();

    if (metadata == null) return;

    AutofillDataset result = await kdbx.autofillSearch(metadata: metadata);

    if (Store.settings.manualSelectFillItem) {
      result.manual = true;
      result.message = I18n.of(context)!.manual_select_fill_item;

      // 手动选择
      if (metadata.manual == true) {
        final kdbxEntryId = await KdbxEntrySelectorDialog.openDialog(context);
        result = await kdbx.autofillSearch(
          metadata: metadata,
          entryId: kdbxEntryId,
        );
      }
    }

    await NativeInstancePlatform.instance.autofillService.responseDataset(
      result,
    );

    return;
  }

  @override
  Future<void> verifyBiometric() async {
    final biometric = Biometric.of(context);

    if (!biometric.enable) return;

    kdbxFile = kdbxFile ?? await Store.localInfo.localKdbxFile.readAsBytes();

    final hash = await biometric.getCredentials(context);
    final kdbx = await Kdbx.openBytes(
      bytes: kdbxFile!,
      credentials: Credentials.formCompositeKey(key: hash),
      filepath: Store.localInfo.localKdbxFile.path,
    );

    Store.kdbx.setKdbx(kdbx);

    await _responseAutoFill(kdbx);

    context.router.replace(HomeRoute());
  }

  @override
  void dispose() {
    kdbxFile = null;
    super.dispose();
  }
}
