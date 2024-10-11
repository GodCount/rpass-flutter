import 'package:flutter/material.dart';

import '../../model/rpass/account.dart';
import './service.dart';

class AccountsContrller with ChangeNotifier {
  AccountsContrller();

  final AccountsService _accountsService = AccountsService();

  List<Account>? _accountList;
  int _accountListCount = 0;

  List<Account> get accountList => _accountList ?? [];
  bool get isExistAccount => _accountListCount > 0;

  Future<List<Account>> denrypt(String token) async {
    _accountList = await _accountsService.getAccountList(token);
    return _accountList!;
  }

  Future<void> clear() async {
    await _accountsService.clear();
  }

  Future<void> init() async {
    _accountListCount = await _accountsService.getAccountListCount();
  }
}
