import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:animations/animations.dart';
import 'package:flutter/services.dart';

import '../../store/verify/contrller.dart';
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
                            Navigator.pushReplacementNamed(context, "/");
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Hi David Park',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text('Sign in with your account', textAlign: TextAlign.center),
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
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    autofocus: true,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                        labelText: "init password",
                        border: OutlineInputBorder()),
                    validator: (value) {
                      return value == null || value.trim().isEmpty
                          ? "be not empty"
                          : value.length > 3
                              ? null
                              : "must length > 3";
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  constraints: const BoxConstraints(maxWidth: 264),
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    autofocus: true,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: "init password",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      return value == controller.text ? null : "must equal";
                    },
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
                    child: const Text("初始化"),
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