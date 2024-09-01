import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:animations/animations.dart';

import '../../i18n.dart';
import '../../store/verify/contrller.dart';
import '../home/home.dart';
import 'security_question.dart';

class InitPassword extends StatefulWidget {
  const InitPassword({super.key, required this.verifyContrller});

  static const routeName = "/init";

  final VerifyController verifyContrller;

  @override
  State<InitPassword> createState() => InitPasswordState();
}

class InitPasswordState extends State<InitPassword> {
  final TextEditingController _passwordController = TextEditingController();

  bool _isSetPasswordDone = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: PageTransitionSwitcher(
              reverse: !_isSetPasswordDone,
              transitionBuilder: (
                child,
                animation,
                secondaryAnimation,
              ) {
                return SharedAxisTransition(
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  transitionType: SharedAxisTransitionType.vertical,
                  fillColor: Colors.transparent,
                  child: child,
                );
              },
              child: !_isSetPasswordDone
                  ? SetPassword(
                      controller: _passwordController,
                      onSetPassword: () {
                        setState(() {
                          _isSetPasswordDone = true;
                        });
                      },
                    )
                  : SecurityQuestion(
                      onSubmit: (questions) {
                        if (questions == null) {
                          setState(() {
                            _isSetPasswordDone = false;
                          });
                        } else {
                          final password = _passwordController.text;
                          widget.verifyContrller
                              .initPassword(password, questions)
                              .then((value) {
                            Navigator.pushReplacementNamed(
                                context, Home.routeName);
                          }, onError: (error) {
                            if (kDebugMode) {
                              print(error);
                            }
                          });
                        }
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class SetPassword extends StatelessWidget {
  const SetPassword({
    super.key,
    required this.controller,
    required this.onSetPassword,
  });

  final TextEditingController controller;
  final void Function() onSetPassword;

  @override
  Widget build(BuildContext context) {
    final GlobalKey<FormState> formState = GlobalKey<FormState>();

    final t = I18n.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          t.app_name,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(t.init_main_password, textAlign: TextAlign.center),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Form(
            key: formState,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 264),
                  child: TextFormField(
                    controller: controller,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: t.password,
                      hintText: t.input_num_password,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.length < 4
                        ? t.at_least_4digits
                        : null,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  constraints: const BoxConstraints(maxWidth: 264),
                  child: TextFormField(
                    textInputAction: TextInputAction.done,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: t.confirm_password,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => value == null ||
                            value.isEmpty ||
                            value == controller.text
                        ? null
                        : t.password_not_equal,
                    onFieldSubmitted: (value) {
                      if (formState.currentState!.validate()) {
                        onSetPassword();
                      }
                    },
                  ),
                ),
                Container(
                  width: 180,
                  padding: const EdgeInsets.only(top: 24),
                  child: ElevatedButton(
                    onPressed: () {
                      if (formState.currentState!.validate()) {
                        onSetPassword();
                      }
                    },
                    child: Text(t.init),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
