import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:logging/logging.dart';
import 'package:rich_text_controller/rich_text_controller.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../native/channel.dart';
import '../../util/route.dart';
import '../route.dart';
import '../../context/kdbx.dart';
import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../util/common.dart';
import '../../util/one_time_password.dart';
import '../../widget/chip_list.dart';
import '../../widget/common.dart';
import '../../widget/extension_state.dart';

final _logger = Logger("page:look_account");

class _LookAccountArgs extends PageRouteArgs {
  _LookAccountArgs({
    super.key,
    this.readOnly = false,
    required this.kdbxEntry,
  });
  final bool readOnly;
  final KdbxEntry kdbxEntry;
}

class LookAccountRoute extends PageRouteInfo<_LookAccountArgs> {
  LookAccountRoute({
    Key? key,
    bool readOnly = false,
    required KdbxEntry kdbxEntry,
    KdbxUuid? uuid,
  }) : super(
          name,
          args: _LookAccountArgs(
            key: key,
            readOnly: readOnly,
            kdbxEntry: kdbxEntry,
          ),
          rawQueryParams: {
            "readOnly": readOnly,
          },
          rawPathParams: {
            "uuid": uuid?.deBase64Uuid,
          },
        );

  static const name = "LookAccountRoute";

  static final PageInfo page = PageInfo.builder(
    name,
    builder: (context, data) {
      final args = data.argsAs<_LookAccountArgs>(
        orElse: () {
          final kdbx = KdbxProvider.of(context)!;
          final readOnly = data.queryParams.getBool("readOnly", false);
          final uuid = data.inheritedPathParams.optString("uuid")?.kdbxUuid;
          final kdbxEntry = uuid != null ? kdbx.findEntryByUuid(uuid) : null;

          if (kdbxEntry == null) {
            throw Exception("kdbxEntry is null, Not found by uuid: $uuid");
          }
          return _LookAccountArgs(
            kdbxEntry: kdbxEntry,
            readOnly: readOnly,
          );
        },
      );

      return LookAccountPage(
        key: args.key,
        readOnly: args.readOnly,
        kdbxEntry: args.kdbxEntry,
      );
    },
  );
}

class LookAccountPage extends StatefulWidget {
  const LookAccountPage({
    super.key,
    this.readOnly = false,
    required this.kdbxEntry,
  });

  final bool readOnly;
  final KdbxEntry kdbxEntry;

  @override
  State<LookAccountPage> createState() => _LookAccountPageState();
}

