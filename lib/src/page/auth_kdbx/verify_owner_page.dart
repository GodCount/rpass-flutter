import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

import '../../context/biometric.dart';
import '../../context/kdbx.dart';
import '../../kdbx/kdbx.dart';
import '../../util/route.dart';
import 'authorized_page.dart';

class _VerifyOwnerArgs extends PageRouteArgs {
  _VerifyOwnerArgs({super.key});
}

class VerifyOwnerRoute extends PageRouteInfo<_VerifyOwnerArgs> {
  VerifyOwnerRoute({
    Key? key,
  }) : super(
          name,
          args: _VerifyOwnerArgs(key: key),
        );

  static const name = "VerifyOwnerRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_VerifyOwnerArgs>(
        orElse: () => _VerifyOwnerArgs(),
      );
      return VerifyOwnerPage(key: args.key);
    },
  );
}

class VerifyOwnerPage extends AuthorizedPage {
  const VerifyOwnerPage({super.key});

  @override
  AuthorizedPageState<VerifyOwnerPage> createState() => _VerifyOwnerPageState();
}

class _VerifyOwnerPageState extends AuthorizedPageState<VerifyOwnerPage> {
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

      context.router.pop();
    }
  }

  @override
  Future<void> verifyBiometric() async {
    await Biometric.of(context).verifyOwner(context);
    context.router.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: super.build(context),
    );
  }
}
