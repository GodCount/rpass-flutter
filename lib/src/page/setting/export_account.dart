import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../rpass.dart';
import '../../component/toast.dart';
import '../../model/backup.dart';
import '../../model/question.dart';
import '../../store/index.dart';
import '../../store/verify/contrller.dart';
import '../../util/common.dart';
import '../../util/file.dart';
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
    if (widget.store.accounts.accountList.isEmpty) {
      showToast(context, "没有数据需要备份");
      return;
    }
    if (_enableEncrypt) {
      if (_isNewPassword && _passwordController.text.isEmpty) {
        showToast(context, "添加或关闭 独立密码");
        return;
      }
      if (_enableSecurityQuestion &&
          _isNewSecurityQuestion &&
          _questions.isEmpty) {
        showToast(context, "添加或关闭 独立安全问题");
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
      final token = _isNewPassword
          ? md5(_passwordController.text)
          : widget.store.verify.token!;

      final passwordTest = aesEncrypt(token, VerifyController.VERIFY_TEXT);

      List<QuestionAnswerKey>? questions;
      String? questionsToken;

      if (_enableSecurityQuestion) {
        questions = !_isNewSecurityQuestion
            ? widget.store.verify.questionList
            : _questions
                .map((item) =>
                    QuestionAnswerKey(item.question, answer: item.answer))
                .toList();
        questionsToken = aesEncrypt(
            md5(_questions.map((item) => item.answer).join()), token);
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
        name: "rpass_export",
        ext: "json",
      );
      showToast(context, "导出完成,地址: $filepath");
    } catch (e) {
      showToast(context, "导出异常: ${e.toString()}");
    } finally {
      _isSaveing = false;
      _passwordController.text = "";
      _questions.clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("导出"),
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
                  title: const Text("加密数据"),
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
                              title: const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Text("独立密码"),
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
                                        decoration: const InputDecoration(
                                          labelText: "备份密码",
                                          hintText: "独立的备份数据密码",
                                          border: OutlineInputBorder(),
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
                              title: const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Text("开启安全问题"),
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
                                      title: const Padding(
                                        padding: EdgeInsets.only(left: 12),
                                        child: Text("独立问题"),
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
                                  ? InkWell(
                                      onTap: _editNewQuestion,
                                      child: Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(
                                          top: 12,
                                          bottom: 12,
                                          left: 28,
                                          right: 32,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: const Color(0xFF000000),
                                          ),
                                          borderRadius: const BorderRadius.all(
                                            Radius.circular(4.0),
                                          ),
                                        ),
                                        child: Text(
                                          _questions.isNotEmpty
                                              ? _questions
                                                  .map((item) => item.question)
                                                  .join("; ")
                                              : "独立的备份安全问题",
                                          overflow: TextOverflow.ellipsis,
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
                            child: const Text("备份"),
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
