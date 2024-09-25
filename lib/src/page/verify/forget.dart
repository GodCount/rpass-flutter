import 'package:flutter/material.dart';

import '../../component/toast.dart';
import '../../context/store.dart';
import '../../i18n.dart';
import '../page.dart';
import 'verify_question.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  static const routeName = "/forget";

  @override
  State<ForgetPassword> createState() => ForgetPasswordState();
}

class ForgetPasswordState extends State<ForgetPassword> {
  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;
    final store = StoreProvider.of(context);

    return Scaffold(
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: VerifyQuestion(
              questions: store.verify.questionList,
              onVerify: (questions) {
                if (questions == null) {
                  Navigator.of(context).pop();
                } else {
                  try {
                    store.verify.forgotToVerifyQuestion(questions);
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
