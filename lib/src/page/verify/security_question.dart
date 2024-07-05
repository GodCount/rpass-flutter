import 'package:flutter/material.dart';

import '../../model/question.dart';

typedef QuestionOnSumit = void Function(List<QuestionAnswer>? questions);

class SecurityQuestion extends StatefulWidget {
  const SecurityQuestion({super.key, required this.onSubmit, this.initialList});

  final QuestionOnSumit onSubmit;
  final List<QuestionAnswer>? initialList;

  @override
  State<SecurityQuestion> createState() => SecurityQuestionState();
}

class SecurityQuestionState extends State<SecurityQuestion> {
  late final List<QuestionAnswer> _questions;

  int _index = 0;

  final TextEditingController _qController = TextEditingController();
  final TextEditingController _aController = TextEditingController();
  final GlobalKey<FormState> _formState = GlobalKey<FormState>();


  @override
  void dispose() {
    _qController.dispose();
    _aController.dispose();
    super.dispose();
  }


  @override
  void initState() {
    if (widget.initialList != null && widget.initialList!.isNotEmpty) {
      _questions = widget.initialList!;
      _qController.text = _questions[_index].question;
      _aController.text = _questions[_index].answer;
    } else {
      _questions = [QuestionAnswer("", "")];
    }
    super.initState();
  }

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
          constraints: const BoxConstraints(maxWidth: 264),
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
                  constraints: const BoxConstraints(maxWidth: 264),
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
                  constraints: const BoxConstraints(maxWidth: 264),
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
          constraints: const BoxConstraints(maxWidth: 264),
          padding: const EdgeInsets.only(top: 6),
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
                  if (_validateSaveQuestion()) {
                    if (_index == _questions.length - 1) {
                      _questions.add(QuestionAnswer("", ""));
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
                if (_validateSaveQuestion()) {
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

  bool _validateSaveQuestion() {
    if (_formState.currentState!.validate()) {
      _questions[_index].question = _qController.value.text;
      _questions[_index].answer = _aController.value.text;
      return true;
    }
    return false;
  }
}
