import 'package:flutter/widgets.dart';

import '../../context/biometric.dart';
import '../../context/kdbx.dart';
import '../../kdbx/kdbx.dart';
import 'authorized_page.dart';

class VerifyOwnerPage extends AuthorizedPage {
  const VerifyOwnerPage({super.key});

  static const routeName = "/verify_owner";

  @override
  VerifyOwnerPageState createState() => VerifyOwnerPageState();
}

class VerifyOwnerPageState extends AuthorizedPageState {
  @override
  AuthorizedType get authType => AuthorizedType.verify_owner;

  @override
  bool get enableBiometric => true;

  @override
  Future<void> confirm() async {
    if (form.currentState!.validate()) {
      final passowrd = passwordController.text;
      final keyFile = keyFilecontroller.keyFile;

      if (!isPassword && keyFile == null) {
        throw Exception("Lack of key file.");
      }

      final kdbx = KdbxProvider.of(context)!;

      final credentials =
          Kdbx.createCredentials(isPassword ? passowrd : null, keyFile?.$2);

      if (credentials.toBase64() != kdbx.credentials.toBase64()) {
        throw Exception("password verify error");
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Future<void> verifyBiometric() async {
    await Biometric.of(context).verifyOwner(context);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: super.build(context),
    );
  }
}
