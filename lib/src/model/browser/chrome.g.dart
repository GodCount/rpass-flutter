// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chrome.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChromeAccount _$ChromeAccountFromJson(Map<String, dynamic> json) =>
    ChromeAccount(
      name: json['name'] as String,
      url: json['url'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      note: json['note'] as String? ?? "",
    );

Map<String, dynamic> _$ChromeAccountToJson(ChromeAccount instance) =>
    <String, dynamic>{
      'name': instance.name,
      'url': instance.url,
      'username': instance.username,
      'password': instance.password,
      'note': instance.note,
    };
