import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../context/kdbx.dart';
import '../../i18n.dart';
import '../../util/file.dart';
import '../../util/route.dart';
import '../home/home.dart';
import 'authorized_page.dart';
import '../../widget/extension_state.dart';
import '../../kdbx/kdbx.dart';
import '../../context/store.dart';
import '../../rpass.dart';
import 'load_ext_page.dart';

class _InitialArgs extends PageRouteArgs {
  _InitialArgs({super.key});
}

class InitialRoute extends PageRouteInfo<_InitialArgs> {
  InitialRoute({
    Key? key,
  }) : super(
          name,
          args: _InitialArgs(key: key),
        );

  static const name = "InitialRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_InitialArgs>();
      return InitialPage(key: args.key);
    },
  );
}

class InitialPage extends AuthorizedPage {
  const InitialPage({super.key});

  @override
  AuthorizedPageState<InitialPage> createState() => _InitialPageState();
}

class _InitialPageState extends AuthorizedPageState<InitialPage> {
  @override
  AuthorizedType get authType => AuthorizedType.initial;

  @override
  bool get enableImport => true;

  void _addPresetGroup(Kdbx kdbx) {
    final t = I18n.of(context)!;

    kdbx.kdbxFile.body.rootGroup.name.set(t.default_);

    String? uuid = kdbx.customData[KdbxCustomDataKey.GENERAL_GROUP_UUID];
    if (uuid == null || kdbx.findGroupByUuid(KdbxUuid(uuid)) == null) {
      final general = kdbx.createGroup(t.common);
      kdbx.customData[KdbxCustomDataKey.GENERAL_GROUP_UUID] = general.uuid.uuid;
    }

    uuid = kdbx.customData[KdbxCustomDataKey.EMAIL_GROUP_UUID];

    if (uuid == null || kdbx.findGroupByUuid(KdbxUuid(uuid)) == null) {
      final email = kdbx.createGroup(t.email)..icon.set(KdbxIcon.EMail);
      kdbx.customData[KdbxCustomDataKey.EMAIL_GROUP_UUID] = email.uuid.uuid;
    }

    kdbxSave(kdbx);
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

      final kdbx = Kdbx.create(
        credentials: credentials,
        name: RpassInfo.defaultKdbxName,
      );

      kdbx.filepath = store.localInfo.localKdbxFile.path;
      _addPresetGroup(kdbx);

      if (store.settings.enableRecordKeyFilePath) {
        await store.settings.setKeyFilePath(keyFile?.$1);
      }

      KdbxProvider.setKdbx(context, kdbx);
      context.router.replace(HomeRoute());
    }
  }

  @override
  Future<void> importKdbx() async {
    // 安卓不支持指定 kdbx 后缀
    final file = await SimpleFile.openFile(
      allowedExtensions: !Platform.isAndroid ? ["kdbx"] : null,
    );

    if (!file.$1.endsWith(".kdbx")) {
      throw Exception("Invalid file extension");
    }

    final result = await context.router.push(LoadExternalKdbxRoute(
      kdbxFile: file.$2,
      kdbxFilePath: file.$1,
    ));

    if (result != null && result is (Kdbx, String?)) {
      final store = StoreProvider.of(context);

      final kdbx = result.$1;
      kdbx.filepath = store.localInfo.localKdbxFile.path;
      _addPresetGroup(kdbx);

      if (store.settings.enableRecordKeyFilePath) {
        await store.settings.setKeyFilePath(result.$2);
      }

      KdbxProvider.setKdbx(context, kdbx);
      context.router.replace(HomeRoute());
    }
  }
}
