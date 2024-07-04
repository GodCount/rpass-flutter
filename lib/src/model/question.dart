import 'package:flutter/foundation.dart';

import '../util/common.dart';

class QuestionAnswer {
  QuestionAnswer(this.question, this.answer);

  late String question;
  late String answer;
}

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
