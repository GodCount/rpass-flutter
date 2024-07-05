import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../model/question.dart';
import '../../store/verify/contrller.dart';
import '../page.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key, required this.verifyContrller});

  static const routeName = "/forget";

  final VerifyController verifyContrller;

  @override
  State<ForgetPassword> createState() => ForgetPasswordState();
}

class ForgetPasswordState extends State<ForgetPassword> {
  final TextEditingController _qController = TextEditingController();
  final TextEditingController _aController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late List<QuestionAnswer> _questions;

  String? _errorHitText;

  int _index = 0;

  @override
  void initState() {
    _questions = widget.verifyContrller.questionList
        .map((item) => QuestionAnswer(item.question, ""))
        .toList();
    _focusNode.addListener(() {
      if (_errorHitText != null && _focusNode.hasFocus) {
        setState(() {
          _errorHitText = null;
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _aController.dispose();
    _qController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("build forget passsword");
    _qController.text = _questions[_index].question;
    _aController.text = _questions[_index].answer;
    return Scaffold(
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _questionRender(),
          ),
        ),
      ),
    );
  }

  Widget _questionRender() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Hi David Park',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text('Sign in with your account', textAlign: TextAlign.center),
        ),
        Container(
          constraints: const BoxConstraints(maxWidth: 264),
          padding: const EdgeInsets.only(top: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                "${_index + 1} / ${_questions.length}",
                textAlign: TextAlign.end,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.only(top: 6),
          constraints: const BoxConstraints(maxWidth: 264),
          child: TextField(
            controller: _qController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: "question",
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(top: 6),
          constraints: const BoxConstraints(maxWidth: 264),
          child: TextField(
            controller: _aController,
            focusNode: _focusNode,
            textInputAction: TextInputAction.next,
            autofocus: true,
            decoration: InputDecoration(
              labelText: "answer",
              errorText: _errorHitText,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16, left: 24, right: 24),
          child: SizedBox(
            width: 180,
            child: ElevatedButton(
              onPressed: () {
                if (widget.verifyContrller.questionList[_index]
                    .verify(_aController.text)) {
                  _questions[_index].answer = _aController.text;
                  if (_index < _questions.length - 1) {
                    setState(() {
                      _index += 1;
                    });
                  } else {
                    try {
                      widget.verifyContrller.forgotToVerifyQuestion(_questions);
                      Navigator.of(context).pushNamedAndRemoveUntil(Home.routeName, ModalRoute.withName('/'));
                    } catch (e) {
                      if (kDebugMode) {
                        print(e);
                      }
                      // TODO!
                    }
                  }
                } else {
                  setState(() {
                    _errorHitText = "不对啊, 再想想!";
                  });
                }
              },
              child: Text(_index == _questions.length - 1 ? "确认" : "下一个"),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 24, right: 24),
          child: SizedBox(
            width: 180,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("输入密码"),
            ),
          ),
        )
      ],
    );
  }
}
