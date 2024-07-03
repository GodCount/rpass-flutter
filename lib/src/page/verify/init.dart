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
      body: Card(
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxHeight = constraints.maxHeight;
        final GlobalKey<FormState> formState = GlobalKey<FormState>();

        return Column(
          children: [
            Padding(padding: EdgeInsets.symmetric(vertical: maxHeight / 20)),
            Text(
              'Hi David Park',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Padding(padding: EdgeInsets.symmetric(vertical: maxHeight / 50)),
            const Text('Sign in with your account',
                textAlign: TextAlign.center),
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Form(
                key: formState,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  children: [
                    TextFormField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
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
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: const InputDecoration(
                          labelText: "init password",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          return value == controller.text ? null : "must equal";
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 128,
                  height: 64,
                  child: IconButton.filled(
                    onPressed: () {
                      if (formState.currentState!.validate()) {
                        onSetPassword();
                      }
                    },
                    icon: const Icon(Icons.keyboard_arrow_right_rounded),
                  ),
                ),
              ),
            ),
          ],
        );
      },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxHeight = constraints.maxHeight;
        _qController.text = _questions[_index].question;
        _aController.text = _questions[_index].answer;
        return Column(
          children: [
            Padding(padding: EdgeInsets.symmetric(vertical: maxHeight / 20)),
            Text(
              'Hi David Park',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Padding(padding: EdgeInsets.symmetric(vertical: maxHeight / 50)),
            const Text('Sign in with your account',
                textAlign: TextAlign.center),
            Padding(
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
                    TextFormField(
                      controller: _qController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                          labelText: "question", border: OutlineInputBorder()),
                      validator: (value) {
                        return value == null || value.trim().isEmpty
                            ? "be not empty"
                            : null;
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: TextFormField(
                        controller: _aController,
                        textInputAction: TextInputAction.done,
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
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => widget.onSubmit(null),
                  child: const Text("返回"),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 24, right: 24),
              child: SizedBox(
                width: double.infinity,
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
      },
    );
  }
}
