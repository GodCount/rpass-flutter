import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../model/question.dart';
import '../../store/index.dart';
import '../verify/security_question.dart';

class ExportAccountPage extends StatefulWidget {
  const ExportAccountPage({super.key, required this.store});

  static const routeName = "/export_account";

  final Store store;

  @override
  ExportAccountPageState createState() => ExportAccountPageState();
}

class ExportAccountPageState extends State<ExportAccountPage> {
  bool enableEncrypt = true;
  bool isNewPassword = false;
  bool enableSecurityQuestion = true;
  bool isNewSecurityQuestion = false;

  TextEditingController passwordController = TextEditingController();
  List<QuestionAnswer> questions = [];

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
                  value: enableEncrypt,
                  onChanged: (value) {
                    setState(() {
                      enableEncrypt = value;
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
                  child: enableEncrypt
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CheckboxListTile(
                              dense: true,
                              value: isNewPassword,
                              onChanged: (value) {
                                setState(() {
                                  isNewPassword = value!;
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
                              child: isNewPassword
                                  ? Padding(
                                      padding: const EdgeInsets.only(
                                        top: 12,
                                        bottom: 12,
                                        left: 28,
                                        right: 32,
                                      ),
                                      child: TextField(
                                        controller: passwordController,
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
                              value: enableSecurityQuestion,
                              onChanged: (value) {
                                setState(() {
                                  enableSecurityQuestion = value!;
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
                              child: enableSecurityQuestion
                                  ? CheckboxListTile(
                                      dense: true,
                                      value: isNewSecurityQuestion,
                                      onChanged: (value) {
                                        setState(() {
                                          isNewSecurityQuestion = value!;
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
                              child: enableSecurityQuestion &&
                                      isNewSecurityQuestion
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
                                          questions.isNotEmpty
                                              ? questions
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
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  constraints: const BoxConstraints(minWidth: 180),
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text("备份"),
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
            initialList: questions,
            onSubmit: (questions) {
              if (questions != null) {
                this.questions = questions;
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
