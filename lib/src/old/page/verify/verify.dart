import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../../i18n.dart';
import '../../../page/page.dart';
import '../../../util/common.dart';
import '../../../widget/extension_state.dart';
import '../../model/rpass/question.dart';
import '../../store/index.dart';
import 'verify_question.dart';

final _logger = Logger("old:verify");

class VerifyPassword extends StatefulWidget {
  const VerifyPassword({super.key});

  static const routeName = "/verify";

  @override
  State<VerifyPassword> createState() => VerifyPasswordState();
}

class VerifyPasswordState extends State<VerifyPassword> {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;

  bool _isVerify = true;

  @override
  void initState() {
    super.initState();
  }

  void _denrypt(String token) async {
    try {
      await OldStore().accounts.denrypt(token);
      Navigator.of(context).popAndPushNamed(InitKdbxPage.routeName);
    } catch (e) {
      _logger.fine("denrypt old data password error!", e);
      showError(e);
    }
  }

  void _verifyPassword() async {
    if (_passwordController.text.isNotEmpty) {
      _denrypt(md5(_passwordController.text));
    }
  }

  void _verifyQuestion(List<QuestionAnswer>? questions) async {
    if (questions == null) {
      return setState(() {
        _isVerify = true;
      });
    }

    try {
      _denrypt(OldStore().verify.forgotToVerifyQuestion(questions));
    } catch (e) {
      _logger.warning("denrypt old data password error by question!", e);
      showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
        child: _isVerify ? _buildVerify() : _buildForget(),
      ),
    );
  }

  Widget _buildForget() {
    final store = OldStore();
    return Card(
      margin: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: VerifyQuestion(
          questions: store.verify.questionList,
          onVerify: _verifyQuestion,
        ),
      ),
    );
  }

  Widget _buildVerify() {
    final t = I18n.of(context)!;
    final store = OldStore();

    return Card(
      margin: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.app_name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                t.data_migrate_hint,
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 24),
              constraints: const BoxConstraints(maxWidth: 264),
              child: TextField(
                controller: _passwordController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofocus: true,
                obscureText: _obscureText,
                obscuringCharacter: "*",
                decoration: InputDecoration(
                  labelText: t.password,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                    icon: Icon(
                      _obscureText
                          ? Icons.remove_red_eye_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                onSubmitted: (value) {
                  _verifyPassword();
                },
              ),
            ),
            if (store.verify.isExistQuestion)
              Container(
                constraints: const BoxConstraints(maxWidth: 264),
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isVerify = false;
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
          ],
        ),
      ),
    );
  }
}
