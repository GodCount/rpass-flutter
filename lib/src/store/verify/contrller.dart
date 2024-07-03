import 'package:flutter/material.dart';

import '../../model/question.dart';
import '../../util/common.dart';
import './service.dart';

class VerifyController with ChangeNotifier {
  VerifyController(this._verifyService);

  // ignore: constant_identifier_names
  static const String VERIFY_TEXT = "done";

  final VerifyService _verifyService;

  String? _token;

  late String? _passwordAes;

  late String? _questionTokenAes;

  late final List<Question> _questionList;

  bool get initialled => _passwordAes != null && _passwordAes!.isNotEmpty;

  String? get token => _token;

  Future<void> initPassword(String password, [List<Question>? questions]) async {
    assert(password.isNotEmpty);
    _token = md5(password);
    _passwordAes = aesEncrypt(_token!, VERIFY_TEXT);
    if (questions != null) await setQuestionList(questions);
    await _verifyService.setPasswordAes(_passwordAes!);
  }

  Future<void> setQuestionList(List<Question> questions) async {
    assert(_token != null && _token!.isNotEmpty, "token is null");
    assert(questions.every((item) => item.verify()), "answer not euqls key");
    assert(questions.isNotEmpty, "must question list length > 1");

    _questionList.clear();
    _questionList.addAll(questions);

    _questionTokenAes = aesEncrypt(
        md5(_questionList.map((item) => item.answerKey).join()), _token!);

    await _verifyService.setQuestionTokenAes(_questionTokenAes!);
    await _verifyService.setQuestionList(_questionList);
  }

  void verify(String password) {
    if (!initialled) throw Exception("Not Initialized");

    final token = md5(password);

    if (aesDenrypt(token, _passwordAes!) == VERIFY_TEXT) {
      _token = token;
    }

    throw Exception("Password Error!");
  }

  void forgotToVerifyQuestion(List<Question> questions) {
    assert(questions.every((item) => item.verify()), "answer not euqls key");
    assert(_questionTokenAes != null, "questionTokenAes is null");
    assert(_passwordAes != null, "_passwordAes is null");

    final key = md5(questions.map((item) => item.answerKey).join());

    final token = aesDenrypt(key, _questionTokenAes!);

    if (aesDenrypt(token, _passwordAes!) == VERIFY_TEXT) {
      _token = token;
    }

    throw Exception("app deranged");
  }

  Future<void> modifyPassword(String newPassword) async {
    await initPassword(newPassword);

    _questionTokenAes = aesEncrypt(
        md5(_questionList.map((item) => item.answerKey).join()), _token!);

    await _verifyService.setQuestionTokenAes(_questionTokenAes!);
  }

  Future<void> load() async {
    _passwordAes = await _verifyService.getPasswordAes();

    _questionTokenAes = await _verifyService.getQuestionTokenAes();

    _questionList = await _verifyService.getQuestionList() ?? [];

    notifyListeners();
  }
}
