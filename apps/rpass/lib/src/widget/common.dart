import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../context/kdbx.dart';
import '../i18n.dart';
import '../kdbx/kdbx.dart';
import '../util/common.dart';
import '../util/one_time_password.dart';
import 'extension_state.dart';
import 'kdbx_icon.dart';

mixin HintEmptyTextUtil<T extends StatefulWidget> on State<T> {
  Widget hintEmptyText(bool isEmpty, Widget widget) {
    return isEmpty
        ? Opacity(
            opacity: .5,
            child: Text(
              I18n.of(context)!.empty,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        : widget;
  }
}

typedef LeadingIconBuilder = Widget Function(InputDialogState state);

class InputDialog extends StatefulWidget {
  const InputDialog({
    super.key,
    this.title,
    this.label,
    this.initialValue,
    this.promptItmes,
    this.limitItems,
    required this.onResult,
    this.leadingBuilder,
  });

  final String? title;
  final String? label;
  final String? initialValue;
  final List<String>? promptItmes;
  final List<String>? limitItems;
  final FormFieldSetter<String> onResult;
  final LeadingIconBuilder? leadingBuilder;

  static Future<Object?> openDialog(
    BuildContext context, {
    String? title,
    String? label,
    String? initialValue,
    List<String>? promptItmes,
    List<String>? limitItems,
    LeadingIconBuilder? leadingBuilder,
  }) {
    return showDialog(
      context: context,
      builder: (context) {
        return InputDialog(
          title: title,
          label: label,
          initialValue: initialValue,
          limitItems: limitItems,
          promptItmes: promptItmes,
          onResult: (value) {
            context.router.pop(value);
          },
          leadingBuilder: leadingBuilder,
        );
      },
    );
  }

  @override
  State<InputDialog> createState() => InputDialogState();
}

class InputDialogState extends State<InputDialog> {
  late final TextEditingController _controller;

  bool isLimitContent = false;

  List<DropdownMenuEntry<String>>? _dropdownMenuEntries;

  @override
  void initState() {
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(_handleControllerChanged);
    if (widget.promptItmes != null) {
      _dropdownMenuEntries = widget.promptItmes!
          .map((value) => DropdownMenuEntry(value: value, label: value))
          .toList();
    }

    super.initState();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void update() {
    setState(() {});
  }

  void _handleControllerChanged() {
    setState(() {
      if (widget.limitItems != null) {
        isLimitContent = widget.limitItems!.contains(_controller.text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    final Widget content;

    Widget? limitIcon;

    final leadingIcon = widget.leadingBuilder != null
        ? widget.leadingBuilder!(this)
        : null;

    if (isLimitContent) {
      limitIcon = Icon(
        Icons.error_outlined,
        color: Theme.of(context).colorScheme.error,
      );
    }

    if (_dropdownMenuEntries != null && _dropdownMenuEntries!.isNotEmpty) {
      content = DropdownMenu(
        width: 230,
        menuHeight: 150,
        label: widget.label != null ? Text(widget.label!) : null,
        enableFilter: true,
        enableSearch: true,
        leadingIcon: leadingIcon,
        trailingIcon: limitIcon,
        selectedTrailingIcon: limitIcon,
        controller: _controller,
        requestFocusOnTap: true,
        expandedInsets: const EdgeInsets.all(0),
        dropdownMenuEntries: _dropdownMenuEntries!,
      );
    } else {
      content = TextField(
        autofocus: true,
        textInputAction: TextInputAction.done,
        controller: _controller,
        decoration: InputDecoration(
          label: widget.label != null ? Text(widget.label!) : null,
          border: const OutlineInputBorder(),
          prefixIcon: leadingIcon,
          suffixIcon: limitIcon,
        ),
      );
    }

    return AlertDialog(
      title: widget.title != null ? Text(widget.title!) : null,
      content: SizedBox(width: 230, child: content),
      actions: [
        TextButton(
          onPressed: () {
            widget.onResult(null);
          },
          child: Text(t.cancel),
        ),
        TextButton(
          onPressed: !isLimitContent && _controller.text.trim().isNotEmpty
              ? () {
                  widget.onResult(_controller.text);
                }
              : null,
          child: Text(t.confirm),
        ),
      ],
    );
  }
}

class GroupSelectorDialog extends StatefulWidget {
  const GroupSelectorDialog({super.key, this.value, required this.onResult});

  final KdbxGroup? value;
  final FormFieldSetter<KdbxGroup> onResult;

  static Future<KdbxGroup?> openDialog(
    BuildContext context, {
    KdbxGroup? value,
  }) {
    return showDialog(
      context: context,
      // fix 在 GroupSelectorDialog 里触发导航 context.router.push 会把页面插入到弹窗下发的问题
      useRootNavigator: kIsDesktop,
      builder: (context) {
        return GroupSelectorDialog(
          value: value,
          onResult: (value) {
            context.router.pop(value);
          },
        );
      },
    );
  }

  @override
  State<GroupSelectorDialog> createState() => _GroupSelectorDialogState();
}

class _GroupSelectorDialogState extends State<GroupSelectorDialog> {
  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;
    final kdbx = KdbxProvider.of(context).kdbx!;

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(t.select_group)),
          IconButton(
            onPressed: () async {
              final uuid = await addKdbxGroup();
              if (uuid != null && uuid is KdbxUuid) {
                return widget.onResult(kdbx.findGroupByUuid(uuid));
              }
              setState(() {});
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      contentPadding: EdgeInsets.only(
        top: Theme.of(context).useMaterial3 ? 16.0 : 20.0,
        right: 0,
        bottom: 24.0,
        left: 0,
      ),
      content: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 312),
        child: ListView(
          shrinkWrap: true,
          children: [kdbx.kdbxFile.body.rootGroup, ...kdbx.rootGroups]
              .map(
                (item) => ListTile(
                  leading: KdbxIconWidget(
                    kdbxIcon: KdbxIconWidgetData(
                      icon: item.icon.get() ?? KdbxIcon.Folder,
                      customIcon: item.customIcon,
                    ),
                  ),
                  title: Text(getKdbxObjectTitle(item)),
                  trailing: item == widget.value
                      ? const Icon(Icons.done)
                      : null,
                  onTap: () {
                    widget.onResult(item == widget.value ? null : item);
                  },
                ),
              )
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onResult(null);
          },
          child: Text(t.cancel),
        ),
      ],
    );
  }
}

class KdbxEntrySelectorDialog extends StatefulWidget {
  const KdbxEntrySelectorDialog({
    super.key,
    this.value,
    this.title,
    required this.onResult,
  });

  final KdbxEntry? value;
  final String? title;
  final FormFieldSetter<KdbxEntry> onResult;

  static Future<KdbxEntry?> openDialog(
    BuildContext context, {
    KdbxEntry? value,
    String? title,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return KdbxEntrySelectorDialog(
          value: value,
          title: title,
          onResult: (value) {
            context.router.pop(value);
          },
        );
      },
    );
  }

  @override
  State<KdbxEntrySelectorDialog> createState() =>
      _KdbxEntrySelectorDialogState();
}

class _KdbxEntrySelectorDialogState extends State<KdbxEntrySelectorDialog> {
  final TextEditingController _searchController = TextEditingController();
  final KbdxSearchHandler _kbdxSearchHandler = KbdxSearchHandler();
  final List<KdbxEntry> _totalEntry = [];

  late KdbxEntry? _selectedKdbxEntry = widget.value;

  @override
  void initState() {
    _searchController.addListener(_searchAccounts);
    _searchAccounts();

    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _totalEntry.clear();
    super.dispose();
  }

  void _searchAccounts() {
    _totalEntry.clear();
    final kdbx = KdbxProvider.of(context).kdbx!;

    _totalEntry.addAll(
      _kbdxSearchHandler.search(_searchController.text, kdbx.totalEntry),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Text(widget.title != null ? widget.title! : t.select_account),
          TextField(
            controller: _searchController,
            autofocus: false,
            style: Theme.of(context).textTheme.bodySmall,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: t.search,
              prefixIcon: IconButton(
                onPressed: showSearchHelpDialog,
                icon: const Icon(Icons.help_outline_rounded),
              ),
            ),
          ),
        ],
      ),
      contentPadding: EdgeInsets.only(
        top: Theme.of(context).useMaterial3 ? 16.0 : 20.0,
        right: 0,
        bottom: 24.0,
        left: 0,
      ),
      content: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 312),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _totalEntry.length,
          itemBuilder: (context, index) {
            KdbxEntry kdbxEntry = _totalEntry[index];
            return ListTile(
              isThreeLine: true,
              selected: _selectedKdbxEntry == kdbxEntry,
              leading: KdbxIconWidget(
                kdbxIcon: KdbxIconWidgetData(
                  icon: kdbxEntry.icon.get() ?? KdbxIcon.Key,
                  customIcon: kdbxEntry.customIcon,
                  domain: kdbxEntry.getActualString(KdbxKeyCommon.URL),
                ),
                size: 24,
              ),
              titleTextStyle: kdbxEntry.isExpiry()
                  ? Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    )
                  : Theme.of(context).textTheme.titleMedium,
              title: Text(
                kdbxEntry.isExpiry()
                    ? "${kdbxEntry.getNonNullString(KdbxKeyCommon.TITLE)} (${t.expires})"
                    : kdbxEntry.getNonNullString(KdbxKeyCommon.TITLE),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      kdbxEntry.getNonNullString(KdbxKeyCommon.URL),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  _subtitleText(
                    t.account_ab,
                    kdbxEntry.getNonNullString(KdbxKeyCommon.USER_NAME),
                  ),
                  _subtitleText(
                    t.email_ab,
                    kdbxEntry.getNonNullString(KdbxKeyCommon.EMAIL),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      kdbxEntry.parent.name.get() ?? '',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              onTap: () {
                setState(() {
                  if (_selectedKdbxEntry == kdbxEntry) {
                    _selectedKdbxEntry = null;
                  } else {
                    _selectedKdbxEntry = kdbxEntry;
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onResult(widget.value);
          },
          child: Text(t.cancel),
        ),
        TextButton(
          onPressed: _selectedKdbxEntry != null
              ? () {
                  widget.onResult(_selectedKdbxEntry);
                }
              : null,
          child: Text(t.confirm),
        ),
      ],
    );
  }

  Widget _subtitleText(String subLabel, String text) {
    return RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: Theme.of(context).textTheme.titleSmall,
        text: "$subLabel ",
        children: [
          TextSpan(style: Theme.of(context).textTheme.bodySmall, text: text),
        ],
      ),
    );
  }
}

