import 'package:flutter/material.dart';

import './service.dart';
import '../../model/account.dart';

class AccountsContrller with ChangeNotifier {
  AccountsContrller(this._accountsService);

  final AccountsService _accountsService;

  String? _token;

  List<Account>? _accountList;

  List<Account> get accountList => _accountList ?? [];

  Future<void> initDenrypt(String token) async {
    if (_accountList != null) return;
    _accountList = await _accountsService.getAccountList(token);
    _token = token;
    notifyListeners();
  }

  Future<void> addAccount(Account account) async {
    assert(_accountList != null, "_accountList is null, to run initDenrypt");
    assert(_token != null, "_token is null, to run initDenrypt");

    _accountList!.add(account);

    notifyListeners();

    await _accountsService.setAccountList(_token!, _accountList!);
  }

  Future<void> removeAccount(String id) async {
    assert(_accountList != null, "_accountList is null, to run initDenrypt");
    assert(_token != null, "_token is null, to run initDenrypt");

    test(Account item) => item.id == id;

    if (!_accountList!.any(test)) return;

    _accountList!.removeWhere(test);

    notifyListeners();

    await _accountsService.setAccountList(_token!, _accountList!);
  }

  Future<void> updateToken(String token) async {
    assert(_accountList != null, "_accountList is null, to run initDenrypt");
    assert(_token != null, "_token is null, to run initDenrypt");

    if (_token == token) return;

    _token = token;

    await _accountsService.setAccountList(_token!, _accountList!);
  }
}
