import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../component/toast.dart';
import '../../model/backup.dart';
import '../../model/question.dart';
import '../../store/index.dart';
import '../../util/common.dart';
import '../../util/file.dart';
import '../../util/verify_core.dart';
import '../verify/verify_question.dart';

class ImportAccountPage extends StatefulWidget {
  const ImportAccountPage({super.key, required this.store});

  static const routeName = "/import_account";

  final Store store;

  @override
  State<ImportAccountPage> createState() => _ImportAccountPageState();
}

class _ImportAccountPageState extends State<ImportAccountPage> {
  bool _isImporting = false;

  void _import() async {
    setState(() {
      _isImporting = true;
    });

    try {
      final result = await SimpleFile.openText();
      if (await _verifyImport(result)) {
        showToast(context, "导入完成");
      }
    } catch (e) {
      showToast(context, "导入异常: ${e.toString()}");
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  Future<bool> _verifyImport(String data) {
    final completer = Completer<bool>();
    final accountsContrller = widget.store.accounts;
    Timer(const Duration(), () async {
      try {
        final object = json.decoder.convert(data);
        late Backup backup;
        try {
          backup = Backup.fromJson(object);
        } catch (e) {
          final reslut = await _denryptBackup(EncryptBackup.fromJson(object));
          if (reslut == null) {
            return completer.complete(false);
          }
          backup = reslut;
        }
        await accountsContrller.importBackupAccounts(backup);
        completer.complete(true);
      } catch (e) {
        completer.completeError(e);
      }
    });

    return completer.future;
  }

  Future<Backup?> _denryptBackup(EncryptBackup encryptBackup) async {
    final completer = Completer<Backup?>();
    Timer(const Duration(), () {
      showDialog<Backup?>(
        context: context,
        builder: (context) {
          return AlertDialog(
            scrollable: true,
            content: _VerifyImportPassword(
              encryptBackup: encryptBackup,
              onDenrypt: (backup) {
                Navigator.of(context).pop(backup);
              },
            ),
          );
        },
      ).then((value) {
        completer.complete(value);
      });
    });
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("导入"),
        centerTitle: true,
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 12, bottom: 12),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
              child: !_isImporting
                  ? Container(
                      key: const ValueKey(1),
                      padding: const EdgeInsets.only(top: 12),
                      constraints: const BoxConstraints(minWidth: 180),
                      child: ElevatedButton(
                        onPressed: _import,
                        child: const Text("导入"),
                      ),
                    )
                  : Container(
                      key: const ValueKey(2),
                      margin: const EdgeInsets.only(top: 12),
                      width: 32,
                      height: 32,
                      child: const CircularProgressIndicator(),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

typedef OnDenryptCallback = void Function(Backup? backup);

class _VerifyImportPassword extends StatefulWidget {
  const _VerifyImportPassword({
    required this.encryptBackup,
    required this.onDenrypt,
  });

  final EncryptBackup encryptBackup;
  final OnDenryptCallback onDenrypt;

  @override
  State<_VerifyImportPassword> createState() => _VerifyImportPasswordState();
}

class _VerifyImportPasswordState extends State<_VerifyImportPassword> {
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late bool _existSecurityQuestion;
  bool _forgetPassword = false;
  bool _obscureText = true;
  String? _errorHitText;

  @override
  void initState() {
    _existSecurityQuestion = widget.encryptBackup.questionsToken != null &&
        widget.encryptBackup.questionsToken!.isNotEmpty &&
        widget.encryptBackup.questions != null &&
        widget.encryptBackup.questions!.isNotEmpty;
    super.initState();
  }

  void _verifyPassword() {
    try {
      final token = VerifyCore.verify(
        password: _passwordController.text,
        passwordAes: widget.encryptBackup.passwordVerify,
      );
      _denryptBackup(token);
    } catch (e) {
      setState(() {
        _errorHitText = "密码异常: ${e.toString()}";
      });
    }
  }

  void _verifyQuestion(List<QuestionAnswer> questions) {
    try {
      final token = VerifyCore.verifyQuestion(
        questions: questions,
        questionAes: widget.encryptBackup.questionsToken!,
        passwordAes: widget.encryptBackup.passwordVerify,
      );
      _denryptBackup(token);
    } catch (e) {
      showToast(context, "安全问题异常: ${e.toString()}");
    }
  }

  void _denryptBackup(String token) {
    try {
      final accounts = aesDenrypt(token, widget.encryptBackup.accounts);
      final backup = Backup.fromJson({
        "accounts": json.decoder.convert(accounts),
        "__version__": widget.encryptBackup.version,
        "__build_number__": widget.encryptBackup.buildNumber,
      });
      widget.onDenrypt(backup);
    } catch (e) {
      showToast(context, "解密异常: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      },
      child: _forgetPassword && _existSecurityQuestion
          ? VerifyQuestion(
              questions: widget.encryptBackup.questions ?? [],
              onVerify: (questions) {
                if (questions == null) {
                  setState(() {
                    _forgetPassword = false;
                  });
                } else {
                  _verifyQuestion(questions);
                }
              },
            )
          : _inputPassword(),
    );
  }

  Widget _inputPassword() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Rpass',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text('验证密码', textAlign: TextAlign.center),
        ),
        Container(
          padding: const EdgeInsets.only(top: 12),
          constraints: const BoxConstraints(maxWidth: 264),
          child: TextField(
            focusNode: _focusNode,
            controller: _passwordController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofocus: true,
            obscureText: _obscureText,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
                labelText: "输入密码",
                errorText: _errorHitText,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                    icon: Icon(_obscureText
                        ? Icons.remove_red_eye_outlined
                        : Icons.visibility_off_outlined))),
            onSubmitted: (value) {
              _verifyPassword();
            },
          ),
        ),
        if (_existSecurityQuestion)
          Container(
            constraints: const BoxConstraints(maxWidth: 264),
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _forgetPassword = true;
                    });
                  },
                  child: const Text("忘记密码"),
                ),
              ],
            ),
          ),
        Container(
          width: 180,
          padding: const EdgeInsets.only(top: 24),
          child: ElevatedButton(
            onPressed: _verifyPassword,
            child: const Text("确认"),
          ),
        ),
        Container(
          width: 180,
          padding: const EdgeInsets.only(top: 6, bottom: 12),
          child: ElevatedButton(
            onPressed: () => widget.onDenrypt(null),
            child: const Text("取消"),
          ),
        ),
      ],
    );
  }
}
