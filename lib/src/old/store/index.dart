

import 'package:flutter/material.dart';

import '../../page/page.dart';
import 'accounts/contrller.dart';
import 'verify/contrller.dart';

final class OldStore {
  static OldStore? _instance;

  factory OldStore() => _instance ?? OldStore._internal();

  OldStore._internal() {
    _instance = this;
  }

  final accounts = AccountsContrller();
  final verify = VerifyController();

  Future<void> migrate(BuildContext context, String token) async {
    final accountList = await accounts.denrypt(token);
    await Navigator.of(context).popAndPushNamed(InitKdbxPage.routeName);
    // TODO!
  }

  Future<void> loadStore() async {
    await accounts.init();
    await verify.init();
  }
}
