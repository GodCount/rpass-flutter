import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../util/common.dart';

part 'question.g.dart';

class QuestionAnswer {
  QuestionAnswer(this.question, this.answer);

  late String question;
  late String answer;
}

@JsonSerializable(explicitToJson: true)
class QuestionAnswerKey {
  QuestionAnswerKey(this.question, {String? answer, String? answerKey}) {
    if (answer != null) {
      this.answerKey = aesEncrypt(md5(answer), question);
    } else if (answerKey != null) {
      this.answerKey = answerKey;
    } else {
      throw Exception("need of answer or answerKey");
    }
  }

  final String question;
  late final String answerKey;

  factory QuestionAnswerKey.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$QuestionAnswerKeyFromJson(json);

  Map<String, dynamic> toJson() => _$QuestionAnswerKeyToJson(this);

  bool verify(String answer) {
    try {
      return aesDenrypt(md5(answer), answerKey) == question;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return false;
    }
  }
}
