// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Account _$AccountFromJson(Map<String, dynamic> json) => Account(
      id: json['id'] as String?,
      date: _$JsonConverterFromJson<int, DateTime>(
          json['date'], const JsonDateTimeConverterNonNullable().fromJson),
      domain: json['domain'] as String,
      domainName: json['domainName'] as String,
      account: json['account'] as String,
      password: json['password'] as String,
      email: json['email'] as String,
      description: json['description'] as String?,
      labels:
          (json['labels'] as List<dynamic>?)?.map((e) => e as String).toList(),
      oneTimePassword: json['oneTimePassword'] as String?,
    );

Map<String, dynamic> _$AccountToJson(Account instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'date': const JsonDateTimeConverterNonNullable().toJson(instance.date),
    'domain': instance.domain,
    'domainName': instance.domainName,
    'account': instance.account,
    'password': instance.password,
    'email': instance.email,
    'description': instance.description,
    'labels': instance.labels,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('oneTimePassword', instance.oneTimePassword);
  return val;
}

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);
