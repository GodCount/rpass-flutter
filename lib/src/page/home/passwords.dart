import 'package:flutter/material.dart';

import '../../model/account.dart';
import '../page.dart';
import '../../store/accounts/contrller.dart';
import '../test.dart';

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
    final accountList = widget.accountsContrller.accountList;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("密码"),
      ),
      body: ListView.builder(
          prototypeItem: _PasswordItem(
            account: Account(
              id: "0",
              domainName: "prototype item",
              domain: "flutter.com",
              account: "flutter",
              password: "111111",
              email: "flutter",
              labels: ["test", "prototype"],
            ),
          ),
          itemCount: accountList.length,
          itemBuilder: (context, index) {
            return _PasswordItem(
              account: accountList[index],
            );
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // generateTestData(100);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PasswordItem extends StatefulWidget {
  const _PasswordItem({required this.account});

  final Account account;

  @override
  State<_PasswordItem> createState() => _PasswordItemState();
}

class _PasswordItemState extends State<_PasswordItem> {
  @override
  Widget build(BuildContext context) {
    final Account account = widget.account;
    return ListTile(
      leading: Text(
        account.account.substring(0, 1),
        style: TextStyle(backgroundColor: Theme.of(context).primaryColor),
      ),
      title: Text(account.domainName),
      subtitle: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(account.domain),
          ),
          Text("A. ${account.domain}"),
          Text("E. ${account.email}"),
          Text("L. ${account.labels.join(",")}"),
          Align(
            alignment: Alignment.centerRight,
            child: Text(account.date.toString()),
          ),
        ],
      ),
      onTap: () {},
      onLongPress: () {},
    );
  }
}
