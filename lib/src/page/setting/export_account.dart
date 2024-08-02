import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_gen/gen_l10n/rpass_localizations.dart';
import 'package:intl/intl.dart';

import '../../rpass.dart';
import '../../component/toast.dart';
import '../../model/rpass/backup.dart';
import '../../model/rpass/question.dart';
import '../../store/index.dart';
import '../../util/common.dart';
import '../../util/file.dart';
import '../../util/verify_core.dart';
import '../verify/security_question.dart';

class ExportAccountPage extends StatefulWidget {
  const ExportAccountPage({super.key, required this.store});

  static const routeName = "/export_account";

  final Store store;

  @override
  ExportAccountPageState createState() => ExportAccountPageState();
}

class ExportAccountPageState extends State<ExportAccountPage> {
  bool _enableEncrypt = true;
  bool _isNewPassword = false;
  bool _enableSecurityQuestion = true;
  bool _isNewSecurityQuestion = false;

  final TextEditingController _passwordController = TextEditingController();
  List<QuestionAnswer> _questions = [];

  bool _isSaveing = false;

  void _export() async {
    final t = RpassLocalizations.of(context)!;

    if (widget.store.accounts.accountList.isEmpty) {
      showToast(context, t.no_backup);
      return;
    }
    if (_enableEncrypt) {
      if (_isNewPassword && _passwordController.text.trim().length < 4) {
        showToast(context, t.input_num_password);
        return;
      }
      if (_enableSecurityQuestion &&
          _isNewSecurityQuestion &&
          _questions.isEmpty) {
        showToast(context, t.at_least_1security_qa);
        return;
      }
    }

    setState(() {
      _isSaveing = true;
    });

    String saveData;

    if (!_enableEncrypt) {
      final Backup data = Backup(
        accounts: widget.store.accounts.accountList,
        version: RpassInfo.version,
        buildNumber: RpassInfo.buildNumber,
      );
      saveData = json.encoder.convert(data);
    } else {
      late final String token;
      late final String passwordTest;

      if (_isNewPassword) {
        final data = VerifyCore.createToken(_passwordController.text);
        token = data.$1;
        passwordTest = data.$2;
      } else {
        token = widget.store.verify.token!;
        passwordTest = widget.store.verify.passwordAes!;
      }

      List<QuestionAnswerKey>? questions;
      String? questionsToken;

      if (_enableSecurityQuestion) {
        if (_isNewSecurityQuestion) {
          questions = _questions
              .map((item) =>
                  QuestionAnswerKey(item.question, answer: item.answer))
              .toList();
          questionsToken = VerifyCore.createQuestionAesByKey(
              token: token, questions: questions);
        } else {
          questions = widget.store.verify.questionList;
          questionsToken = widget.store.verify.questionTokenAes!;
        }
      }

      final EncryptBackup data = EncryptBackup(
        questions: questions,
        accounts: aesEncrypt(
            token, json.encoder.convert(widget.store.accounts.accountList)),
        questionsToken: questionsToken,
        passwordVerify: passwordTest,
        version: RpassInfo.version,
        buildNumber: RpassInfo.buildNumber,
      );

      saveData = json.encoder.convert(data);
    }
    try {
      final filepath = await SimpleFile.saveText(
        data: saveData,
        name: "rpass_export_${DateFormat.yMd().format(DateTime.now())}",
        ext: "json",
      );
      showToast(context, t.export_done_location(filepath));
    } catch (e) {
      showToast(context, t.export_throw(e.toString()));
    } finally {
      _isSaveing = false;
      _passwordController.text = "";
      _questions.clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = RpassLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.export),
        centerTitle: true,
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  value: _enableEncrypt,
                  onChanged: (value) {
                    setState(() {
                      _enableEncrypt = value;
                    });
                  },
                  title: Text(t.encrypt_data),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return SizeTransition(
                      sizeFactor: animation,
                      child: child,
                    );
                  },
                  child: _enableEncrypt
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CheckboxListTile(
                              dense: true,
                              value: _isNewPassword,
                              onChanged: (value) {
                                setState(() {
                                  _isNewPassword = value!;
                                });
                              },
                              title: Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Text(t.alone_password),
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) {
                                return SizeTransition(
                                  sizeFactor: animation,
                                  child: child,
                                );
                              },
                              child: _isNewPassword
                                  ? Padding(
                                      padding: const EdgeInsets.only(
                                        top: 12,
                                        bottom: 12,
                                        left: 28,
                                        right: 32,
                                      ),
                                      child: TextField(
                                        controller: _passwordController,
                                        keyboardType: TextInputType.number,
                                        textInputAction: TextInputAction.done,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly
                                        ],
                                        decoration: InputDecoration(
                                          labelText: t.password,
                                          hintText: t.input_num_password,
                                          border: const OutlineInputBorder(),
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            CheckboxListTile(
                              dense: true,
                              value: _enableSecurityQuestion,
                              onChanged: (value) {
                                setState(() {
                                  _enableSecurityQuestion = value!;
                                });
                              },
                              title: Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Text(t.enable_security_qa),
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) {
                                return SizeTransition(
                                  sizeFactor: animation,
                                  child: child,
                                );
                              },
                              child: _enableSecurityQuestion
                                  ? CheckboxListTile(
                                      dense: true,
                                      value: _isNewSecurityQuestion,
                                      onChanged: (value) {
                                        setState(() {
                                          _isNewSecurityQuestion = value!;
                                        });
                                      },
                                      title: Padding(
                                        padding:
                                            const EdgeInsets.only(left: 12),
                                        child: Text(t.alone_security_qa),
                                      ),
                                    )
                                  : null,
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) {
                                return SizeTransition(
                                  sizeFactor: animation,
                                  child: child,
                                );
                              },
                              child: _enableSecurityQuestion &&
                                      _isNewSecurityQuestion
                                  ? Container(
                                      margin: const EdgeInsets.only(
                                        top: 12,
                                        bottom: 12,
                                        left: 28,
                                        right: 32,
                                      ),
                                      child: GestureDetector(
                                        onTap: _editNewQuestion,
                                        child: InputDecorator(
                                          decoration: InputDecoration(
                                            labelText: _questions.isNotEmpty
                                                ? t.security_qa
                                                : null,
                                            border: const OutlineInputBorder(),
                                          ),
                                          child: Text(
                                            _questions.isNotEmpty
                                                ? _questions
                                                    .map((it) => it.question)
                                                    .join("; ")
                                                : t.security_qa,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        )
                      : null,
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: !_isSaveing
                      ? Container(
                          key: const ValueKey(1),
                          padding: const EdgeInsets.only(top: 12),
                          constraints: const BoxConstraints(minWidth: 180),
                          child: ElevatedButton(
                            onPressed: _export,
                            child: Text(t.backup),
                          ),
                        )
                      : Container(
                          key: const ValueKey(2),
                          margin: const EdgeInsets.only(top: 12),
                          width: 32,
                          height: 32,
                          child: const CircularProgressIndicator(),
                        ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editNewQuestion() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true,
          content: SecurityQuestion(
            initialList: _questions,
            onSubmit: (questions) {
              if (questions != null) {
                _questions = questions;
                setState(() {});
              }
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }
}
