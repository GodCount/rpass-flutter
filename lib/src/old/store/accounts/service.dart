import 'dart:convert';

import '../../../store/shared_preferences/index.dart';
import '../../../util/common.dart';
import '../../model/rpass/account.dart';



class AccountsService with SharedPreferencesService {


  Future<int> getAccountListCount() async {
    return (await getStringList("account_list"))?.length ?? 0;
  }

  Future<List<Account>> getAccountList(String token) async {
    final list = await getStringList("account_list");

    if (list == null) return [];

    return aesDenryptList(token, list)
        .map((item) => Account.fromJson(json.decode(item)))
        .toList();
  }

    @override
  Future<bool> clear() {
    return remove("account_list");
  }
}
