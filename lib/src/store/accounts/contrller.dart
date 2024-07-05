import 'package:flutter/material.dart';

import '../index.dart';
import './service.dart';
import '../../model/account.dart';

class AccountsContrller with ChangeNotifier {
  AccountsContrller();

  late Store _store;

  final AccountsService _accountsService = AccountsService();

  List<Account>? _accountList;

  List<Account> get accountList => _accountList ?? [];

  Future<void> initDenrypt() async {
    assert(_store.verify.token != null, "token is null, to verify password");

    if (_accountList != null) return;

    _accountList = await _accountsService.getAccountList(_store.verify.token!);
  }

  Future<void> addAccount(Account account) async {
    assert(_accountList != null, "_accountList is null, to run initDenrypt");

    _accountList!.add(account);

    notifyListeners();

    await _accountsService.setAccountList(_store.verify.token!, _accountList!);
  }

  Future<void> modifyAccount(Account account) async {
    assert(_accountList != null, "_accountList is null, to run initDenrypt");


    final index = _accountList!.indexWhere((Account item) => item.id == account.id);

    if (index < 0) return await addAccount(account);

    _accountList![index] = account;

    notifyListeners();

    await _accountsService.setAccountList(_store.verify.token!, _accountList!);
  }

  Future<void> removeAccount(String id) async {
    assert(_accountList != null, "_accountList is null, to run initDenrypt");

    test(Account item) => item.id == id;

    if (!_accountList!.any(test)) return;

    _accountList!.removeWhere(test);

    notifyListeners();

    await _accountsService.setAccountList(_store.verify.token!, _accountList!);
  }

  Future<void> updateToken() async {
    assert(_accountList != null, "_accountList is null, to run initDenrypt");

    await _accountsService.setAccountList(_store.verify.token!, _accountList!);
  }

  Future<void> init(Store store) async {
    _store = store;
  }
}
