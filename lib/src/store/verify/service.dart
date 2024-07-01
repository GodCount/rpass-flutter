import 'dart:convert';

import '../../util/common.dart';
import '../shared_preferences/index.dart';

class Question {
  Question(this.question, {String? answer, String? answerKey}) {
    if (answer != null) {
      this.answer = answer;
    }

    if (answerKey == null && answer != null) {
      this.answerKey = md5(answer);
    } else if (answerKey != null) {
      this.answerKey = answerKey;
    }
  }

  late String question;
  late String? answer;
  late String answerKey;

  bool verify() => answer != null && md5(answer!) == answerKey;
}

class VerifyService with SharedPreferencesService {
  Future<String?> getPasswordAes() async => await getString("password_str");

  Future<bool> setPasswordAes(String str) => setString("password_str", str);

  Future<String?> getQuestionTokenAes() async =>
      await getString("question_token_str");

  Future<bool> setQuestionTokenAes(String str) =>
      setString("question_token_str", str);

  Future<List<Question>?> getQuestionList() async {
    final question = await getStringList("question_list");

    if (question == null) return null;

    return question.map((str) {
      final [q, k] = str.split(":");
      return Question(utf8.decode(base64.decode(q)), answerKey: k);
    }).toList();
  }

  Future<bool> setQuestionList(List<Question> list) {
    return setStringList(
        "question_list",
        list
            .map((item) =>
                "${base64.encode(utf8.encode(item.question))}:${item.answerKey}")
            .toList());
  }
}
