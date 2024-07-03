import 'package:flutter/material.dart';

import 'package:animations/animations.dart';
import 'package:flutter/services.dart';

// import '../../component/component.dart';
import '../../store/verify/contrller.dart';
import '../../model/question.dart';

class InitPassword extends StatefulWidget {
  const InitPassword({super.key, required this.verifyContrller});

  static const routeName = "/init";

  final VerifyController verifyContrller;

  @override
  State<InitPassword> createState() => InitPasswordState();
}

class InitPasswordState extends State<InitPassword> {
  final TextEditingController _passwordController = TextEditingController();

  bool _isSetPasswordDone = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: PageTransitionSwitcher(
              reverse: !_isSetPasswordDone,
              transitionBuilder: (
                child,
                animation,
                secondaryAnimation,
              ) {
                return SharedAxisTransition(
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  transitionType: SharedAxisTransitionType.vertical,
                  fillColor: Colors.transparent,
                  child: child,
                );
              },
              child: !_isSetPasswordDone
                  ? SetPassword(
                      controller: _passwordController,
                      onSetPassword: () {
                        setState(() {
                          _isSetPasswordDone = true;
                        });
                      },
                    )
                  : SecurityQuestion(
                      onSubmit: (questions) {
                        if (questions == null) {
                          setState(() {
                            _isSetPasswordDone = false;
                          });
                        } else {
                          final password = _passwordController.text;
                          final questionList = questions
                              .map((item) =>
                                  Question(item.question, answer: item.answer))
                              .toList();
                          widget.verifyContrller
                              .initPassword(password, questionList)
                              .then((value) {
                            Navigator.pushReplacementNamed(context, "/");
                          }, onError: (error) {
                            print(error);
                          });
                        }
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class SetPassword extends StatelessWidget {
  const SetPassword({
    super.key,
    required this.controller,
    required this.onSetPassword,
  });

  final TextEditingController controller;
  final void Function() onSetPassword;

  @override
  Widget build(BuildContext context) {
    final GlobalKey<FormState> formState = GlobalKey<FormState>();

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
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Form(
            key: formState,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: TextFormField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    autofocus: true,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                        labelText: "init password",
                        border: OutlineInputBorder()),
                    validator: (value) {
                      return value == null || value.trim().isEmpty
                          ? "be not empty"
                          : value.length > 3
                              ? null
                              : "must length > 3";
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    autofocus: true,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: "init password",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      return value == controller.text ? null : "must equal";
                    },
                  ),
                ),
                Container(
                  width: 180,
                  padding: const EdgeInsets.only(top: 24),
                  child: ElevatedButton(
                    onPressed: () {
                      if (formState.currentState!.validate()) {
                        onSetPassword();
                      }
                    },
                    child: const Text("初始化"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

typedef QuestionOnSumit = void Function(List<QuestionItem>? questions);

class SecurityQuestion extends StatefulWidget {
  const SecurityQuestion({super.key, required this.onSubmit});

  final QuestionOnSumit onSubmit;

  @override
  State<SecurityQuestion> createState() => SecurityQuestionState();
}

class QuestionItem {
  QuestionItem({String? question, String? answer})
      : question = question ?? "",
        answer = answer ?? "";
  late String question;
  late String answer;
}

class SecurityQuestionState extends State<SecurityQuestion> {
  final List<QuestionItem> _questions = [QuestionItem()];

  int _index = 0;

  final TextEditingController _qController = TextEditingController();
  final TextEditingController _aController = TextEditingController();
  final GlobalKey<FormState> _formState = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
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
          constraints: const BoxConstraints.tightFor(width: 200),
          padding: const EdgeInsets.only(top: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                "${_index + 1} / ${_questions.length}",
                textAlign: TextAlign.end,
              ),
              IconButton(
                onPressed: _questions.length > 1
                    ? () {
                        _questions.removeAt(_index);
                        setState(() {
                          _index = _index == 0 ? 0 : _index - 1;
                        });
                      }
                    : null,
                iconSize: 16,
                icon: const Icon(Icons.delete),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Form(
            key: _formState,
            child: Column(
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: TextFormField(
                    controller: _qController,
                    textInputAction: TextInputAction.next,
                    autofocus: true,
                    decoration: const InputDecoration(
                        labelText: "question", border: OutlineInputBorder()),
                    validator: (value) {
                      return value == null || value.trim().isEmpty
                          ? "be not empty"
                          : null;
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(top: 6),
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: TextFormField(
                    controller: _aController,
                    textInputAction: TextInputAction.next,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: "answer",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      return value == null || value.trim().isEmpty
                          ? "be not empty"
                          : null;
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          constraints: const BoxConstraints.tightFor(width: 200),
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: _index > 0
                    ? () {
                        setState(() {
                          _index -= 1;
                          _formState.currentState?.reset();
                        });
                      }
                    : null,
                child: const Text("上一个"),
              ),
              TextButton(
                onPressed: () {
                  if (_formState.currentState!.validate()) {
                    _questions[_index].question = _qController.value.text;
                    _questions[_index].answer = _aController.value.text;
                    if (_index == _questions.length - 1) {
                      _questions.add(QuestionItem());
                    }
                    setState(() {
                      _index += 1;
                    });
                  }
                },
                child: Text(_index == _questions.length - 1 ? "添加" : "下一个"),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16, left: 24, right: 24),
          child: SizedBox(
            width: 180,
            child: ElevatedButton(
              onPressed: () => widget.onSubmit(null),
              child: const Text("返回"),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 24, right: 24),
          child: SizedBox(
            width: 180,
            child: ElevatedButton(
              onPressed: () {
                if (_formState.currentState!.validate()) {
                  widget.onSubmit(_questions);
                }
              },
              child: const Text("确定"),
            ),
          ),
        )
      ],
    );
  }
}
