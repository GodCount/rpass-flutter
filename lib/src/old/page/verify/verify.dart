import 'package:flutter/material.dart';

import '../../../i18n.dart';
import '../../../util/common.dart';
import '../../../widget/common.dart';
import '../../model/rpass/question.dart';
import '../../store/index.dart';
import 'verify_question.dart';

class VerifyPassword extends StatefulWidget {
  const VerifyPassword({super.key});

  static const routeName = "/verify";

  @override
  State<VerifyPassword> createState() => VerifyPasswordState();
}

class VerifyPasswordState extends State<VerifyPassword> with CommonWidgetUtil {
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _obscureText = true;
  String? _errorMessage;

  bool _isVerify = true;

  @override
  void initState() {
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _errorMessage != null) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
    super.initState();
  }

  void _verifyPassword() async {
    if (_passwordController.text.isNotEmpty) {
      try {
        await OldStore().migrate(context, md5(_passwordController.text));
      } catch (error) {
        setState(() {
          _errorMessage = error.toString();
        });
      }
    }
  }

  void _verifyQuestion(List<QuestionAnswer>? questions) async {
    if (questions == null) {
      return setState(() {
        _isVerify = true;
      });
    }

    try {
      final store = OldStore();
      await store.migrate(
        context,
        store.verify.forgotToVerifyQuestion(questions),
      );
    } catch (e) {
      showToast(I18n.of(context)!.security_qa_throw(e.toString()));
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
                t.verify_password,
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 24),
              constraints: const BoxConstraints(maxWidth: 264),
              child: TextField(
                focusNode: _focusNode,
                controller: _passwordController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofocus: true,
                obscureText: _obscureText,
                obscuringCharacter: "*",
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