class AnimatedIconSwitcher extends StatefulWidget {
  const AnimatedIconSwitcher({super.key, required this.icon});

  final Widget icon;

  @override
  State<AnimatedIconSwitcher> createState() => _AnimatedIconSwitcherState();
}

class _AnimatedIconSwitcherState extends State<AnimatedIconSwitcher> {
  Key? prveKey;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => RotationTransition(
        turns: prveKey != widget.key
            ? Tween<double>(begin: 0.5, end: 0.5).animate(animation)
            : Tween<double>(begin: 0.5, end: 1).animate(animation),
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: widget.icon,
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedIconSwitcher oldWidget) {
    prveKey = oldWidget.key;
    super.didUpdateWidget(oldWidget);
  }
}

class ImageFileString extends StatefulWidget {
  const ImageFileString(
    this.file, {
    super.key,
    this.width,
    this.height,
    this.error,
  });

  final String file;
  final double? width;
  final double? height;

  final Widget? error;

  @override
  State<ImageFileString> createState() => ImageFileStringState();
}

class ImageFileStringState extends State<ImageFileString> {
  late File file = File(widget.file);

  @override
  void didUpdateWidget(covariant ImageFileString oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.file != oldWidget.file) {
      file = File(widget.file);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Image.file(
      file,
      width: widget.width,
      height: widget.height,
      errorBuilder: widget.error != null ? (_, _, _) => widget.error! : null,
    );
  }
}

