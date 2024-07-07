import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../model/account.dart';
import '../../store/accounts/contrller.dart';

class LookAccountPage extends StatefulWidget {
  const LookAccountPage({
    super.key,
    required this.accountsContrller,
    required this.accountId,
  });

  final AccountsContrller accountsContrller;
  final String accountId;

  static const routeName = "/look_account";

  @override
  State<LookAccountPage> createState() => _LookAccountPageState();
}

class _LookAccountPageState extends State<LookAccountPage> {
  late final Account _account;

  @override
  void initState() {
    try {
      _account = widget.accountsContrller.getAccountById(widget.accountId);
    } catch (e) {
      Navigator.of(context).pop();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(6.0), bottomRight: Radius.circular(6.0)),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text("查看"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _cardColumn([
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.domain,
                    ),
                  ),
                  Text(
                    "来源",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Text("网站域名"),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  _account.domain,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              onTap: () {},
            ),
            ListTile(
              shape: shape,
              title: const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Text("网站名"),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  _account.domainName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              onTap: () {},
            ),
          ]),
          _cardColumn([
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.account_box,
                    ),
                  ),
                  Text(
                    "账号",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Text("账号"),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  _account.account,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              onTap: () {},
            ),
            ListTile(
              title: const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Text("邮箱"),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  _account.email,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              onTap: () {},
            ),
            _LookPasswordListTile(
              shape: shape,
              password: _account.password,
              onTap: () {},
            ),
          ]),
          _account.oneTimePassword != null
              ? _cardColumn([
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(
                            Icons.password,
                          ),
                        ),
                        Text(
                          "一次性密码",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  _LookOtPasswordListTile(
                    shape: shape,
                    oneTimePassword: _account.oneTimePassword,
                  ),
                ])
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _cardColumn(List<Widget> children) {
    return Card(
      margin: const EdgeInsets.all(12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(6.0)),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _LookPasswordListTile extends StatefulWidget {
  const _LookPasswordListTile({required this.password, this.onTap, this.shape});

  final String password;
  final GestureTapCallback? onTap;
  final ShapeBorder? shape;

  @override
  State<_LookPasswordListTile> createState() => _LookPasswordListTileState();
}

class _LookPasswordListTileState extends State<_LookPasswordListTile> {
  bool showPassword = false;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: widget.shape,
      title: const Padding(
        padding: EdgeInsets.only(left: 6),
        child: Text("密码"),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Text(
          showPassword ? widget.password : "*" * widget.password.length,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
      trailing: IconButton(
        onPressed: () {
          setState(() {
            showPassword = !showPassword;
          });
        },
        icon: Icon(
          showPassword
              ? Icons.remove_red_eye_outlined
              : Icons.visibility_off_outlined,
        ),
      ),
      onTap: widget.onTap,
    );
  }
}

class _LookOtPasswordListTile extends StatefulWidget {
  const _LookOtPasswordListTile({required this.oneTimePassword, this.shape});

  final String? oneTimePassword;
  final ShapeBorder? shape;

  @override
  State<_LookOtPasswordListTile> createState() =>
      _LookOtPasswordListTileState();
}

class _LookOtPasswordListTileState extends State<_LookOtPasswordListTile> {
  bool showPassword = false;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: widget.shape,
      title: Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Text(
          "239343289",
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      trailing: IconButton(
        onPressed: () {
          setState(() {
            showPassword = !showPassword;
          });
        },
        icon: Icon(
          showPassword
              ? Icons.remove_red_eye_outlined
              : Icons.visibility_off_outlined,
        ),
      ),
      onTap: () {},
    );
  }
}

class _OtpDownCount extends StatefulWidget {
  const _OtpDownCount({required this.oneTimePassword, this.shape});

  final String? oneTimePassword;
  final ShapeBorder? shape;

  @override
  State<_OtpDownCount> createState() =>
      _OtpDownCountState();
}

class _OtpDownCountState extends State<_OtpDownCount> {
  bool showPassword = false;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: widget.shape,
      title: Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Text(
          "239343289",
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      trailing: IconButton(
        onPressed: () {
          setState(() {
            showPassword = !showPassword;
          });
        },
        icon: Icon(
          showPassword
              ? Icons.remove_red_eye_outlined
              : Icons.visibility_off_outlined,
        ),
      ),
      onTap: () {},
    );
  }
}