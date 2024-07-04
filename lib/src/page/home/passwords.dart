import 'package:flutter/material.dart';

import '../page.dart';
import '../../store/accounts/contrller.dart';

class PasswordsPage extends StatefulWidget {
  const PasswordsPage({super.key, required this.accountsContrller});

  final AccountsContrller accountsContrller;

  @override
  State<PasswordsPage> createState() => PasswordsPageState();
}

class PasswordsPageState extends State<PasswordsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 2,
        automaticallyImplyLeading: false,
        title: const Text("密码"),
      ),
      body: Container(
        color: Colors.amber,
      ),
    );
  }
}
