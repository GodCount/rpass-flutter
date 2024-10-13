import 'package:flutter/material.dart';

import './service.dart';

class AccountsContrller with ChangeNotifier {
  AccountsContrller();

  final AccountsService _accountsService = AccountsService();

  List<Map<String, dynamic>>? _accountList;
  int _accountListCount = 0;

  List<Map<String, dynamic>> get accountList => _accountList ?? [];
  bool get isExistAccount => _accountListCount > 0;

  Future<List<Map<String, dynamic>>> denrypt(String token) async {
    _accountList = await _accountsService.getAccountList(token);
    return _accountList!;
  }

  Future<void> clear() async {
    await _accountsService.clear();
    _accountListCount = 0;
    _accountList = null;
  }

  Future<void> init() async {
    _accountListCount = await _accountsService.getAccountListCount();
  }
}
