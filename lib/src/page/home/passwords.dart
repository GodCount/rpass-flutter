import 'package:flutter/material.dart';

import '../page.dart';
import '../../store/accounts/contrller.dart';

class PasswordsPage extends StatefulWidget {
  const PasswordsPage({super.key, required this.accountsContrller});

  final AccountsContrller accountsContrller;

  @override
  State<PasswordsPage> createState() => PasswordsPageState();
}

class PasswordsPageState extends State<PasswordsPage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.amberAccent,
      body: Center(
        child: Text("password list"),
      ),
    );
  }
}