class QrCodeDialog extends StatefulWidget {
  const QrCodeDialog({
    super.key,
    this.title,
    required this.getQrData,
    this.onClose,
  });

  final ValueGetter<Future<(String, Duration)>> getQrData;
  final VoidCallback? onClose;

  final String? title;

  static Future<void> openDialog(
    BuildContext context, {
    required ValueGetter<Future<(String, Duration)>> getQrData,
    VoidCallback? onClose,
    String? title,
    DialogCloseController? controller,
  }) {
    return showDialog(
      context: context,
      builder: (context) {
        if (controller != null) controller.context = context;

        return Theme(
          data: context.findAncestorWidgetOfExactType<MaterialApp>()!.theme!,
          child: QrCodeDialog(
            getQrData: getQrData,
            title: title,
            onClose: onClose,
          ),
        );
      },
    );
  }

  @override
  State<QrCodeDialog> createState() => _QrCodeDialogState();
}

class _QrCodeDialogState extends State<QrCodeDialog> {
  String? _qrCode;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _refresh();
  }

  void _refresh() async {
    final (data, next) = await widget.getQrData();

    _qrCode = data;

    _timer?.cancel();
    _timer = Timer(next, _refresh);

    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    return AlertDialog(
      title: widget.title != null ? Center(child: Text(widget.title!)) : null,
      actionsAlignment: .center,
      content: _qrCode != null
          ? PrettyQrView.data(
              // fix: set decoration after will not redrawn
              key: ValueKey(_qrCode!),
              data: _qrCode!,
              errorCorrectLevel: QrErrorCorrectLevel.M,
              decoration: const PrettyQrDecoration(
                image: PrettyQrDecorationImage(
                  padding: EdgeInsets.all(30),
                  image: AssetImage("assets/icons/logo.png"),
                ),
              ),
            )
          : null,
      actions: widget.onClose != null
          ? [
              TextButton(
                onPressed: () {
                  _timer?.cancel();
                  context.router.pop();
                  widget.onClose?.call();
                },
                child: Text(t.close),
              ),
            ]
          : null,
    );
  }
}

