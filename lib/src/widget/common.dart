import 'package:flutter/material.dart';

import '../i18n.dart';
import '../kdbx/icons.dart';
import '../kdbx/kdbx.dart';

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
