import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../widget/verify_password.dart';
import '../../context/kdbx.dart';
import '../../page/page.dart';

final _logger = Logger("page:verify_owner");

class VerifyOwnerPage extends StatefulWidget {
  static const routeName = "/verify_owner";

  @override
  State<VerifyOwnerPage> createState() => _VerifyOwnerPageState();
}

class _VerifyOwnerPageState extends State<VerifyOwnerPage> {
  Future<void> _verifyPassword(String? password) async {
    final kdbx = KdbxProvider.of(context)!;
    
  }

  Future<void> _verifyBiometric() async {
    final kdbx = KdbxProvider.of(context)!;
  }

  @override
  Widget build(BuildContext context) {
    final kdbx = KdbxProvider.of(context);

    return VerifyPassword(onVerifyPassword: (type, [password]) async {
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
    });
  }
}
