import 'common.dart';
import '../model/rpass/question.dart';

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
      {required String token, required List<QuestionAnswerKey> questions}) {
    return aesEncrypt(
        md5(questions.map((item) => item.answerKey).join()), token);
  }

  static String verify({
    required String password,
    required String passwordAes,
  }) {
    return verifyToken(token: md5(password), passwordAes: passwordAes);
  }

  static String verifyToken({
    required String token,
    required String passwordAes,
  }) {
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
        md5(questions
            .map(
                (item) => QuestionAnswerKey(item.question, answer: item.answer).answerKey)
            .join()),
        questionAes);

    if (aesDenrypt(token, passwordAes) == VERIFY_TEXT) {
      return token;
    }

    throw Exception("question verify error");
  }
}
