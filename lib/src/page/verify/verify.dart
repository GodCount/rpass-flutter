import 'package:biometric_storage/biometric_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../component/toast.dart';
import '../../i18n.dart';
import '../../store/verify/contrller.dart';
import '../widget/biometric.dart';
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
  bool _biometricDisable = false;
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
    _verifyBiometric();
    super.initState();
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
          _errorMessage = error.toString();
        });
      }
    }
  }

  void _verifyBiometric() async {
    try {
      final biometric = Biometric.of(context);
      if (biometric.enable) {
        await biometric.verify();
        Navigator.of(context).pushReplacementNamed(Home.routeName);
      }
    } on AuthException catch (e) {
      if (e.code == AuthExceptionCode.userCanceled ||
          e.code == AuthExceptionCode.canceled ||
          e.code == AuthExceptionCode.timeout) {
        return;
      }
      rethrow;
    } catch (e) {
      showToast(context, I18n.of(context)!.biometric_throw(e.toString()));
      setState(() {
        _biometricDisable = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    final biometric = Biometric.of(context);
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
                if (biometric.enable)
                  Container(
                    width: 180,
                    padding: const EdgeInsets.only(top: 12),
                    child: ElevatedButton(
                      onPressed: !_biometricDisable ? _verifyBiometric : null,
                      child: Text(t.biometric),
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
