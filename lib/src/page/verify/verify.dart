import 'package:flutter/material.dart';

import '../../store/verify/contrller.dart';

class VerifyPassword extends StatefulWidget {
  const VerifyPassword({super.key, required this.verifyContrller});

  static const routeName = "/verify";

  final VerifyController verifyContrller;

  @override
  State<VerifyPassword> createState() => VerifyPasswordState();
}

class VerifyPasswordState extends State<VerifyPassword> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Verify page'),
      ),
    );
  }
}
