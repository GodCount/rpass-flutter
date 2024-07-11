import 'package:flutter/material.dart';

import '../../model/question.dart';
import '../../util/verify_core.dart';
import '../index.dart';
import './service.dart';

class VerifyController with ChangeNotifier {
  VerifyController();

  late Store _store;

  final VerifyService _verifyService = VerifyService();

  String? _token;

  late String? _passwordAes;

  late String? _questionTokenAes;

  late List<QuestionAnswerKey> _questionList;

  bool get initialled => _passwordAes != null && _passwordAes!.isNotEmpty;

  List<QuestionAnswerKey> get questionList => _questionList;

  String? get token => _token;
  String? get passwordAes => _passwordAes;
  String? get questionTokenAes => _questionTokenAes;


  Future<void> initPassword(String password,
      [List<QuestionAnswer>? questions]) async {
    assert(password.isNotEmpty);
    final data = VerifyCore.createToken(password);
    _token = data.$1;
    _passwordAes = data.$2;
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
        VerifyCore.createQuestionAes(token: _token!, questions: questions);

    await _verifyService.setQuestionTokenAes(_questionTokenAes!);
    await _verifyService.setQuestionList(_questionList);
  }

  void verify(String password) {
    if (!initialled) throw Exception("Not Initialized");
    _token = VerifyCore.verify(password: password, passwordAes: _passwordAes!);
  }

  void forgotToVerifyQuestion(List<QuestionAnswer> questions) {
    assert(_questionTokenAes != null, "questionTokenAes is null");
    assert(_passwordAes != null, "_passwordAes is null");

    _token = VerifyCore.verifyQuestion(
      questions: questions,
      questionAes: _questionTokenAes!,
      passwordAes: _passwordAes!,
    );
  }

  Future<void> modifyPassword(String newPassword) async {
    await initPassword(newPassword);

    _questionTokenAes = VerifyCore.createQuestionAesByKey(
        token: _token!, questions: _questionList);

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
