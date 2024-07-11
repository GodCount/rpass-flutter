import '../model/question.dart';
import 'common.dart';

class VerifyCore {
  // ignore: constant_identifier_names
  static const String VERIFY_TEXT = "done";

  static (String, String) createToken(String password) {
    final token = md5(password);
    return (token, createPasswordAes(token));
  }

  static String createPasswordAes(String token) {
    return aesEncrypt(token, VERIFY_TEXT);
  }

  static String createQuestionAes(
      {required String token, required List<QuestionAnswer> questions}) {
    return aesEncrypt(md5(questions.map((item) => item.answer).join()), token);
  }

  static String createQuestionAesByKey(
      {required String token, required List<QuestionAnswerKey> questions}) {
    return aesEncrypt(
        md5(questions.map((item) => item.answerKey).join()), token);
  }

  static String verify({
    required String password,
    required String passwordAes,
  }) {
    final token = md5(password);

    if (aesDenrypt(token, passwordAes) == VERIFY_TEXT) {
      return token;
    }
    throw Exception("Password Error!");
  }

  static String verifyQuestion({
    required List<QuestionAnswer> questions,
    required String questionAes,
    required String passwordAes,
  }) {
    final token = aesDenrypt(
        md5(questions.map((item) => item.answer).join()), questionAes);

    if (aesDenrypt(token, passwordAes) == VERIFY_TEXT) {
      return token;
    }

    throw Exception("question verify error");
  }
}