typedef OnUpdateCallback = void Function();

class OtpDownCount extends StatefulWidget {
  const OtpDownCount({
    super.key,
    required this.authOneTimePassword,
    this.onUpdate,
  });

  final AuthOneTimePassword authOneTimePassword;
  final OnUpdateCallback? onUpdate;

  @override
  State<OtpDownCount> createState() => _OtpDownCountState();
}

class _OtpDownCountState extends State<OtpDownCount>
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
      } else if (status == AnimationStatus.reverse && widget.onUpdate != null) {
        Timer(const Duration(milliseconds: 100), widget.onUpdate!);
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

class DialogCloseController {
  BuildContext? _context;

  set context(BuildContext? value) {
    _context = value;
  }

  void close<T extends Object?>([T? result]) {
    if (_context != null && _context!.mounted) {
      final route = ModalRoute.of(_context!);
      if (route != null) {
        Navigator.of(_context!, rootNavigator: true).removeRoute(route);
      }
      _context = null;
    }
  }

  void dispose() {
    _context = null;
  }
}

Future<T?> showBottomSheetView<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? barrierLabel,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  Color? barrierColor,
  bool isScrollControlled = false,
  double scrollControlDisabledMaxHeightRatio = 9.0 / 16.0,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool? showDragHandle,
  bool useSafeArea = false,
  RouteSettings? routeSettings,
  AnimationController? transitionAnimationController,
  Offset? anchorPoint,
  AnimationStyle? sheetAnimationStyle,
  bool? requestFocus,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    barrierLabel: barrierLabel,
    elevation: elevation,
    shape: shape,
    clipBehavior: clipBehavior,
    constraints: constraints,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    showDragHandle: showDragHandle,
    useSafeArea: useSafeArea,
    routeSettings: routeSettings,
    transitionAnimationController: transitionAnimationController,
    anchorPoint: anchorPoint,
    sheetAnimationStyle: sheetAnimationStyle,
    requestFocus: requestFocus,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Material(
            color:
                Theme.of(context).bottomSheetTheme.modalBackgroundColor ??
                Theme.of(context).bottomSheetTheme.backgroundColor ??
                Theme.of(context).colorScheme.surfaceContainerLow,
            clipBehavior: .antiAlias,
            borderRadius: .circular(12),
            child: builder(context),
          ),
        ),
      );
    },
  );
}
