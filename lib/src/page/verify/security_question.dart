import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/rpass_localizations.dart';

import '../../model/rpass/question.dart';

typedef QuestionOnSumit = void Function(List<QuestionAnswer>? questions);

class SecurityQuestion extends StatefulWidget {
  const SecurityQuestion({
    super.key,
    required this.onSubmit,
    this.initialList,
    this.title,
    this.subtitle,
    this.maxQuestion = 3,
  });

  final QuestionOnSumit onSubmit;
  final List<QuestionAnswer>? initialList;

  final String? title;
  final String? subtitle;
  final int maxQuestion;

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
    FocusManager.instance.primaryFocus?.unfocus();
    super.dispose();
  }

  @override
  void initState() {
    if (widget.initialList != null && widget.initialList!.isNotEmpty) {
      _questions = widget.initialList!;
      _updateText();
    } else {
      _questions = [QuestionAnswer("", "")];
    }
    super.initState();
  }

  bool _validateSaveQuestion() {
    if (_formState.currentState!.validate()) {
      _questions[_index].question = _qController.text;
      _questions[_index].answer = _aController.text;
      return true;
    }
    return false;
  }

  void _updateText() {
    _qController.text = _questions[_index].question;
    _aController.text = _questions[_index].answer;
  }

  void _removeQuestion() {
    _questions.removeAt(_index);
    setState(() {
      if (_index > 0) {
        _index--;
      }
      _updateText();
    });
  }

  void _prevQuestion() {
    _formState.currentState?.reset();
    _index--;
    _updateText();
    setState(() {});
  }

  void _nextQuestionOrAdd() {
    if (_validateSaveQuestion()) {
      if (_index == _questions.length - 1) {
        _questions.add(QuestionAnswer("", ""));
      }
      _index++;
      _updateText();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = RpassLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title ?? t.security_qa,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            widget.subtitle ?? t.security_qa_hint,
            textAlign: TextAlign.center,
          ),
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
                onPressed: _questions.length > 1 ? _removeQuestion : null,
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
                    decoration: InputDecoration(
                      labelText: t.question,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? t.cannot_emprty
                        : null,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(top: 6),
                  constraints: const BoxConstraints(maxWidth: 264),
                  child: TextFormField(
                    controller: _aController,
                    textInputAction: TextInputAction.next,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: t.answer,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? t.cannot_emprty
                        : null,
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
                onPressed: _index > 0 ? _prevQuestion : null,
                child: Text(t.prev),
              ),
              TextButton(
                onPressed:
                    _index < widget.maxQuestion ? _nextQuestionOrAdd : null,
                child: Text(_index == _questions.length - 1 ? t.add : t.next),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16, left: 24, right: 24),
          child: SizedBox(
            width: 180,
            child: ElevatedButton(
              onPressed: () {
                if (_validateSaveQuestion()) {
                  widget.onSubmit(_questions);
                }
              },
              child: Text(t.confirm),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 24, right: 24),
          child: SizedBox(
            width: 180,
            child: ElevatedButton(
              onPressed: () => widget.onSubmit(null),
              child: Text(t.back),
            ),
          ),
        )
      ],
    );
  }
}
