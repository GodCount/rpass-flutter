import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../store/index.dart';
import '../../store/settings/shortcuts.dart';
import '../../util/route.dart';
import '../../widget/extension_state.dart';

class _ShortcutsSettingsArgs extends PageRouteArgs {
  _ShortcutsSettingsArgs({super.key});
}

class ShortcutsSettingsRoute extends PageRouteInfo<_ShortcutsSettingsArgs> {
  ShortcutsSettingsRoute({Key? key})
    : super(name, args: _ShortcutsSettingsArgs(key: key));

  static const name = "ShortcutsSettingsRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_ShortcutsSettingsArgs>(
        orElse: () => _ShortcutsSettingsArgs(),
      );
      return ShortcutsSettingsPage(key: args.key);
    },
  );
}

class ShortcutsSettingsPage extends StatefulWidget {
  const ShortcutsSettingsPage({super.key});

  @override
  State<ShortcutsSettingsPage> createState() => _ShortcutsSettingsPageState();
}

class _ShortcutsSettingsPageState extends State<ShortcutsSettingsPage>
    with SecondLevelPageAutoBack<ShortcutsSettingsPage> {
  void modifyHotKey(String identifier, [HotKey? hotKey]) async {
    final result = await ModifyHotKeyDialog.openDialog(
      context,
      identifier: identifier,
      value: hotKey,
    );

    if (result != hotKey) {
      await Store.instance.settings.shortcutsStore.setShrtcutsHot(
        result ?? hotKey!,
        result == null,
      );
      setState(() {});
    }
  }

  void _setOpenAppAlignment() {
    final t = I18n.of(context)!;

    final shortcutsStore = Store.instance.settings.shortcutsStore;

    GestureTapCallback? autoSavePop(ShortcutsOpenAppAlignment value) {
      return () {
        context.router.pop();
        if (shortcutsStore.shortcutsOpenAppAlignment != value) {
          shortcutsStore.setShortcutsOpenAppAlignment(value);
          setState(() {});
        }
      };
    }

    showBottomSheetList(
      title: t.window_position,
      children: [
        ListTile(
          title: Text(t.mouse_position),
          trailing:
              shortcutsStore.shortcutsOpenAppAlignment ==
                  ShortcutsOpenAppAlignment.mouse
              ? const Icon(Icons.check)
              : null,
          onTap: autoSavePop(ShortcutsOpenAppAlignment.mouse),
        ),
        ListTile(
          title: Text(t.mouse_center),
          trailing:
              shortcutsStore.shortcutsOpenAppAlignment ==
                  ShortcutsOpenAppAlignment.mouseCenter
              ? const Icon(Icons.check)
              : null,
          onTap: autoSavePop(ShortcutsOpenAppAlignment.mouseCenter),
        ),
        ListTile(
          title: Text(t.mouse_screen_center),
          trailing:
              shortcutsStore.shortcutsOpenAppAlignment ==
                  ShortcutsOpenAppAlignment.mouseScreenCenter
              ? const Icon(Icons.check)
              : null,
          onTap: autoSavePop(ShortcutsOpenAppAlignment.mouseScreenCenter),
        ),
        ListTile(
          title: Text(t.prev_position),
          trailing:
              shortcutsStore.shortcutsOpenAppAlignment ==
                  ShortcutsOpenAppAlignment.prev
              ? const Icon(Icons.check)
              : null,
          onTap: autoSavePop(ShortcutsOpenAppAlignment.prev),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: automaticallyImplyLeading,
        leading: autoBack(),
        title: Text(t.shortcuts),
      ),
      body: ListView(children: _buildList()),
    );
  }

  (String, String?) _hotKeyIdentifier2I18n(String identifier) {
    final t = I18n.of(context)!;
    switch (identifier) {
      case "open":
        return ("${t.open} ${t.app_name}", t.shortcut_open_subtitle);
      case "lock":
        return (t.lock, t.shortcut_lock_subtitle);
      case "autofill":
        return (t.auto_fill, t.shortcut_autofill_subtitle);
      default:
        {
          if (identifier.startsWith("autofill_")) {
            final key = identifier.split("_")[1];
            return (
              t.shortcut_autofill_field(key.fromKdbxKeyToI18n(context)),
              null,
            );
          }
          return (identifier, null);
        }
    }
  }

  List<Widget> _buildList() {
    final t = I18n.of(context)!;

    final shortcutsStore = Store.instance.settings.shortcutsStore;
    final defaultHotkeys = shortcutsStore.defaultHotKeys.keys.toList();

    final List<Widget> children = [
      ListTile(
        onTap: _setOpenAppAlignment,
        title: Text(t.window_position),
        trailing: Text(
          switch (shortcutsStore.shortcutsOpenAppAlignment) {
            ShortcutsOpenAppAlignment.mouse => t.mouse_position,
            ShortcutsOpenAppAlignment.mouseCenter => t.mouse_center,
            ShortcutsOpenAppAlignment.mouseScreenCenter =>
              t.mouse_screen_center,
            ShortcutsOpenAppAlignment.prev => t.prev_position,
          },
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    ];

    for (final key in defaultHotkeys) {
      final (title, subtitle) = _hotKeyIdentifier2I18n(key);

      children.add(
        ListTile(
          title: Text(title),
          subtitle: subtitle != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              : null,
          trailing: HotKeyView(hotKey: shortcutsStore.hotKeys[key]),
          onTap: () => modifyHotKey(key, shortcutsStore.hotKeys[key]),
        ),
      );
    }

    return children;
  }
}

class _VirtualKeyView extends StatelessWidget {
  const _VirtualKeyView({required this.keyLabel});

  final String keyLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      padding: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Align(
        alignment: AlignmentGeometry.center,
        child: Text(keyLabel, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}

class HotKeyView extends StatelessWidget {
  const HotKeyView({super.key, required this.hotKey});

  final HotKey? hotKey;

  @override
  Widget build(BuildContext context) {
    return hotKey != null
        ? Wrap(
            spacing: 8,
            children: [
              for (HotKeyModifier modifier in hotKey!.modifiers ?? [])
                _VirtualKeyView(keyLabel: modifier.physicalKeys.first.keyLabel),
              _VirtualKeyView(keyLabel: hotKey!.physicalKey.keyLabel),
            ],
          )
        : Icon(
            Icons.do_disturb_alt,
            color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.3),
          );
  }
}

class ModifyHotKeyDialog extends StatefulWidget {
  const ModifyHotKeyDialog({
    super.key,
    this.value,
    required this.identifier,
    required this.onResult,
  });

  final String identifier;
  final HotKey? value;
  final FormFieldSetter<HotKey> onResult;

  static Future<HotKey?> openDialog(
    BuildContext context, {
    required String identifier,
    HotKey? value,
  }) {
    return showDialog(
      context: context,
      builder: (context) {
        return ModifyHotKeyDialog(
          value: value,
          identifier: identifier,
          onResult: (value) {
            context.router.pop(value);
          },
        );
      },
    );
  }

  @override
  State<ModifyHotKeyDialog> createState() => _ModifyHotKeyDialogState();
}

class _ModifyHotKeyDialogState extends State<ModifyHotKeyDialog> {
  late HotKey? hotKey = widget.value;

  bool canSave = false;

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(widget.identifier),
        constraints: BoxConstraints(maxWidth: 312, maxHeight: 240),
        content: Center(
          child: HotKeyRecorder(
            initalHotKey: hotKey,
            onHotKeyRecorded: (key) {
              hotKey = key;
              if (key.modifiers != null && key.modifiers!.isNotEmpty) {
                if (!canSave) {
                  setState(() {
                    canSave = true;
                  });
                }
              } else if (canSave) {
                setState(() {
                  canSave = false;
                });
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: canSave
                ? () {
                    widget.onResult(
                      hotKey != null
                          ? HotKey(
                              identifier: widget.identifier,
                              key: hotKey!.key,
                              modifiers: hotKey!.modifiers,
                              scope: hotKey!.scope,
                            )
                          : null,
                    );
                  }
                : null,
            child: Text(t.save),
          ),
          TextButton(
            onPressed: () {
              widget.onResult(
                Store
                    .instance
                    .settings
                    .shortcutsStore
                    .defaultHotKeys[widget.identifier]!
                    .clone(),
              );
            },
            child: Text(t.reset),
          ),
          TextButton(
            onPressed: () {
              widget.onResult(null);
            },
            child: Text(
              t.delete,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              widget.onResult(widget.value);
            },
            child: Text(t.cancel),
          ),
        ],
      ),
    );
  }
}
