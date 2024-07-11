import 'package:json_annotation/json_annotation.dart';

import 'account.dart';
import 'question.dart';

part 'backup.g.dart';


@JsonSerializable()
class Backup {
  const Backup({
    required this.accounts,
    required this.version,
    required this.buildNumber,
  });

  final List<Account> accounts;

  @JsonKey(name: "__version__")
  final String version;
  @JsonKey(name: "__build_number__")
  final String buildNumber;

  factory Backup.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$BackupFromJson(json);

  Map<String, dynamic> toJson() => _$BackupToJson(this);
}

@JsonSerializable()
class EncryptBackup {
  const EncryptBackup({
    required this.accounts,
    required this.passwordVerify,
    required this.version,
    required this.buildNumber,
    this.questions,
    this.questionsToken,
  });

  final List<QuestionAnswerKey>? questions;
  final String accounts;

  @JsonKey(name: "__questions_token__")
  final String? questionsToken;
  @JsonKey(name: "__password_verify__")
  final String passwordVerify;

  @JsonKey(name: "__version__")
  final String version;
  @JsonKey(name: "__build_number__")
  final String buildNumber;

  factory EncryptBackup.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$EncryptBackupFromJson(json);

  Map<String, dynamic> toJson() => _$EncryptBackupToJson(this);
}
