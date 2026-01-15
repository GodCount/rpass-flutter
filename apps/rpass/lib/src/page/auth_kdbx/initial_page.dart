import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../context/kdbx.dart';
import '../../i18n.dart';
import '../../remotes_fs/adapter/webdav.dart';
import '../../store/index.dart';
import '../../util/file.dart';
import '../../util/route.dart';
import '../route.dart';
import 'authorized_page.dart';
import '../../widget/extension_state.dart';
import '../../kdbx/kdbx.dart';
import '../../rpass.dart';

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
      final args = data.argsAs<_InitialArgs>(
        orElse: () => _InitialArgs(),
      );
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

  @override
  bool get enableRemoteImport => true;

  void _addPresetGroup(Kdbx kdbx) {
    final t = I18n.of(context)!;

    if (kdbx.kdbxFile.body.rootGroup.name.get() != t.default_) {
      kdbx.kdbxFile.body.rootGroup.name.set(t.default_);
    }

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
  }

  Future<void> _setInitKdbx(
    (Kdbx, String?) result, [
    bool initPresetGroup = false,
  ]) async {
    final store = Store.instance;

    final kdbx = result.$1;
    kdbx.filepath = store.localInfo.localKdbxFile.path;
    if (initPresetGroup) {
      _addPresetGroup(kdbx);
    }

    await kdbxSave(kdbx);

    if (store.settings.enableRecordKeyFilePath) {
      await store.settings.setKeyFilePath(result.$2);
    }

    KdbxProvider.setKdbx(context, kdbx);
    context.router.replace(HomeRoute());
  }

  @override
  Future<void> confirm() async {
    if (form.currentState!.validate()) {
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

      await _setInitKdbx((kdbx, keyFile?.$1), true);
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
      await _setInitKdbx(result);
    }
  }

  @override
  Future<void> importKdbxByWebDav() async {
    // 登录 webdav
    final result = await context.router.push(AuthRemoteFsRoute(
      config: WebdavConfig(),
      type: AuthRemoteRouteType.import,
    ));

    if (result != null && result is WebdavClient) {
      // 导入 kdbx 文件
      final result2 = await context.router.push(ImportRemoteKdbxRoute(
        client: result,
      ));

      if (result2 != null && result2 is (Kdbx, String?)) {
        await _setInitKdbx(result2);
      }
    }
  }
}
