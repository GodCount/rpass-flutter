import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../context/store.dart';
import '../../i18n.dart';
import './forget.dart';
import '../home/home.dart';

class VerifyPassword extends StatefulWidget {
  const VerifyPassword({super.key});

  static const routeName = "/verify";

  @override
  State<VerifyPassword> createState() => VerifyPasswordState();
}

class VerifyPasswordState extends State<VerifyPassword> {
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _obscureText = true;
  String? _errorMessage;

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

  void _verifyPassword() {
    if (_passwordController.text.isNotEmpty) {
      try {
        StoreProvider.of(context).verify.verify(_passwordController.text);
        Navigator.of(context).pushReplacementNamed(Home.routeName);
      } catch (error) {
        if (kDebugMode) {
          print(error);
        }
        setState(() {
          _errorMessage = error.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

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
        ),
      ),
    );
  }
}
