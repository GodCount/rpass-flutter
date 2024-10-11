import 'package:flutter/material.dart';

import '../../../i18n.dart';
import '../../model/rpass/question.dart';

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
    _qController.dispose();
    _aController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _confirmOrNext() {
    if (widget.questions[_index].verify(_aController.text)) {
      _questions[_index].answer = _aController.text;
      if (_index < _questions.length - 1) {
        _index++;
        _errorHitText = null;
        setState(() {});
        _focusNode.requestFocus();
      } else {
        widget.onVerify(_questions);
      }
    } else {
      setState(() {
        _errorHitText = I18n.of(context)!.security_qa_error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    _qController.text = _questions[_index].question;
    _aController.text = _questions[_index].answer;

    final isDone = _index >= _questions.length - 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          t.app_name,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
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
            textInputAction: TextInputAction.none,
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
            textInputAction:
                isDone ? TextInputAction.done : TextInputAction.next,
            autofocus: true,
            decoration: InputDecoration(
              labelText: t.answer,
              errorText: _errorHitText,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (value) => _confirmOrNext(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16, left: 24, right: 24),
          child: SizedBox(
            width: 180,
            child: ElevatedButton(
              onPressed: _confirmOrNext,
              child: Text(isDone ? t.confirm : t.next),
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
