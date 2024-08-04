import 'package:json_annotation/json_annotation.dart';

import '../../util/common.dart';
import '../common.dart';

part 'account.g.dart';

@JsonSerializable(explicitToJson: true)
class Account {
  Account({
    String? id,
    DateTime? date,
    String? domain,
    String? domainName,
    String? account,
    String? password,
    String? email,
    String? description,
    List<String>? labels,
    this.oneTimePassword,
  })  : id = id ?? timeBasedUuid(),
        date = date ?? DateTime.now(),
        domain = domain ?? "",
        domainName = domainName ?? "",
        account = account ?? "",
        password = password ?? "",
        email = email ?? "",
        description = description ?? "",
        labels = labels ?? [];

  String id;

  @JsonDateTimeConverterNonNullable()
  DateTime date;

  String domain;

  String domainName;

  String account;

  String password;

  String email;

  String description;

  List<String> labels;

  String? oneTimePassword;

  String get hash => md5(
      "$domain$domainName$account$password$email$description${oneTimePassword ?? ""}");

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);

  Map<String, dynamic> toJson() => _$AccountToJson(this);

  Account clone() => Account(
        id: id,
        date: date,
        domain: domain,
        domainName: domainName,
        account: account,
        password: password,
        email: email,
        description: description,
        labels: labels,
        oneTimePassword: oneTimePassword,
      );
}