class _LookAccountPageState extends State<LookAccountPage>
    with
        HintEmptyTextUtil,
        SecondLevelPageAutoBack<LookAccountPage>,
        NativeChannelListener {
  @override
  void initState() {
    NativeInstancePlatform.instance.addListener(this);
    super.initState();
  }

  @override
  void onTargetAppChange(String? name) {
    setState(() {});
  }

  _launchUrl(String url) {
    launchUrl(
      Uri.parse(url.startsWith(RegExp(r"^https*://")) ? url : "http://$url"),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  void dispose() {
    NativeInstancePlatform.instance.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    final kdbxEntry = widget.kdbxEntry;
    final readOnly = widget.readOnly;

    final customFields = kdbxEntry.stringEntries
        .where((item) => !defaultKdbxKeys.contains(item.key));

    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(6.0), bottomRight: Radius.circular(6.0)),
    );

    final title = kdbxEntry.getNonNullString(KdbxKeyCommon.TITLE);
    final url = kdbxEntry.getNonNullString(KdbxKeyCommon.URL);
    final username = kdbxEntry.getNonNullString(KdbxKeyCommon.USER_NAME);
    final password = kdbxEntry.getNonNullString(KdbxKeyCommon.PASSWORD);
    final email = kdbxEntry.getNonNullString(KdbxKeyCommon.EMAIL);
    final notes = kdbxEntry.getNonNullString(KdbxKeyCommon.NOTES);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: automaticallyImplyLeading,
        leading: autoBack(),
        title: Text(t.lookup),
        actions: [
          IconButton(
            onPressed: !readOnly && !kdbxEntry.isInRecycleBin()
                ? _deleteAccount
                : null,
            icon: const Icon(Icons.delete),
          ),
          IconButton(
            onPressed: !readOnly ? () => showEntryHistoryList(kdbxEntry) : null,
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
                        icon: kdbxEntry.parent.icon.get() ?? KdbxIcon.Key,
                        customIcon: kdbxEntry.parent.customIcon,
                      ),
                      size: 24,
                    ),
                  ),
                  hintEmptyText(
                    (kdbxEntry.parent.name.get() ?? '').isEmpty,
                    Expanded(
                      child: Text(
                        kdbxEntry.parent.name.get() ?? '',
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
                        icon: kdbxEntry.icon.get() ?? KdbxIcon.Key,
                        customIcon: kdbxEntry.customIcon,
                      ),
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      kdbxEntry.isExpiry() ? "$title (${t.expires})" : title,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: kdbxEntry.isExpiry()
                          ? Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.error)
                          : Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ),
            if (isDesktop)
              ListTile(
                title: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    "${t.auto_fill}${NativeInstancePlatform.instance.isTargetAppExist ? " (${NativeInstancePlatform.instance.targetAppName})" : ""}",
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: RichWrapper(
                    initialText: kdbxEntry.getAutoTypeSequence(),
                    targetMatches: [
                      MatchTargetItem.pattern(
                        AutoTypeRichPattern.BUTTON,
                        allowInlineMatching: true,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall!
                            .copyWith(color: Colors.blueAccent),
                      ),
                      MatchTargetItem.pattern(
                        AutoTypeRichPattern.KDBX_KEY,
                        allowInlineMatching: true,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall!
                            .copyWith(color: Colors.green),
                      ),
                      MatchTargetItem.pattern(
                        AutoTypeRichPattern.SHORTCUT_KEY,
                        allowInlineMatching: true,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall!
                            .copyWith(color: Colors.orangeAccent),
                      )
                    ],
                    child: (controller) {
                      return RichText(
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        text: controller.buildTextSpan(
                          context: context,
                          style: Theme.of(context).textTheme.titleSmall,
                          withComposing: true,
                        ),
                      );
                    },
                  ),
                ),
                trailing: IconButton(
                  onPressed: NativeInstancePlatform.instance.isTargetAppExist
                      ? () async {
                          await kdbxEntry.autoFill();
                        }
                      : null,
                  icon: const Icon(Icons.ads_click),
                ),
                // onLongPress: () => writeClipboard(
                //   kdbxEntry.getAutoTypeSequence(),
                // ),
              ),
            ListTile(
              title: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(t.domain),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: hintEmptyText(
                  url.isEmpty,
                  Text(
                    url,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
              trailing: IconButton(
                onPressed: url.isNotEmpty ? () => _launchUrl(url) : null,
                icon: const Icon(Icons.open_in_new),
              ),
              onLongPress: url.isNotEmpty
                  ? () => writeClipboard(
                        url,
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
                  username.isEmpty,
                  Text(
                    username,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
              onLongPress:
                  username.isNotEmpty ? () => writeClipboard(username) : null,
            ),
            ListTile(
              title: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(t.email),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: hintEmptyText(
                  email.isEmpty,
                  Text(
                    email,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
              onLongPress:
                  email.isNotEmpty ? () => writeClipboard(email) : null,
            ),
            _LookPasswordListTile(
              shape: shape,
              password: password,
              onLongPress: () => writeClipboard(password),
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
                      t.custom_field,
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
                      kdbxEntry.getNonNullString(item.key).isEmpty,
                      Text(
                        kdbxEntry.getNonNullString(item.key),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ),
                  onLongPress: kdbxEntry.getNonNullString(item.key).isNotEmpty
                      ? () =>
                          writeClipboard(kdbxEntry.getNonNullString(item.key))
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
                  notes.isEmpty,
                  Text(
                    notes,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
              onTap: notes.isNotEmpty ? _showDescriptionDialog : null,
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
                  kdbxEntry.tagList.isEmpty,
                  ChipList(
                    maxHeight: 150,
                    items: kdbxEntry.tagList
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
              title: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(t.attachment),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: hintEmptyText(
                  kdbxEntry.binaryEntries.isEmpty,
                  ChipList(
                    maxHeight: 150,
                    onChipTap: (binary) {
                      showBinaryAction(binary);
                    },
                    items: kdbxEntry.binaryEntries
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
              title: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(t.create),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  kdbxEntry.times.creationTime.get()!.toLocal().formatDate,
                ),
              ),
            ),
            ListTile(
              shape: shape,
              title: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(t.last_modify),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  kdbxEntry.times.lastModificationTime
                      .get()!
                      .toLocal()
                      .formatDate,
                ),
              ),
            ),
            if (kdbxEntry.times.expires.get() == true &&
                kdbxEntry.times.expiryTime.get() != null)
              ListTile(
                shape: shape,
                title: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(t.expires_time),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    kdbxEntry.times.expiryTime.get()!.toLocal().formatDate,
                  ),
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
                child: Text(kdbxEntry.uuid.uuid),
              ),
            ),
          ]),
          const SizedBox(height: 42)
        ],
      ),
      floatingActionButton: !readOnly
          ? FloatingActionButton(
              heroTag: const ValueKey("look_account_float"),
              onPressed: () async {
                if (kdbxEntry.isInRecycleBin()) {
                  final kdbx = KdbxProvider.of(context)!;
                  kdbx.restoreObject(kdbxEntry);
                  if (await kdbxSave(kdbx)) {
                    context.router.pop();
                  }
                } else {
                  final result = await context.router.push(
                    EditAccountRoute(
                      kdbxEntry: kdbxEntry,
                      uuid: kdbxEntry.uuid,
                    ),
                  );
                  if (result is bool && result) {
                    setState(() {});
                  }
                }
              },
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(56 / 2),
                ),
              ),
              child: kdbxEntry.isInRecycleBin()
                  ? const Icon(Icons.restore_from_trash)
                  : const Icon(Icons.edit),
            )
          : null,
    );
  }

  void _deleteAccount() async {
    final t = I18n.of(context)!;
    if (await showConfirmDialog(
      title: t.delete,
      message: t.is_move_recycle,
    )) {
      final kdbx = KdbxProvider.of(context)!;
      kdbx.deleteEntry(widget.kdbxEntry);
      if (await kdbxSave(kdbx)) {
        context.router.pop();
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
    return widget.kdbxEntry.getNonNullString(KdbxKeyCommon.OTP).isNotEmpty
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
              oneTimePassword:
                  widget.kdbxEntry.getNonNullString(KdbxKeyCommon.OTP),
            ),
          ])
        : const SizedBox.shrink();
  }

  void _showDescriptionDialog() {
    context.router.push(
      EditNotesRoute(
        text: widget.kdbxEntry.getNonNullString(KdbxKeyCommon.NOTES),
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
