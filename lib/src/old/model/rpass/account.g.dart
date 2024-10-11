// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Account _$AccountFromJson(Map<String, dynamic> json) => Account(
      id: json['id'] as String?,
      date: const JsonDateTimeConverterNonNullable().fromJson(json['date']),
      domain: json['domain'] as String?,
      domainName: json['domainName'] as String?,
      account: json['account'] as String?,
      password: json['password'] as String?,
      email: json['email'] as String?,
      description: json['description'] as String?,
      labels:
          (json['labels'] as List<dynamic>?)?.map((e) => e as String).toList(),
      oneTimePassword: json['oneTimePassword'] as String?,
    );

Map<String, dynamic> _$AccountToJson(Account instance) {
  final val = <String, dynamic>{
    'id': instance.id,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(
      'date', const JsonDateTimeConverterNonNullable().toJson(instance.date));
  val['domain'] = instance.domain;
  val['domainName'] = instance.domainName;
  val['account'] = instance.account;
  val['password'] = instance.password;
  val['email'] = instance.email;
  val['description'] = instance.description;
  val['labels'] = instance.labels;
  writeNotNull('oneTimePassword', instance.oneTimePassword);
  return val;
}
