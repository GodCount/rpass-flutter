import 'dart:io';

import 'package:json_annotation/json_annotation.dart';

import '../common.dart';
import 'browser.dart';
import '../../util/common.dart';
import '../rpass/account.dart';

part 'chrome.g.dart';

@JsonSerializable(explicitToJson: true)
class ChromeAccount extends BrowserAccount {
  ChromeAccount({
    required this.name,
    required this.url,
    required this.username,
    required this.password,
    this.note = "",
  });

  @JsonUrlConverter()
  String name;

  @JsonUrlConverter()
  String url;

  String username;

  String password;

  String note;

  static List<ChromeAccount> fromCsv(String csv) {
    return csvToJson(
      csv,
      shouldParseNumbers: false,
      eol: !Platform.isWindows ? "\n" : null,
    ).map((item) => ChromeAccount.fromJson(item)).toList();
  }

  static List<Account> toAccounts(List<ChromeAccount> list) {
    return list.map((item) => item.toAccount()).toList();
  }

  static String toCsv(List<Account> list) {
    return jsonToCsv(
        list.map((item) => ChromeAccount.formAccount(item).toJson()).toList());
  }

  factory ChromeAccount.fromJson(Map<String, dynamic> json) {
    return _$ChromeAccountFromJson(json);
  }

  factory ChromeAccount.formAccount(Account account) {
    return ChromeAccount(
      name: account.domain,
      url: account.domain,
      username: account.account,
      password: account.password,
      note: account.description,
    );
  }

  Map<String, dynamic> toJson() => _$ChromeAccountToJson(this);

  @override
  Account toAccount() {
    return Account(
      domain: name,
      domainName: "",
      account: username,
      password: password,
      email: CommonRegExp.email.hasMatch(username) ? username : "",
      description: note,
      labels: ["Chrome"],
    );
  }
}
