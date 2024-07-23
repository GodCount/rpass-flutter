import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/rpass_localizations.dart';

import '../../model/question.dart';

typedef OnVerifyCallback = void Function(List<QuestionAnswer>? questions);

class VerifyQuestion extends StatefulWidget {
  const VerifyQuestion(
      {super.key, required this.questions, required this.onVerify});

  final List<QuestionAnswerKey> questions;
  final OnVerifyCallback onVerify;

  @override
  State<VerifyQuestion> createState() => _VerifyQuestionState();
}

class _VerifyQuestionState extends State<VerifyQuestion> {
  final TextEditingController _qController = TextEditingController();
  final TextEditingController _aController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late List<QuestionAnswer> _questions;

  String? _errorHitText;

  int _index = 0;

  @override
  void initState() {
    _questions = widget.questions
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
    final t = RpassLocalizations.of(context)!;

    _qController.text = _questions[_index].question;
    _aController.text = _questions[_index].answer;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          t.app_name,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(t.input_security_qa_hint, textAlign: TextAlign.center),
        ),
        Container(
          constraints: const BoxConstraints(maxWidth: 264),
          padding: const EdgeInsets.only(top: 12),
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
            decoration: InputDecoration(
              labelText: t.question,
              border: const OutlineInputBorder(),
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
              labelText: t.answer,
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
                if (widget.questions[_index].verify(_aController.text)) {
                  _questions[_index].answer = _aController.text;
                  if (_index < _questions.length - 1) {
                    setState(() {
                      _index += 1;
                    });
                  } else {
                    widget.onVerify(_questions);
                  }
                } else {
                  setState(() {
                    _errorHitText = t.security_qa_error;
                  });
                }
              },
              child: Text(_index == _questions.length - 1 ? t.confirm : t.next),
            ),
          ),
        ),
        Padding(
          padding:
              const EdgeInsets.only(top: 6, left: 24, right: 24, bottom: 12),
          child: SizedBox(
            width: 180,
            child: ElevatedButton(
              onPressed: () => widget.onVerify(null),
              child: Text(t.back),
            ),
          ),
        )
      ],
    );
  }
}
