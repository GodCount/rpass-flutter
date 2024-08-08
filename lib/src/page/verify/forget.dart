import 'package:flutter/material.dart';

import '../../component/toast.dart';
import '../../i18n.dart';
import '../../store/verify/contrller.dart';
import '../page.dart';
import 'verify_question.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key, required this.verifyContrller});

  static const routeName = "/forget";

  final VerifyController verifyContrller;

  @override
  State<ForgetPassword> createState() => ForgetPasswordState();
}

class ForgetPasswordState extends State<ForgetPassword> {
  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    return Scaffold(
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: VerifyQuestion(
              questions: widget.verifyContrller.questionList,
              onVerify: (questions) {
                if (questions == null) {
                  Navigator.of(context).pop();
                } else {
                  try {
                    widget.verifyContrller.forgotToVerifyQuestion(questions);
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        Home.routeName, ModalRoute.withName('/'));
                  } catch (e) {
                    showToast(context, t.security_qa_throw(e.toString()));
                  }
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
