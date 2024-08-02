import 'package:json_annotation/json_annotation.dart';
import 'package:rpass/src/model/rpass/account.dart';

import '../common.dart';
import '../../util/common.dart';
import 'browser.dart';

part 'firefox.g.dart';

class GuidConverter implements JsonConverter<String, String> {
  const GuidConverter();

  @override
  String fromJson(String json) {
    if (json.startsWith("{")) {
      json = json.substring(1);
    }
    if (json.endsWith("}")) {
      json = json.substring(0, json.length - 1);
    }
    return json;
  }

  @override
  String toJson(String object) {
    return "{$object}";
  }
}

@JsonSerializable(explicitToJson: true)
class FirefoxAccount extends BrowserAccount {
  FirefoxAccount({
    required this.url,
    required this.username,
    required this.password,
    this.httpRealm,
    required this.formActionOrigin,
    required this.guid,
    required this.timeCreated,
    required this.timeLastUsed,
    required this.timePasswordChanged,
  });

  String url;

  String username;

  String password;

  String? httpRealm;

  String formActionOrigin;

  @GuidConverter()
  String guid;

  @JsonDateTimeConverterNonNullable()
  DateTime timeCreated;

  @JsonDateTimeConverterNonNullable()
  DateTime timeLastUsed;

  @JsonDateTimeConverterNonNullable()
  DateTime timePasswordChanged;

  static List<FirefoxAccount> fromCsv(String csv) {
    return csvToJson(csv).map((item) => FirefoxAccount.fromJson(item)).toList();
  }

  static List<Account> toAccounts(List<FirefoxAccount> list) {
    return list.map((item) => item.toAccount()).toList();
  }

  static String toCsv(List<Account> list) {
    return jsonToCsv(
        list.map((item) => FirefoxAccount.formAccount(item).toJson()).toList());
  }

  factory FirefoxAccount.fromJson(Map<String, dynamic> json) {
    return _$FirefoxAccountFromJson(json);
  }

  factory FirefoxAccount.formAccount(Account account) {
    return FirefoxAccount(
      url: account.domain,
      username: account.account,
      password: account.password,
      formActionOrigin: account.domain,
      guid: account.id,
      timeCreated: account.date,
      timeLastUsed: DateTime.now(),
      timePasswordChanged: DateTime.now()
    );
  }

  Map<String, dynamic> toJson() => _$FirefoxAccountToJson(this);

  @override
  Account toAccount() {
    return Account(
      id: guid,
      date: timeCreated,
      domain: url,
      domainName: "",
      account: username,
      password: password,
      email: CommonRegExp.email.hasMatch(username) ? username : "",
      description: "",
      labels: ["Firefox"],
    );
  }
}
