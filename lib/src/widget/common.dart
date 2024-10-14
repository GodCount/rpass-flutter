import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../i18n.dart';
import '../kdbx/icons.dart';
import '../kdbx/kdbx.dart';
import '../page/page.dart';
import '../util/common.dart';
import '../util/file.dart';
import 'chip_list.dart';

enum TimeLineNodeType { all, top, bottom, dot }

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

mixin CommonWidgetUtil<T extends StatefulWidget> on State<T> {
  void writeClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((value) {
      showToast(I18n.of(context)!.copy_done);
    }, onError: (error) {
      showToast(error.toString());
    });
  }

  Future<bool> kdbxSave(Kdbx kdbx) async {
    try {
      await kdbx.save();
      return true;
    } catch (e) {
      print(e);
      showToast(e.toString());
      // TODO! 记录异常
      return false;
    }
  }

  Future<void> showAlert(String msg) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Text(msg),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(I18n.of(context)!.confirm),
            )
          ],
        );
      },
    );
  }

  Future<void> showToast(String msg) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await Fluttertoast.showToast(msg: msg);
    } else {
      await showAlert(msg);
    }
  }

  Future<bool> showConfirmDialog({
    required String title,
    required String message,
    String? cancel,
    String? confirm,
  }) async {
    final result = await showDialog(
      context: context,
      builder: (context) {
        final t = I18n.of(context)!;

        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(cancel ?? t.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(confirm ?? t.confirm),
            ),
          ],
        );
      },
    );
    return result is bool && result ? true : false;
  }
}

mixin BottomSheetUtil<T extends StatefulWidget>
    on State<T>, CommonWidgetUtil<T> {
  void showBottomSheetList({
    String? title,
    required List<ListTile> children,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: [
            if (title != null)
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 6),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
            ...children,
          ],
        );
      },
    );
  }

  void showBinaryAction(ChipListItem<MapEntry<KdbxKey, KdbxBinary>> binary) {
    showBottomSheetList(title: binary.label, children: [
      ListTile(
        leading: const Icon(Icons.save),
        title: const Text("保存"),
        onTap: () async {
          try {
            final result = await SimpleFile.saveFile(
              data: binary.value.value.value,
              filename: binary.label,
            );
            showToast(result);
          } catch (e) {
            if (e is! CancelException) {
              // TODO! 处理异常
            }
          } finally {
            Navigator.of(context).pop();
          }
        },
      )
    ]);
  }

  String getKdbxObjectTitle(KdbxObject kdbxObject) {
    return kdbxObject is KdbxEntry
        ? kdbxObject.label ?? ''
        : kdbxObject is KdbxGroup
            ? kdbxObject.name.get() ?? ''
            : '';
  }

  void showKdbxGroupAction(
    String title, {
    GestureTapCallback? onModifyTap,
    GestureTapCallback? onDeleteTap,
  }) {
    showBottomSheetList(
      title: title,
      children: [
        ListTile(
          iconColor: Theme.of(context).colorScheme.primary,
          textColor: Theme.of(context).colorScheme.primary,
          leading: const Icon(Icons.edit),
          title: const Text("修改"),
          onTap: onModifyTap != null
              ? () {
                  Navigator.of(context).pop();
                  onModifyTap();
                }
              : null,
        ),
        ListTile(
          iconColor: Theme.of(context).colorScheme.error,
          textColor: Theme.of(context).colorScheme.error,
          leading: const Icon(Icons.delete),
          title: const Text("删除"),
          enabled: onDeleteTap != null,
          onTap: onDeleteTap != null
              ? () {
                  Navigator.of(context).pop();
                  onDeleteTap();
                }
              : null,
        ),
      ],
    );
  }

  void showEntryHistoryList(KdbxEntry kdbxEntry) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final history = kdbxEntry.history.reversed.toList();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 6),
                child: Text(
                  "时间线",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            history.isNotEmpty
                ? Expanded(
                    child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final entry = history[index];

                          TimeLineNodeType type = TimeLineNodeType.all;

                          if (history.length == 1) {
                            type = TimeLineNodeType.dot;
                          } else if (index == 0) {
                            type = TimeLineNodeType.bottom;
                          } else if (index == history.length - 1) {
                            type = TimeLineNodeType.top;
                          }

                          return ListTile(
                            leading: _timelineNode(type),
                            title: Card(
                              elevation: 4.0,
                              shape: const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(6.0)),
                              ),
                              child: InkWell(
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(6.0)),
                                onTap: () {
                                  Navigator.of(context).popAndPushNamed(
                                      LookAccountPage.routeName,
                                      arguments: entry);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    dateFormat(
                                      entry.times.lastModificationTime.get()!,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                  )
                : const Expanded(
                    child: Center(
                      child: Opacity(
                        opacity: .5,
                        child: Text("没有历史记录！"),
                      ),
                    ),
                  )
          ],
        );
      },
    );
  }

  Widget _timelineNode(TimeLineNodeType type) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (type != TimeLineNodeType.dot)
          Align(
            alignment: type == TimeLineNodeType.top
                ? const Alignment(0.0, -1.2)
                : type == TimeLineNodeType.bottom
                    ? const Alignment(0.0, 1.2)
                    : Alignment.center,
            widthFactor: 1,
            heightFactor: 2,
            child: FractionallySizedBox(
              heightFactor: type != TimeLineNodeType.all ? 0.5 : 1.2,
              child: Container(
                width: 4,
                color: Colors.amber,
              ),
            ),
          ),
        Container(
          width: 15,
          height: 15,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.amber,
          ),
        )
      ],
    );
  }
}

