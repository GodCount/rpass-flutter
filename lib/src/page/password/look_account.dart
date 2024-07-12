import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../component/label_list.dart';
import '../../component/toast.dart';
import '../../model/account.dart';
import '../../store/accounts/contrller.dart';
import '../../util/one_time_password.dart';
import './edit_account.dart';

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
  late Account _account;

  @override
  void initState() {
    try {
      _account = widget.accountsContrller.getAccountById(widget.accountId);
    } catch (e) {
      Navigator.of(context).pop();
    }
    super.initState();
  }

  void writeClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((value) {
      showToast(context, "复制完成!");
    }, onError: (error) {
      showToast(context, error.toString());
    });
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
        actions: [
          IconButton(
            onPressed: _deleteAccount,
            icon: const Icon(Icons.delete),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                return EditAccountPage(
                  accountsContrller: widget.accountsContrller,
                  accountId: _account.id,
                );
              })).then((value) {
                if (value is String && value == _account.id) {
                  _account = widget.accountsContrller.getAccountById(value);
                  setState(() {});
                }
              });
            },
            icon: const Icon(Icons.edit),
          ),
        ],
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
                child: Text("域名"),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  _account.domain,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              onTap: () => writeClipboard(_account.domain),
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
              onTap: () => writeClipboard(_account.domainName),
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
                      Icons.account_box_outlined,
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
              onTap: () => writeClipboard(_account.account),
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
              onTap: () => writeClipboard(_account.email),
            ),
            _LookPasswordListTile(
              shape: shape,
              password: _account.password,
              onTap: () => writeClipboard(_account.password),
            ),
          ]),
          _otp(shape),
          _cardColumn([
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.description_outlined,
                    ),
                  ),
                  Text(
                    "备注",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            ListTile(
              shape: shape,
              title: const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Text("标签"),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: LabelList(
                  preview: true,
                  items: _account.labels
                      .map((value) => LabelItem(value: value))
                      .toList(),
                ),
              ),
            ),
            ListTile(
              shape: shape,
              title: const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Text("描述"),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  _account.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              onLongPress: _showDescriptionDialog,
            ),
          ]),
          _cardColumn([
            ListTile(
              shape: shape,
              title: const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Text("日期"),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(_account.date.toString()),
              ),
            ),
            ListTile(
              shape: shape,
              title: const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Text("ID"),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(_account.id),
              ),
            ),
          ])
        ],
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("删除"),
          content: const Text("确定要删除账号吗, 删除后将无法恢复."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("取消"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text("删除"),
            ),
          ],
        );
      },
    ).then((value) async {
      if (value is bool && value) {
        try {
          await widget.accountsContrller.removeAccount(_account.id);
          if (mounted) {
            Navigator.of(context).pop();
          }
        } catch (e) {
          showToast(context, "账号删除异常: ${e.toString()}");
        }
      }
    });
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

  Widget _otp(ShapeBorder? shape) {
    return _account.oneTimePassword != null &&
            _account.oneTimePassword!.isNotEmpty
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
                    "一次性密码(OTP)",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            _LookOtPasswordListTile(
              shape: shape,
              oneTimePassword: _account.oneTimePassword!,
            ),
          ])
        : const SizedBox.shrink();
  }

  void _showDescriptionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("备注"),
          content: SelectableText(
            _account.description,
            maxLines: 10,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("取消"),
            ),
          ],
        );
      },
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
  const _LookOtPasswordListTile({
    required this.oneTimePassword,
    this.shape,
  });

  final String oneTimePassword;
  final ShapeBorder? shape;

  @override
  State<_LookOtPasswordListTile> createState() =>
      _LookOtPasswordListTileState();
}

class _LookOtPasswordListTileState extends State<_LookOtPasswordListTile> {
  AuthOneTimePassword? _authOneTimePassword;
  String errorText = "";

  @override
  void initState() {
    try {
      _authOneTimePassword = AuthOneTimePassword.parse(widget.oneTimePassword);
    } catch (e) {
      errorText = "解析一次性密码(OTP)异常! ${e.toString()}";
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: widget.shape,
      title: Padding(
        padding: const EdgeInsets.only(left: 6),
        child: _authOneTimePassword != null
            ? Text(
                _authOneTimePassword!.code(),
                style: Theme.of(context).textTheme.titleLarge,
              )
            : Text(
                errorText,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Colors.redAccent),
              ),
      ),
      trailing: _authOneTimePassword != null
          ? _OtpDownCount(
              authOneTimePassword: _authOneTimePassword!,
              onUpdate: () {
                setState(() {});
              },
            )
          : null,
      onTap: () {
        Clipboard.setData(
          ClipboardData(
            text: _authOneTimePassword!.code(),
          ),
        ).then((value) {
          showToast(context, "复制完成!");
        }, onError: (error) {
          showToast(context, error.toString());
        });
      },
    );
  }
}

typedef OnUpdateCallback = void Function();

class _OtpDownCount extends StatefulWidget {
  const _OtpDownCount(
      {required this.authOneTimePassword, required this.onUpdate});

  final AuthOneTimePassword authOneTimePassword;
  final OnUpdateCallback onUpdate;

  @override
  State<_OtpDownCount> createState() => _OtpDownCountState();
}

class _OtpDownCountState extends State<_OtpDownCount>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    _controller = AnimationController(
      reverseDuration: const Duration(seconds: 1),
      duration: Duration(seconds: widget.authOneTimePassword.period),
      vsync: this,
    )..repeat();

    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller);

    _animation.addListener(() {
      setState(() => {});
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _controller.forward(from: widget.authOneTimePassword.percent());
        widget.onUpdate();
      }
    });

    _controller.forward(from: widget.authOneTimePassword.percent());
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String downcount() {
    return (widget.authOneTimePassword.period -
            (_animation.value * widget.authOneTimePassword.period))
        .round()
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          CircularProgressIndicator(
            value: _animation.value,
            backgroundColor: Colors.grey[400],
          ),
          Text(downcount()),
        ],
      ),
    );
  }
}
