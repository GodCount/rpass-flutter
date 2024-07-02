import '../util/common.dart';

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