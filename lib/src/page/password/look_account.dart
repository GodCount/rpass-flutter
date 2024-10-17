import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:logging/logging.dart';

import '../page.dart';
import '../../context/kdbx.dart';
import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../util/common.dart';
import '../../util/one_time_password.dart';
import '../../widget/chip_list.dart';
import '../../widget/common.dart';
import '../../widget/extension_state.dart';

final _logger = Logger("page:look_account");

class LookAccountPage extends StatefulWidget {
  const LookAccountPage({super.key});

  static const routeName = "/look_account";

  @override
  State<LookAccountPage> createState() => _LookAccountPageState();
}

class _LookAccountPageState extends State<LookAccountPage>
    with HintEmptyTextUtil {
  KdbxEntry? _kdbxEntry;

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    _kdbxEntry ??= ModalRoute.of(context)!.settings.arguments as KdbxEntry?;

    if (_kdbxEntry == null) {
      _logger.warning("open look account page _kdbxEntry is null");
      return Scaffold(
        appBar: AppBar(
          title: Text(t.lookup),
        ),
        body: const Center(
          child: Text("没有找到实体！"),
        ),
      );
    }

    final defaultFields = [
      ...KdbxKeyCommon.all,
      ...KdbxKeySpecial.all,
    ];

    final customFields = _kdbxEntry!.stringEntries
        .where((item) => !defaultFields.contains(item.key));

    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(6.0), bottomRight: Radius.circular(6.0)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(t.lookup),
        actions: [
          IconButton(
            onPressed:
                !_kdbxEntry!.isHistoryEntry && !_kdbxEntry!.isInRecycleBin()
                    ? _deleteAccount
                    : null,
            icon: const Icon(Icons.delete),
          ),
          IconButton(
            onPressed: !_kdbxEntry!.isHistoryEntry
                ? () => showEntryHistoryList(_kdbxEntry!)
                : null,
            icon: const Icon(Icons.history_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(6),
        children: [
          _cardColumn([
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: KdbxIconWidget(
                      kdbxIcon: KdbxIconWidgetData(
                        icon: _kdbxEntry!.parent?.icon.get() ?? KdbxIcon.Key,
                        customIcon: _kdbxEntry!.parent?.customIcon,
                      ),
                      size: 24,
                    ),
                  ),
                  hintEmptyText(
                    (_kdbxEntry!.parent?.name.get() ?? '').isEmpty,
                    Expanded(
                      child: Text(
                        _kdbxEntry!.parent?.name.get() ?? '',
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]),
          _cardColumn([
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: KdbxIconWidget(
                      kdbxIcon: KdbxIconWidgetData(
                        icon: _kdbxEntry!.icon.get() ?? KdbxIcon.Key,
                        customIcon: _kdbxEntry!.customIcon,
                      ),
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _kdbxEntry!.getNonNullString(KdbxKeyCommon.TITLE),
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
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
                  _kdbxEntry!.getNonNullString(KdbxKeyCommon.URL).isEmpty,
                  Text(
                    _kdbxEntry!.getNonNullString(KdbxKeyCommon.URL),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
              onLongPress:
                  _kdbxEntry!.getNonNullString(KdbxKeyCommon.URL).isNotEmpty
                      ? () => writeClipboard(
                            _kdbxEntry!.getNonNullString(KdbxKeyCommon.URL),
                          )
                      : null,
            ),
            ListTile(
              title: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(t.account),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: hintEmptyText(
                  _kdbxEntry!.getNonNullString(KdbxKeyCommon.USER_NAME).isEmpty,
                  Text(
                    _kdbxEntry!.getNonNullString(KdbxKeyCommon.USER_NAME),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
              onLongPress: _kdbxEntry!
                      .getNonNullString(KdbxKeyCommon.USER_NAME)
                      .isNotEmpty
                  ? () => writeClipboard(
                      _kdbxEntry!.getNonNullString(KdbxKeyCommon.USER_NAME))
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
                  _kdbxEntry!.getNonNullString(KdbxKeyCommon.EMAIL).isEmpty,
                  Text(
                    _kdbxEntry!.getNonNullString(KdbxKeyCommon.EMAIL),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
              onLongPress:
                  _kdbxEntry!.getNonNullString(KdbxKeyCommon.EMAIL).isNotEmpty
                      ? () => writeClipboard(
                          _kdbxEntry!.getNonNullString(KdbxKeyCommon.EMAIL))
                      : null,
            ),
            _LookPasswordListTile(
              shape: shape,
              password: _kdbxEntry!.getNonNullString(KdbxKeyCommon.PASSWORD),
              onLongPress: () => writeClipboard(
                  _kdbxEntry!.getNonNullString(KdbxKeyCommon.PASSWORD)),
            ),
          ]),
          _otp(shape),
          if (customFields.isNotEmpty)
            _cardColumn([
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.add_box_rounded,
                      ),
                    ),
                    Text(
                      "自定义字段",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              ...customFields.map(
                (item) => ListTile(
                  shape: shape,
                  title: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Text(item.key.key),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: hintEmptyText(
                      _kdbxEntry!.getNonNullString(item.key).isEmpty,
                      Text(
                        _kdbxEntry!.getNonNullString(item.key),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ),
                  onLongPress: _kdbxEntry!.getNonNullString(item.key).isNotEmpty
                      ? () =>
                          writeClipboard(_kdbxEntry!.getNonNullString(item.key))
                      : null,
                ),
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
              title: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(t.description),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: hintEmptyText(
                  _kdbxEntry!.getNonNullString(KdbxKeyCommon.NOTES).isEmpty,
                  Text(
                    _kdbxEntry!.getNonNullString(KdbxKeyCommon.NOTES),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
              onTap:
                  _kdbxEntry!.getNonNullString(KdbxKeyCommon.NOTES).isNotEmpty
                      ? _showDescriptionDialog
                      : null,
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
                  _kdbxEntry!.tagList.isEmpty,
                  ChipList(
                    maxHeight: 150,
                    items: _kdbxEntry!.tagList
                        .map(
                          (item) => ChipListItem(
                            label: item,
                            value: item,
                            select: true,
                            deletable: false,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
            ListTile(
              shape: shape,
              title: const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Text("附件"),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: hintEmptyText(
                  _kdbxEntry!.binaryEntries.isEmpty,
                  ChipList(
                    maxHeight: 150,
                    onChipTap: (binary) {
                      showBinaryAction(binary);
                    },
                    items: _kdbxEntry!.binaryEntries
                        .map(
                          (item) => ChipListItem(
                            label: item.key.key,
                            value: item,
                            select: true,
                            deletable: false,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
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
                      Icons.date_range_rounded,
                    ),
                  ),
                  Text(
                    t.date,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            ListTile(
              shape: shape,
              title: const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Text("创建"),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(dateFormat(_kdbxEntry!.times.creationTime.get()!)),
              ),
            ),
            ListTile(
              shape: shape,
              title: const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Text("最近修改"),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                    dateFormat(_kdbxEntry!.times.lastModificationTime.get()!)),
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
                child: Text(_kdbxEntry!.uuid.uuid),
              ),
            ),
          ]),
          const SizedBox(height: 42)
        ],
      ),
      floatingActionButton: !_kdbxEntry!.isHistoryEntry
          ? FloatingActionButton(
              onPressed: () async {
                if (_kdbxEntry!.isInRecycleBin()) {
                  final kdbx = KdbxProvider.of(context)!;
                  kdbx.restoreObject(_kdbxEntry!);
                  if (await kdbxSave(kdbx)) {
                    Navigator.of(context).pop();
                  }
                } else {
                  Navigator.of(context)
                      .pushNamed(EditAccountPage.routeName,
                          arguments: _kdbxEntry)
                      .then((value) {
                    if (value is bool && value) {
                      setState(() {});
                    }
                  });
                }
              },
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(56 / 2),
                ),
              ),
              child: _kdbxEntry!.isInRecycleBin()
                  ? const Icon(Icons.restore_from_trash)
                  : const Icon(Icons.edit),
            )
          : null,
    );
  }

  void _deleteAccount() async {
    final t = I18n.of(context)!;
    if (await showConfirmDialog(
      title: "删除",
      message: "是否将项目移动到回收站!",
    )) {
      final kdbx = KdbxProvider.of(context)!;
      kdbx.deleteEntry(_kdbxEntry!);
      if (await kdbxSave(kdbx)) {
        Navigator.of(context).pop();
      }
    }
  }

  Widget _cardColumn(List<Widget> children) {
    return Card(
      margin: const EdgeInsets.all(6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(6.0)),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _otp(ShapeBorder? shape) {
    return _kdbxEntry!.getNonNullString(KdbxKeyCommon.OTP).isNotEmpty
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
              oneTimePassword: _kdbxEntry!.getNonNullString(KdbxKeyCommon.OTP),
            ),
          ])
        : const SizedBox.shrink();
  }

  void _showDescriptionDialog() {
    Navigator.of(context).pushNamed(
      EditNotes.routeName,
      arguments: EditNotesArgs(
        text: _kdbxEntry!.getNonNullString(KdbxKeyCommon.NOTES),
        readOnly: true,
      ),
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
                t.throw_message(errorMessage),
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
        writeClipboard("${_authOneTimePassword!.code()}");
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
