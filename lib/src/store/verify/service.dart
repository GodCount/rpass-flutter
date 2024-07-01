import 'dart:convert';

import '../../util/common.dart';
import '../shared_preferences/index.dart';

class Question {
  Question(this.Q, this.A, [String? aKey]) {
    if (aKey == null) {
      this.aKey = md5(A);
    } else {
      this.aKey = aKey;
    }
  }

  final String Q;
  final String A;
  late final String aKey;
}

class VerifyService with SharedPreferencesService {
  Future<String?> getPasswordAes() async => await getString("password_str");

  Future<bool> setPasswordAes(String str) => setString("password_str", str);

  Future<String?> getQuestionByPasswordToken() async =>
      await getString("question_by_password_token");

  Future<bool> setQuestionByPasswordToken(String str) =>
      setString("question_by_password_token", str);

  Future<List<Question>?> getQuestionList() async {
    final question = await getStringList("question_list");
    
    if (question == null) return null;

    // return question.map((str) {
    //   // final a = base64.encode(str).split("");
    //   return Question("Q", "A")
    // });
  }
}
