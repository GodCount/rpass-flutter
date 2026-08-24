import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:keepass_core/keepass_core.dart';
import 'package:remote_fs/remote_fs.dart';

import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../remotes_fs/remote_fs.dart';
import '../../store/index.dart';
import '../../util/file.dart';
import '../../util/route.dart';
import '../../widget/extension_state.dart';
import '../route.dart';
import 'authorized_page.dart';

class _InitialArgs extends PageRouteArgs {
  _InitialArgs({super.key});
}

class InitialRoute extends PageRouteInfo<_InitialArgs> {
  InitialRoute({Key? key}) : super(name, args: _InitialArgs(key: key));

  static const name = "InitialRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_InitialArgs>(orElse: () => _InitialArgs());
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

  Future<void> _setInitKdbx(
    (Kdbx, String?) result, [
    RemoteFileConfig? config,
  ]) async {
    final t = I18n.of(context)!;
    final kdbx = result.$1;

    if (Store.settings.enableRecordKeyFilePath) {
      await Store.settings.setKeyFilePath(result.$2);
    }

    await Store.kdbx.setKdbx(kdbx);
    await kdbx.setFilepath(filepath: Store.localInfo.localKdbxFile.path);

    if (config != null &&
        (await Store.kdbx.getSyncEntryData()) == null &&
        await showConfirmDialog(
          title: t.save,
          message: t.save_sync_account_subtitle,
        )) {
      final entry = kdbx.newEntry()
        ..fields[KdbxKeyCommon.TITLE] = FieldValue.plaintext(t.sync_config);

      for (final item in config.toKdbx().entries) {
        entry.fields[item.key] = item.value;
      }

      await kdbxAction(KdbxAction.updateSyncEntry(entry));
    }

    await kdbx.saveFile();

    context.router.replace(HomeRoute());
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

      final kdbx = Kdbx.create(
        credentials: credentials,
        filepath: Store.localInfo.localKdbxFile.path,
      );

      await _setInitKdbx((kdbx, keyFile?.$1));
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

    final result = await context.router.push(
      LoadExternalKdbxRoute(kdbxFile: file.$2, kdbxFilePath: file.$1),
    );

    if (result != null && result is (Kdbx, String?)) {
      await _setInitKdbx(result);
    }
  }

  @override
  Future<void> importKdbxByRemote(RemoteType type) async {
    // 登录 webdav
    final result = await context.router.push(AuthRemoteFsRoute(type: type));

    if (result != null && result is RemoteFileConfig) {
      // 导入 kdbx 文件
      final result2 = await context.router.push(
        SelectRemoteFileRoute(config: result, importKdbx: true),
      );

      if (result2 != null && result2 is (RemoteFileConfig, (Kdbx, String?))) {
        await _setInitKdbx(result2.$2, result2.$1);
      }
    }
  }
}
