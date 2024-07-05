import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import '../../store/verify/contrller.dart';
import './forget.dart';
import '../home/home.dart';

class VerifyPassword extends StatefulWidget {
  const VerifyPassword({super.key, required this.verifyContrller});

  static const routeName = "/verify";

  final VerifyController verifyContrller;

  @override
  State<VerifyPassword> createState() => VerifyPasswordState();
}

class VerifyPasswordState extends State<VerifyPassword> {
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _obscureText = true;
  String? _errorHitText;

  @override
  void initState() {
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _errorHitText != null) {
        setState(() {
          _errorHitText = null;
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print("build verify password");
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hi David Park',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('Sign in with your account',
                      textAlign: TextAlign.center),
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
                        labelText: "input password",
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
                Container(
                  constraints: const BoxConstraints(maxWidth: 264),
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context)
                              .pushNamed(ForgetPassword.routeName);
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _verifyPassword() {
    if (_passwordController.text.isNotEmpty) {
      try {
        widget.verifyContrller.verify(_passwordController.text);
        Navigator.of(context).pushReplacementNamed(Home.routeName);
      } catch (error) {
        if (kDebugMode) {
          print(error);
        }
        setState(() {
          _errorHitText = error.toString();
        });
      }
    }
  }
}
