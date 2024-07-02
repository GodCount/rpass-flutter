import 'dart:convert';

import '../../model/question.dart';
import '../shared_preferences/index.dart';

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
