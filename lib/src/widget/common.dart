import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../context/kdbx.dart';
import '../i18n.dart';
import '../kdbx/icons.dart';
import '../kdbx/kdbx.dart';
import 'extension_state.dart';

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
            requestFocusOnTap: true,
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
  const GroupSelectorDialog({
    super.key,
    this.value,
    required this.onResult,
  });

  final KdbxGroup? value;
  final FormFieldSetter<KdbxGroup> onResult;

  static Future<KdbxGroup?> openDialog(
    BuildContext context, {
    KdbxGroup? value,
  }) {
    return showDialog(
      context: context,
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
  State<GroupSelectorDialog> createState() => GroupSelectorDialogState();
}

class GroupSelectorDialogState extends State<GroupSelectorDialog> {
  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;
    final kdbx = KdbxProvider.of(context)!;

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(t.select_group)),
          IconButton(
            onPressed: () async {
              await setKdbxGroup(
                KdbxGroupData(
                  name: '',
                  kdbxIcon: KdbxIconWidgetData(
                    icon: KdbxIcon.Folder,
                  ),
                ),
              );
              setState(() {});
            },
            icon: const Icon(Icons.add),
          )
        ],
      ),
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
          children: [kdbx.kdbxFile.body.rootGroup, ...kdbx.rootGroups]
              .map(
                (item) => ListTile(
                  title: Padding(
                    padding: const EdgeInsets.only(left: 24.0),
                    child: Text(getKdbxObjectTitle(item)),
                  ),
                  trailing:
                      item == widget.value ? const Icon(Icons.done) : null,
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

extension _IntIterator on int {
  Iterable<T> range<T>(T Function(int i) toElement) sync* {
    for (var i = 0; i < this; i++) {
      yield toElement(i);
    }
  }
}

class TimeLineListWidget extends StatelessWidget {
  const TimeLineListWidget({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 6),
      child: Table(
        columnWidths: const {
          1: FixedColumnWidth(32),
        },
        children: itemCount.range((i) {
          final child = itemBuilder(context, i);
          final even = i % 2 == 0;
          return TableRow(
            children: [
              TableCell(
                child: Visibility(
                  visible: even,
                  child: child,
                ),
              ),
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.fill,
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: 2,
                        color: i != 0 && itemCount > 1
                            ? Colors.amber
                            : Colors.transparent,
                      ),
                    ),
                    Container(
                      width: 15,
                      height: 15,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.amber,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 2,
                        color: itemCount > 1 && i != itemCount - 1
                            ? Colors.amber
                            : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
              TableCell(
                child: Visibility(
                  visible: !even,
                  child: child,
                ),
              )
            ],
          );
        }).toList(),
      ),
    );
  }
}
