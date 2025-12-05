import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../context/kdbx.dart';
import '../i18n.dart';
import '../kdbx/icons.dart';
import '../kdbx/kdbx.dart';
import '../page/route.dart';
import '../util/common.dart';
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
  State<GroupSelectorDialog> createState() => _GroupSelectorDialogState();
}

class _GroupSelectorDialogState extends State<GroupSelectorDialog> {
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
                  notes: '',
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
      content: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 312),
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

class SetKdbxGroupDialog extends StatefulWidget {
  const SetKdbxGroupDialog({
    super.key,
    required this.kdbxGroupData,
    required this.onResult,
  });

  final KdbxGroupData kdbxGroupData;
  final FormFieldSetter<KdbxGroupData> onResult;

  static Future<Object?> openDialog(
    BuildContext context,
    KdbxGroupData kdbxGroupData,
  ) {
    return showDialog(
      context: context,
      builder: (context) {
        return SetKdbxGroupDialog(
          kdbxGroupData: kdbxGroupData,
          onResult: (value) {
            context.router.pop(value);
          },
        );
      },
    );
  }

  @override
  State<SetKdbxGroupDialog> createState() => SetKdbxGroupDialogState();
}

class SetKdbxGroupDialogState extends State<SetKdbxGroupDialog> {
  late final KdbxGroupData _kdbxGroupData = widget.kdbxGroupData.clone();

  bool _isDirty() {
    return _kdbxGroupData.kdbxIcon.icon != widget.kdbxGroupData.kdbxIcon.icon ||
        _kdbxGroupData.kdbxIcon.customIcon?.uuid !=
            widget.kdbxGroupData.kdbxIcon.customIcon?.uuid ||
        _kdbxGroupData.name != widget.kdbxGroupData.name ||
        _kdbxGroupData.notes != widget.kdbxGroupData.notes ||
        _kdbxGroupData.enableDisplay != widget.kdbxGroupData.enableDisplay ||
        _kdbxGroupData.enableSearching != widget.kdbxGroupData.enableSearching;
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    return AlertDialog(
      title: Text(_kdbxGroupData.kdbxGroup != null ? t.modify : t.create),
      content: SizedBox(
        // 移动端不需要限制宽度
        width: isDesktop ? 375 : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              autofocus: true,
              initialValue: _kdbxGroupData.name,
              textInputAction: TextInputAction.done,
              onChanged: (value) {
                _kdbxGroupData.name = value;
                setState(() {});
              },
              decoration: InputDecoration(
                label: Text(t.title),
                border: const OutlineInputBorder(),
                prefixIcon: IconButton(
                  onPressed: () async {
                    final reslut = await context.router.push(SelectIconRoute());
                    if (reslut != null && reslut is KdbxIconWidgetData) {
                      _kdbxGroupData.kdbxIcon = reslut;
                      setState(() {});
                    }
                  },
                  icon: KdbxIconWidget(
                    kdbxIcon: _kdbxGroupData.kdbxIcon,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final text = await context.router.push(EditNotesRoute(
                  text: _kdbxGroupData.notes,
                ));

                if (text != null && text is String) {
                  _kdbxGroupData.notes = text;
                  setState(() {});
                }
              },
              child: InputDecorator(
                isEmpty: _kdbxGroupData.notes.isEmpty,
                decoration: InputDecoration(
                  labelText: t.description,
                  border: const OutlineInputBorder(),
                ),
                child: _kdbxGroupData.notes.isNotEmpty
                    ? Text(
                        _kdbxGroupData.notes,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
              ),
            ),
            ListTile(
              trailing: Checkbox(
                tristate: true,
                value: _kdbxGroupData.enableDisplay,
                onChanged: (value) {
                  _kdbxGroupData.enableDisplay = value;
                  setState(() {});
                },
              ),
              title: Text(t.display),
              subtitle: Text(switch (_kdbxGroupData.enableDisplay) {
                true => t.enable_display_true_subtitle,
                false => t.enable_display_false_subtitle,
                null => t.enable_display_null_subtitle
              }),
            ),
            ListTile(
              trailing: Checkbox(
                tristate: true,
                value: _kdbxGroupData.enableSearching,
                onChanged: (value) {
                  _kdbxGroupData.enableSearching = value;
                  setState(() {});
                },
              ),
              title: Text(t.search),
              subtitle: Text(switch (_kdbxGroupData.enableSearching) {
                true => t.enable_searching_true_subtitle,
                false => t.enable_searching_false_subtitle,
                null => t.enable_searching_null_subtitle
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onResult(null);
          },
          child: Text(t.cancel),
        ),
        TextButton(
          onPressed: _isDirty()
              ? () {
                  widget.onResult(_kdbxGroupData);
                }
              : null,
          child: Text(t.confirm),
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
    final kdbx = KdbxProvider.of(context)!;

    _totalEntry.addAll(_kbdxSearchHandler.search(
      _searchController.text,
      kdbx.totalEntry,
    ));
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
          )
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
                ),
                size: 24,
              ),
              titleTextStyle: kdbxEntry.isExpiry()
                  ? Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.error)
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
          TextSpan(
            style: Theme.of(context).textTheme.bodySmall,
            text: text,
          )
        ],
      ),
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
