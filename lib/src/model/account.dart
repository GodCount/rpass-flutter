import 'package:json_annotation/json_annotation.dart';

import '../util/common.dart';

part 'account.g.dart';

class JsonDateTimeConverterNonNullable implements JsonConverter<DateTime, int> {
  const JsonDateTimeConverterNonNullable();

  @override
  DateTime fromJson(int timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: false);
  }

  @override
  int toJson(DateTime object) {
    return object.millisecondsSinceEpoch;
  }
}

@JsonSerializable(explicitToJson: true)
class Account {
  Account(
      {String? id,
      DateTime? date,
      required this.domain,
      required this.domainName,
      required this.account,
      required this.password,
      required this.email,
      String? description,
      List<String>? labels,
      this.oneTimePassword})
      : id = id ?? timeBasedUuid(),
        date = date ?? DateTime.timestamp(),
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

  factory Account.fromEmpty() => Account(
        domain: "",
        domainName: "",
        account: "",
        password: "",
        email: "",
      );

  factory Account.fromJson(
    Map<String, dynamic> json,
  ) =>
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
