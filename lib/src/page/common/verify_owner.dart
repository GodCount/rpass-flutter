import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../widget/verify_password.dart';
import '../../context/kdbx.dart';
import '../../page/page.dart';
import '../../kdbx/kdbx.dart';
import '../../context/biometric.dart';

final _logger = Logger("page:verify_owner");

class VerifyOwnerPage extends StatefulWidget {
  const VerifyOwnerPage({super.key});

  static const routeName = "/verify_owner";

  @override
  State<VerifyOwnerPage> createState() => _VerifyOwnerPageState();
}

class _VerifyOwnerPageState extends State<VerifyOwnerPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      _onVerifyPassword(VerifyType.biometric);
    }
  }

  Future<void> _verifyPassword(String? password) async {
    if (password == null || password.isEmpty) {
      throw Exception("password is empty");
    }
    final kdbx = KdbxProvider.of(context)!;
    final credentials = kdbx.createCredentials(password);

    if (credentials.toBase64() != kdbx.credentials.toBase64()) {
      throw Exception("password verify error");
    }
  }

  Future<void> _verifyBiometric() async {
    final biometric = Biometric.of(context);
    if (!await biometric.verifyOwner(context)) {
      throw Exception("biometric verify error");
    }
  }

  Future<void> _onVerifyPassword(
    VerifyType type, [
    String? password,
  ]) async {
    final kdbx = KdbxProvider.of(context);

    if (kdbx == null) {
      Navigator.popUntil(
        context,
        ModalRoute.withName(InitKdbxPage.routeName),
      );
      _logger.warning("verify owner but kdbx is null");
      return;
    }

    switch (type) {
      case VerifyType.password:
        await _verifyPassword(password);
      case VerifyType.biometric:
        await _verifyBiometric();
    }

    Navigator.pop(context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onVerifyPassword(VerifyType.biometric);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
        child: VerifyPassword(
          biometric: true,
          autoPopUpBiometric: false,
          onVerifyPassword: _onVerifyPassword,
        ),
      ),
    );
  }
}
