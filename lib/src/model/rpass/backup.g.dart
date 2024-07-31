// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Backup _$BackupFromJson(Map<String, dynamic> json) => Backup(
      accounts: (json['accounts'] as List<dynamic>)
          .map((e) => Account.fromJson(e as Map<String, dynamic>))
          .toList(),
      version: json['__version__'] as String,
      buildNumber: json['__build_number__'] as String,
    );

Map<String, dynamic> _$BackupToJson(Backup instance) => <String, dynamic>{
      'accounts': instance.accounts,
      '__version__': instance.version,
      '__build_number__': instance.buildNumber,
    };

EncryptBackup _$EncryptBackupFromJson(Map<String, dynamic> json) =>
    EncryptBackup(
      accounts: json['accounts'] as String,
      passwordVerify: json['__password_verify__'] as String,
      version: json['__version__'] as String,
      buildNumber: json['__build_number__'] as String,
      questions: (json['questions'] as List<dynamic>?)
          ?.map((e) => QuestionAnswerKey.fromJson(e as Map<String, dynamic>))
          .toList(),
      questionsToken: json['__questions_token__'] as String?,
    );

Map<String, dynamic> _$EncryptBackupToJson(EncryptBackup instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('questions', instance.questions);
  val['accounts'] = instance.accounts;
  writeNotNull('__questions_token__', instance.questionsToken);
  val['__password_verify__'] = instance.passwordVerify;
  val['__version__'] = instance.version;
  val['__build_number__'] = instance.buildNumber;
  return val;
}
