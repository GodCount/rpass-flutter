import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../widget/verify_password.dart';
import '../../context/kdbx.dart';
import '../../page/page.dart';
import '../../kdbx/kdbx.dart';
import '../../context/biometric.dart';
import '../../util/common.dart';

final _logger = Logger("page:verify_owner");

class VerifyOwnerPage extends StatefulWidget {
  const VerifyOwnerPage({super.key});

  static const routeName = "/verify_owner";

  @override
  State<VerifyOwnerPage> createState() => _VerifyOwnerPageState();
}

class _VerifyOwnerPageState extends State<VerifyOwnerPage> {
  late final RunOnceFunc<OnVerifyPasswordParam> _onceVerifyPassword;

  @override
  void initState() {
    super.initState();
    _onceVerifyPassword = runOnceFunc(_onVerifyPassword);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _onceVerifyPassword(OnVerifyPasswordParam(type: VerifyType.biometric));
      }
    });
  }

  Future<void> _verifyPassword(Kdbx kdbx, String? password) async {
    if (password == null || password.isEmpty) {
      throw Exception("password is empty");
    }
    final credentials = kdbx.createCredentials(password);

    if (credentials.toBase64() != kdbx.credentials.toBase64()) {
      throw Exception("password verify error");
    }
  }

  Future<void> _verifyBiometric(BiometricState biometric) async {
    await biometric.verifyOwner(context);
  }

  Future<void> _onVerifyPassword(OnVerifyPasswordParam param) async {
    final kdbx = KdbxProvider.of(context);
    final biometric = Biometric.of(context);

    if (kdbx == null) {
      Navigator.popUntil(
        context,
        ModalRoute.withName(InitKdbxPage.routeName),
      );
      _logger.warning("verify owner but kdbx is null");
      return;
    }

    switch (param.type) {
      case VerifyType.password:
        await _verifyPassword(kdbx, param.password);
        break;
      case VerifyType.biometric:
        if (!biometric.enable) {
          return;
        }
        await _verifyBiometric(biometric);
        break;
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
        child: VerifyPassword(
          biometric: true,
          onVerifyPassword: _onceVerifyPassword,
        ),
      ),
    );
  }
}
