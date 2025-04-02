import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../kdbx/kdbx.dart';
import '../../util/route.dart';
import 'authorized_page.dart';

@Deprecated(
  '使用构造函数传参'
  '弃用 Arguments 路由传参',
)
class LoadExternalKdbxPageArguments {
  LoadExternalKdbxPageArguments({
    required this.kdbxFile,
    this.kdbxFilePath,
  });

  final Uint8List kdbxFile;
  final String? kdbxFilePath;
}

class _LoadExternalKdbxArgs extends PageRouteArgs {
  _LoadExternalKdbxArgs({
    super.key,
    required this.kdbxFile,
    this.kdbxFilePath,
  });

  final Uint8List kdbxFile;
  final String? kdbxFilePath;
}

class LoadExternalKdbxRoute extends PageRouteInfo<_LoadExternalKdbxArgs> {
  LoadExternalKdbxRoute({
    Key? key,
    required Uint8List kdbxFile,
    String? kdbxFilePath,
  }) : super(
          name,
          args: _LoadExternalKdbxArgs(
            key: key,
            kdbxFile: kdbxFile,
            kdbxFilePath: kdbxFilePath,
          ),
        );

  static const name = "LoadExternalKdbxRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_LoadExternalKdbxArgs>();
      return LoadExternalKdbxPage(
        key: args.key,
        kdbxFile: args.kdbxFile,
      );
    },
  );
}

class LoadExternalKdbxPage extends AuthorizedPage {
  const LoadExternalKdbxPage({
    super.key,
    required this.kdbxFile,
  });

  final Uint8List kdbxFile;

  @override
  AuthorizedPageState<LoadExternalKdbxPage> createState() =>
      _LoadExternalKdbxPageState();
}

class _LoadExternalKdbxPageState
    extends AuthorizedPageState<LoadExternalKdbxPage> {
  @override
  AuthorizedType get authType => AuthorizedType.load;

  @override
  bool get enableBack => true;

  @override
  bool get readHistoryKeyFile => false;

  @override
  Future<void> confirm() async {
    if (form.currentState!.validate()) {
      final passowrd = passwordController.text;
      final keyFile = keyFilecontroller.keyFile;

      if (!isPassword && keyFile == null) {
        throw Exception("Lack of key file.");
      }

      Kdbx kdbx = await Kdbx.loadBytesFromCredentials(
        data: widget.kdbxFile,
        credentials:
            Kdbx.createCredentials(isPassword ? passowrd : null, keyFile?.$2),
      );
      context.router.pop((kdbx, keyFile?.$1));
    }
  }
}
