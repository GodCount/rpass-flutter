import 'dart:convert';

import '../../util/common.dart';
import '../shared_preferences/index.dart';
import '../../model/account.dart';

class AccountsService with SharedPreferencesService {
  Future<List<Account>> getAccountList(String token) async {
    final list = await getStringList("account_list");

    if (list == null) return [];

    return aesDenryptList(token, list)
        .map((item) => Account.fromJson(json.decode(item)))
        .toList();
  }

  Future<bool> setAccountList(String token, List<Account> accounts) {
    return setStringList(
        "account_list",
        aesDenryptList(token, accounts.map((item) => json.encode(item)))
            .toList());
  }
}
