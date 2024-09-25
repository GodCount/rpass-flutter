import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:animated_flip_counter/animated_flip_counter.dart';

import '../../component/label_list.dart';
import '../../component/toast.dart';
import '../../context/store.dart';
import '../../i18n.dart';
import '../../model/rpass/account.dart';
import '../../util/common.dart';
import '../../util/one_time_password.dart';
import '../widget/utils.dart';
import './edit_account.dart';

class LookAccountPage extends StatefulWidget {
  const LookAccountPage({
    super.key,
    required this.accountId,
  });

  final String accountId;

  static const routeName = "/look_account";

  @override
  State<LookAccountPage> createState() => _LookAccountPageState();
}

class _LookAccountPageState extends State<LookAccountPage>
    with HintEmptyTextUtil, CommonWidgetUtil {
  late Account _account = Account();

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      try {
        _account =
            StoreProvider.of(context).accounts.getAccountById(widget.accountId);
      } catch (e) {
        Navigator.of(context).pop();
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;
    final store = StoreProvider.of(context);

    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(6.0), bottomRight: Radius.circular(6.0)),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(t.lookup),
        actions: [
          IconButton(
            onPressed: _deleteAccount,
            icon: const Icon(Icons.delete),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                return EditAccountPage(
                  accountId: _account.id,
                );
              })).then((value) {
                if (value is String && store.accounts.hasAccountById(value)) {
                  _account = store.accounts.getAccountById(value);
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
                    t.source,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            ListTile(
              title: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(t.domain),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: hintEmptyText(
                  _account.domain.isEmpty,
                  Text(
                    _account.domain,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
              onLongPress: _account.domain.isNotEmpty
                  ? () => writeClipboard(_account.domain)
                  : null,
            ),
            ListTile(
              shape: shape,
              title: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(t.domain_title),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: hintEmptyText(
                  _account.domainName.isEmpty,
                  Text(
                    _account.domainName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
              onLongPress: _account.domainName.isNotEmpty
                  ? () => writeClipboard(_account.domainName)
                  : null,
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
                    t.account,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            ListTile(
              title: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(t.account),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: hintEmptyText(
                  _account.account.isEmpty,
                  Text(
                    _account.account,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
              onLongPress: _account.account.isNotEmpty
                  ? () => writeClipboard(_account.account)
                  : null,
            ),
            ListTile(
              title: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(t.email),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: hintEmptyText(
                  _account.account.isEmpty,
                  Text(
                    _account.email,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
              onLongPress: _account.email.isNotEmpty
                  ? () => writeClipboard(_account.email)
                  : null,
            ),
            _LookPasswordListTile(
              shape: shape,
              password: _account.password,
              onLongPress: () => writeClipboard(_account.password),
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
                    t.remark,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            ListTile(
              shape: shape,
              title: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(t.label),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: hintEmptyText(
                  _account.labels.isEmpty,
                  LabelList(
                    preview: true,
                    items: _account.labels
                        .map((value) => LabelItem(value: value))
                        .toList(),
                  ),
                ),
              ),
            ),
            ListTile(
              shape: shape,
              title: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(t.description),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: hintEmptyText(
                  _account.description.isEmpty,
                  Text(
                    _account.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
              onLongPress: _account.description.isNotEmpty
                  ? _showDescriptionDialog
                  : null,
            ),
          ]),
          _cardColumn([
            ListTile(
              shape: shape,
              title: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(t.date),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(dateFormat(_account.date)),
              ),
            ),
            ListTile(
              shape: shape,
              title: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(t.uuid),
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
    final t = I18n.of(context)!;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t.delete),
          content: Text(t.delete_warn_hit),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(t.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(t.delete),
            ),
          ],
        );
      },
    ).then((value) async {
      if (value is bool && value) {
        try {
          await StoreProvider.of(context).accounts.removeAccount(_account.id);
          if (mounted) {
            Navigator.of(context).pop();
          }
        } catch (e) {
          showToast(context, t.account_delete_throw(e.toString()));
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
                    I18n.of(context)!.otp,
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
    final t = I18n.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t.description),
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
              child: Text(t.cancel),
            ),
          ],
        );
      },
    );
  }
}

class _LookPasswordListTile extends StatefulWidget {
  const _LookPasswordListTile({
    required this.password,
    this.onLongPress,
    this.shape,
  });

  final String password;
  final GestureTapCallback? onLongPress;
  final ShapeBorder? shape;

  @override
  State<_LookPasswordListTile> createState() => _LookPasswordListTileState();
}

class _LookPasswordListTileState extends State<_LookPasswordListTile>
    with HintEmptyTextUtil {
  bool showPassword = false;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: widget.shape,
      title: Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Text(I18n.of(context)!.password),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: hintEmptyText(
          widget.password.isEmpty,
          Text(
            showPassword ? widget.password : "*" * widget.password.length,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      ),
      trailing: widget.password.isNotEmpty
          ? IconButton(
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
            )
          : null,
      onLongPress: widget.password.isNotEmpty ? widget.onLongPress : null,
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
  String errorMessage = "";

  @override
  void initState() {
    try {
      _authOneTimePassword = AuthOneTimePassword.parse(widget.oneTimePassword);
    } catch (e) {
      errorMessage = e.toString();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;
    return ListTile(
      shape: widget.shape,
      title: Padding(
        padding: const EdgeInsets.only(left: 6),
        child: _authOneTimePassword != null
            ? AnimatedFlipCounter(
                duration: const Duration(milliseconds: 900),
                value: _authOneTimePassword!.code(),
                mainAxisAlignment: MainAxisAlignment.start,
                thousandSeparator: " ",
                wholeDigits: 6,
                textStyle: Theme.of(context).textTheme.headlineMedium,
              )
            : Text(
                t.calculate_otp_throw(errorMessage),
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
      onLongPress: () {
        Clipboard.setData(
          ClipboardData(
            text: "${_authOneTimePassword!.code()}",
          ),
        ).then((value) {
          showToast(context, t.copy_done);
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
      } else if (status == AnimationStatus.reverse) {
        Timer(const Duration(milliseconds: 100), widget.onUpdate);
      } else if (status == AnimationStatus.dismissed) {
        _controller.forward(from: widget.authOneTimePassword.percent());
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
