import 'package:flutter/material.dart';

import '../../model/question.dart';
import '../../util/common.dart';
import '../index.dart';
import './service.dart';

class VerifyController with ChangeNotifier {
  VerifyController();

  // ignore: constant_identifier_names
  static const String VERIFY_TEXT = "done";

  late Store _store;

  final VerifyService _verifyService = VerifyService();

  String? _token;

  late String? _passwordAes;

  late String? _questionTokenAes;

  late List<QuestionAnswerKey> _questionList;

  bool get initialled => _passwordAes != null && _passwordAes!.isNotEmpty;

  List<QuestionAnswerKey> get questionList => _questionList;

  String? get token => _token;

  Future<void> initPassword(String password,
      [List<QuestionAnswer>? questions]) async {
    assert(password.isNotEmpty);
    _token = md5(password);
    _passwordAes = aesEncrypt(_token!, VERIFY_TEXT);
    if (questions != null) await setQuestionList(questions);
    await _verifyService.setPasswordAes(_passwordAes!);
  }

  Future<void> setQuestionList(List<QuestionAnswer> questions) async {
    assert(_token != null && _token!.isNotEmpty, "token is null");
    assert(questions.isNotEmpty, "must question list length > 1");

    _questionList.clear();
    _questionList.addAll(questions
        .map((item) => QuestionAnswerKey(item.question, answer: item.answer)));

    _questionTokenAes =
        aesEncrypt(md5(questions.map((item) => item.answer).join()), _token!);

    await _verifyService.setQuestionTokenAes(_questionTokenAes!);
    await _verifyService.setQuestionList(_questionList);
  }

  void verify(String password) {
    if (!initialled) throw Exception("Not Initialized");

    final token = md5(password);

    if (aesDenrypt(token, _passwordAes!) != VERIFY_TEXT) {
      throw Exception("Password Error!");
    }
    _token = token;
  }

  void forgotToVerifyQuestion(List<QuestionAnswer> questions) {
    assert(_questionTokenAes != null, "questionTokenAes is null");
    assert(_passwordAes != null, "_passwordAes is null");

    final token = aesDenrypt(
        md5(questions.map((item) => item.answer).join()), _questionTokenAes!);

    if (aesDenrypt(token, _passwordAes!) != VERIFY_TEXT) {
      throw Exception("app deranged");
    }
    _token = token;
  }

  Future<void> modifyPassword(String newPassword) async {
    await initPassword(newPassword);

    _questionTokenAes = aesEncrypt(
        md5(_questionList.map((item) => item.answerKey).join()), _token!);

    await _verifyService.setQuestionTokenAes(_questionTokenAes!);

    await _store.accounts.updateToken();

  }

  Future<void> init(Store store) async {
    _store = store;
    _passwordAes = await _verifyService.getPasswordAes();

    _questionTokenAes = await _verifyService.getQuestionTokenAes();

    _questionList = await _verifyService.getQuestionList() ?? [];

    notifyListeners();
  }
}
