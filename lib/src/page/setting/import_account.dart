import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../component/toast.dart';
import '../../context/store.dart';
import '../../i18n.dart';
import '../../model/browser/chrome.dart';
import '../../model/browser/firefox.dart';
import '../../model/common.dart';
import '../../model/rpass/backup.dart';
import '../../model/rpass/question.dart';
import '../../rpass.dart';
import '../../util/common.dart';
import '../../util/file.dart';
import '../../util/verify_core.dart';
import '../verify/verify_question.dart';

class ImportAccountPage extends StatefulWidget {
  const ImportAccountPage({super.key});

  static const routeName = "/import_account";

  @override
  State<ImportAccountPage> createState() => _ImportAccountPageState();
}

class _ImportAccountPageState extends State<ImportAccountPage> {
  BackupType? _importType;
  bool? _importSuccess;

  void _import(BackupType type) async {
    setState(() {
      _importType = type;
    });

    try {
      Backup? backup;
      switch (type) {
        case BackupType.rpass:
          backup = await _importRpass();
          break;
        case BackupType.chrome:
          backup = await _importChrome();
          break;
        case BackupType.firefox:
          backup = await _importFirefox();
          break;
      }
      if (backup != null && backup.accounts.isNotEmpty) {
        await StoreProvider.of(context).accounts.importBackupAccounts(backup);
        showToast(context, I18n.of(context)!.import_done);
        _importSuccess = true;
      }
    } catch (e) {
      showToast(context, I18n.of(context)!.import_throw(e.toString()));
      _importSuccess = false;
    } finally {
      setState(() {});
      Timer(const Duration(seconds: 1), () {
        setState(() {
          _importType = null;
          _importSuccess = null;
        });
      });
    }
  }

  Future<Backup?> _importRpass() {
    final completer = Completer<Backup?>();
    Timer(const Duration(), () async {
      try {
        final data = await SimpleFile.openText(allowedExtensions: ["json"]);
        final object = json.decoder.convert(data);
        try {
          completer.complete(Backup.fromJson(object));
        } catch (e) {
          return completer
              .complete(await _denryptBackup(EncryptBackup.fromJson(object)));
        }
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

  Future<Backup?> _importChrome() async {
    final data = await SimpleFile.openText(allowedExtensions: ["csv"]);
    final result = ChromeAccount.toAccounts(ChromeAccount.fromCsv(data));
    return Backup(
      accounts: result,
      version: RpassInfo.version,
      buildNumber: RpassInfo.buildNumber,
    );
  }

  Future<Backup?> _importFirefox() async {
    final data = await SimpleFile.openText(allowedExtensions: ["csv"]);
    final result = FirefoxAccount.toAccounts(FirefoxAccount.fromCsv(data));
    return Backup(
      accounts: result,
      version: RpassInfo.version,
      buildNumber: RpassInfo.buildNumber,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.import),
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(6.0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _listTile(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(6.0),
                    topRight: Radius.circular(6.0),
                  ),
                ),
                type: BackupType.rpass,
                title: t.app_name,
              ),
              _listTile(type: BackupType.chrome, title: t.chrome),
              _listTile(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(6.0),
                    bottomRight: Radius.circular(6.0),
                  ),
                ),
                type: BackupType.firefox,
                title: t.firefox,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _listTile({
    ShapeBorder? shape,
    required BackupType type,
    required String title,
  }) {
    return ListTile(
      shape: shape,
      onTap: _importType == null ? () => _import(type) : null,
      title: Opacity(
        opacity: _importType == null ? 1 : 0.5,
        child: Text(title),
      ),
      trailing: _importType == type
          ? AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: SizedBox(
                width: 24,
                height: 24,
                child: _importSuccess == null
                    ? const CircularProgressIndicator()
                    : _importSuccess!
                        ? Icon(
                            Icons.task_alt,
                            color: Theme.of(context).colorScheme.secondary,
                          )
                        : Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.error,
                          ),
              ),
            )
          : null,
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
  String? _errorMessage;

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
        _errorMessage = e.toString();
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
      showToast(context, I18n.of(context)!.security_qa_throw(e.toString()));
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
      showToast(context, I18n.of(context)!.denrypt_throw(e.toString()));
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
    final t = I18n.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          t.app_name,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(t.verify_password, textAlign: TextAlign.center),
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
            obscuringCharacter: "*",
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
                labelText: t.password,
                hintText: t.input_num_password,
                errorText: _errorMessage != null
                    ? t.verify_password_throw(_errorMessage!)
                    : null,
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
                  child: Text(t.forget_password),
                ),
              ],
            ),
          ),
        Container(
          width: 180,
          padding: const EdgeInsets.only(top: 24),
          child: ElevatedButton(
            onPressed: _verifyPassword,
            child: Text(t.confirm),
          ),
        ),
        Container(
          width: 180,
          padding: const EdgeInsets.only(top: 6, bottom: 12),
          child: ElevatedButton(
            onPressed: () => widget.onDenrypt(null),
            child: Text(t.cancel),
          ),
        ),
      ],
    );
  }
}
