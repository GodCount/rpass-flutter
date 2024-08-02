// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firefox.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FirefoxAccount _$FirefoxAccountFromJson(Map<String, dynamic> json) =>
    FirefoxAccount(
      url: json['url'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      httpRealm: json['httpRealm'] as String?,
      formActionOrigin: json['formActionOrigin'] as String,
      guid: const GuidConverter().fromJson(json['guid'] as String),
      timeCreated: const JsonDateTimeConverterNonNullable()
          .fromJson(json['timeCreated']),
      timeLastUsed: const JsonDateTimeConverterNonNullable()
          .fromJson(json['timeLastUsed']),
      timePasswordChanged: const JsonDateTimeConverterNonNullable()
          .fromJson(json['timePasswordChanged']),
    );

Map<String, dynamic> _$FirefoxAccountToJson(FirefoxAccount instance) {
  final val = <String, dynamic>{
    'url': instance.url,
    'username': instance.username,
    'password': instance.password,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('httpRealm', instance.httpRealm);
  val['formActionOrigin'] = instance.formActionOrigin;
  val['guid'] = const GuidConverter().toJson(instance.guid);
  writeNotNull('timeCreated',
      const JsonDateTimeConverterNonNullable().toJson(instance.timeCreated));
  writeNotNull('timeLastUsed',
      const JsonDateTimeConverterNonNullable().toJson(instance.timeLastUsed));
  writeNotNull(
      'timePasswordChanged',
      const JsonDateTimeConverterNonNullable()
          .toJson(instance.timePasswordChanged));
  return val;
}
