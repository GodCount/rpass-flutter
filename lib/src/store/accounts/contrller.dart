import 'package:flutter/material.dart';

import '../../util/common.dart';
import '../index.dart';
import './service.dart';
import '../../model/rpass/backup.dart';
import '../../model/rpass/account.dart';

class AccountsContrller with ChangeNotifier {
  AccountsContrller();

  late Store _store;

  final AccountsService _accountsService = AccountsService();

  List<Account>? _accountList;

  final Set<String> emailSet = {};
  final Set<String> accountNumSet = {};
  final Set<String> labelSet = {};

  List<Account> get accountList => _accountList ?? [];


  void _updateSet([List<Account>? accounts]) {
    assert(_accountList != null, "_accountList is null, to run initDenrypt");

    if (accounts == null) {
      emailSet.clear();
      accountNumSet.clear();
      labelSet.clear();
    }

    for (var account in accounts ?? _accountList!) {
      emailSet.add(account.email);
      accountNumSet.add(account.account);
      labelSet.addAll(account.labels);
    }
  }

  Future<void> initDenrypt() async {
    assert(_store.verify.token != null, "token is null, to verify password");

    if (_accountList != null) return;

    _accountList = await _accountsService.getAccountList(_store.verify.token!);

    _updateSet();
  }

  Future<void> addAccounts(List<Account> accounts) async {
    assert(_accountList != null, "_accountList is null, to run initDenrypt");

    _accountList!.insertAll(0, accounts);

    _updateSet(accounts);

    notifyListeners();

    await _accountsService.setAccountList(_store.verify.token!, _accountList!);
  }

  Future<void> addAccount(Account account) async {
    assert(_accountList != null, "_accountList is null, to run initDenrypt");

    _accountList!.insert(0, account);

    _updateSet([account]);

    notifyListeners();

    await _accountsService.setAccountList(_store.verify.token!, _accountList!);
  }

  Future<void> setAccount(Account account) async {
    assert(_accountList != null, "_accountList is null, to run initDenrypt");

    final index =
        _accountList!.indexWhere((Account item) => item.id == account.id);

    if (index < 0) return await addAccount(account);

    _accountList![index] = account;

    _updateSet();

    notifyListeners();

    await _accountsService.setAccountList(_store.verify.token!, _accountList!);
  }

  Future<void> removeAccount(String id) async {
    assert(_accountList != null, "_accountList is null, to run initDenrypt");

    test(Account item) => item.id == id;

    if (!_accountList!.any(test)) return;

    _accountList!.removeWhere(test);

    _updateSet();

    notifyListeners();

    await _accountsService.setAccountList(_store.verify.token!, _accountList!);
  }

  bool hasAccountById(String id) {
    assert(_accountList != null, "_accountList is null, to run initDenrypt");
    return _accountList!.any((item) => item.id == id);
  }

  Account getAccountById(String id) {
    assert(_accountList != null, "_accountList is null, to run initDenrypt");
    return _accountList!.lastWhere((item) => item.id == id);
  }

  Future<void> importBackupAccounts(Backup backup) async {
    if (backup.accounts.isEmpty) return;
    final localIds = accountList.map((item) => item.id).toList();
    final result = backup.accounts.map((item) {
      if (localIds.contains(item.id)) {
        item.id = timeBasedUuid();
      }
      localIds.add(item.id);
      return item;
    }).toList();
    await addAccounts(result);
  }

  Future<void> updateToken() async {
    assert(_accountList != null, "_accountList is null, to run initDenrypt");

    await _accountsService.setAccountList(_store.verify.token!, _accountList!);
  }

  Future<void> init(Store store) async {
    _store = store;
  }
}
