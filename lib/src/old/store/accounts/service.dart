import 'dart:convert';

import '../../../store/shared_preferences/index.dart';
import '../../../util/common.dart';

class AccountsService with SharedPreferencesService {
  Future<int> getAccountListCount() async {
    return (await getStringList("account_list"))?.length ?? 0;
  }

  Future<List<Map<String, dynamic>>> getAccountList(String token) async {
    final list = await getStringList("account_list");

    if (list == null) return [];

    return aesDenryptList(token, list)
        .map((item) => json.decode(item) as Map<String, dynamic>)
        .toList();
  }

  @override
  Future<bool> clear() {
    return remove("account_list");
  }
}