class KdbxIconWidgetData {
  KdbxIconWidgetData({required this.icon, this.customIcon});

  final KdbxIcon icon;
  final KdbxCustomIcon? customIcon;
}

class KdbxIconWidget extends StatelessWidget {
  const KdbxIconWidget({super.key, required this.kdbxIcon, this.size = 32});

  final KdbxIconWidgetData kdbxIcon;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (kdbxIcon.customIcon != null) {
      return Image.memory(
        kdbxIcon.customIcon!.data,
        width: size,
        height: size,
      );
    } else {
      return Icon(
        KdbxIcon2Material.to(kdbxIcon.icon),
        size: size,
      );
    }
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
            Navigator.of(context).pop(value);
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

  @override
  void initState() {
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(_handleControllerChanged);
    super.initState();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    super.dispose();
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

    final leadingIcon =
        widget.leadingBuilder != null ? widget.leadingBuilder!(this) : null;

    if (isLimitContent) {
      limitIcon = Icon(
        Icons.error_outlined,
        color: Theme.of(context).colorScheme.error,
      );
    }

    if (widget.promptItmes != null && widget.promptItmes!.isNotEmpty) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownMenu(
            menuHeight: 150,
            label: widget.label != null ? Text(widget.label!) : null,
            enableFilter: true,
            enableSearch: true,
            leadingIcon: leadingIcon,
            trailingIcon: limitIcon,
            selectedTrailingIcon: limitIcon,
            controller: _controller,
            expandedInsets: const EdgeInsets.all(0),
            dropdownMenuEntries: widget.promptItmes!
                .map((value) => DropdownMenuEntry(value: value, label: value))
                .toList(),
          )
        ],
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
      content: content,
      actions: [
        TextButton(
          onPressed: () {
            widget.onResult(null);
          },
          child: Text(t.cancel),
        ),
        TextButton(
          onPressed: !isLimitContent && _controller.text.isNotEmpty
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

class SimpleSelectorDialogItem<T> {
  SimpleSelectorDialogItem({
    required this.value,
    required this.label,
  });
  final T value;
  final String label;
}

class SimpleSelectorDialog<T> extends StatefulWidget {
  const SimpleSelectorDialog({
    super.key,
    this.title,
    this.value,
    required this.items,
    required this.onResult,
  });

  final String? title;
  final T? value;
  final List<SimpleSelectorDialogItem<T>> items;
  final FormFieldSetter<T> onResult;

  static Future<Object?> openDialog<T>(
    BuildContext context, {
    String? title,
    T? value,
    required List<SimpleSelectorDialogItem<T>> items,
  }) {
    return showDialog(
      context: context,
      builder: (context) {
        return SimpleSelectorDialog<T>(
          title: title,
          value: value,
          items: items,
          onResult: (value) {
            Navigator.of(context).pop(value);
          },
        );
      },
    );
  }

  @override
  State<SimpleSelectorDialog<T>> createState() =>
      SimpleSelectorDialogState<T>();
}

class SimpleSelectorDialogState<T> extends State<SimpleSelectorDialog<T>> {
  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    return AlertDialog(
      title: widget.title != null ? Text(widget.title!) : null,
      contentPadding: EdgeInsets.only(
        top: Theme.of(context).useMaterial3 ? 16.0 : 20.0,
        right: 0,
        bottom: 24.0,
        left: 0,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: widget.items
              .map(
                (item) => ListTile(
                  title: Padding(
                    padding: const EdgeInsets.only(left: 24.0),
                    child: Text(item.label),
                  ),
                  trailing: item.value == widget.value
                      ? const Icon(Icons.done)
                      : null,
                  onTap: () {
                    widget.onResult(
                        item.value == widget.value ? null : item.value);
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

class AnimatedIconSwitcher extends StatefulWidget {
  const AnimatedIconSwitcher({
    super.key,
    required this.icon,
  });

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
