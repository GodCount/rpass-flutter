import 'package:flutter/material.dart';

import '../../../util/common.dart';
import '../../model/rpass/question.dart';
import 'service.dart';

class VerifyController with ChangeNotifier {
  VerifyController();

  final VerifyService _verifyService = VerifyService();

  late String? _questionTokenAes;

  late List<QuestionAnswerKey> _questionList;

  List<QuestionAnswerKey> get questionList => _questionList;

  bool get isExistQuestion =>
      _questionTokenAes != null &&
      _questionTokenAes!.isNotEmpty &&
      _questionList.isNotEmpty;

  String forgotToVerifyQuestion(List<QuestionAnswer> questions) {
    assert(_questionTokenAes != null, "questionTokenAes is null");

    return aesDenrypt(
      md5(questions.map((item) => item.answer).join()),
      _questionTokenAes!,
    );
  }

  Future<void> clear() async {
    await _verifyService.clear();
    _questionTokenAes = null;
    _questionList = [];
  }

  Future<void> init() async {
    _questionTokenAes = await _verifyService.getQuestionTokenAes();
    _questionList = await _verifyService.getQuestionList() ?? [];
  }
}
