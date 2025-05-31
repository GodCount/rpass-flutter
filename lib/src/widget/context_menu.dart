import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';

import '../i18n.dart';
import '../kdbx/kdbx.dart';

sealed class MyContextMenuItem {
  MyContextMenuItem();

  factory MyContextMenuItem.edit() => EditContextMenuItem();
  factory MyContextMenuItem.search() => SearchContextMenuItem();
  factory MyContextMenuItem.modify() => ModifyContextMenuItem();
  factory MyContextMenuItem.view() => ViewContextMenuItem();

  factory MyContextMenuItem.delete([bool selected = false]) =>
      DeleteContextMenuItem(selected);
  factory MyContextMenuItem.move([bool selected = false]) =>
      MoveContextMenuItem(selected);
  factory MyContextMenuItem.revert([bool selected = false]) =>
      RevertContextMenuItem(selected);

  factory MyContextMenuItem.autoFill([KdbxKey? kdbxKey]) =>
      AutoFillContextMenuItem(kdbxKey);
  factory MyContextMenuItem.copy([KdbxKey? kdbxKey]) =>
      CopyContextMenuItem(kdbxKey);

  static List<MenuItem<MyContextMenuItem>> buildSubmenuAutoFill(
    BuildContext context,
    KdbxEntry kdbxEntry,
  ) =>
      AutoFillContextMenuItem.buildSubmenuItem(context, kdbxEntry);

  static List<MenuItem<MyContextMenuItem>> buildSubmenuCopy(
    BuildContext context,
    KdbxEntry kdbxEntry,
  ) =>
      CopyContextMenuItem.buildSubmenuItem(context, kdbxEntry);
}

class EditContextMenuItem extends MyContextMenuItem {}

class SearchContextMenuItem extends MyContextMenuItem {}

class ModifyContextMenuItem extends MyContextMenuItem {}

class ViewContextMenuItem extends MyContextMenuItem {}

class DeleteContextMenuItem extends MyContextMenuItem {
  DeleteContextMenuItem([this.selected = false]);
  final bool selected;
}

class MoveContextMenuItem extends MyContextMenuItem {
  MoveContextMenuItem([this.selected = false]);
  final bool selected;
}

class RevertContextMenuItem extends MyContextMenuItem {
  RevertContextMenuItem([this.selected = false]);
  final bool selected;
}

mixin class _KdbxKeyContextMenuItem {
  static String _kdbxKey2I18n(BuildContext context, String key) {
    final t = I18n.of(context)!;
    switch (key) {
      case KdbxKeyCommon.KEY_TITLE:
        return t.title;
      case KdbxKeyCommon.KEY_URL:
        return t.domain;
      case KdbxKeyCommon.KEY_USER_NAME:
        return t.account;
      case KdbxKeyCommon.KEY_EMAIL:
        return t.email;
      case KdbxKeyCommon.KEY_PASSWORD:
        return t.password;
      case KdbxKeyCommon.KEY_OTP:
        return t.otp;
      case KdbxKeyCommon.KEY_NOTES:
        return t.description;
      case KdbxKeySpecial.KEY_AUTO_TYPE:
        return t.fill_sequence;
      default:
        return key;
    }
  }

  static List<(KdbxKey, String)> _getKdbxKeyI18n(
    BuildContext context,
    KdbxEntry kdbxEntry,
  ) {
    return [
      ...KdbxKeyCommon.all
          .map((item) => (item, _kdbxKey2I18n(context, item.key))),
      ...kdbxEntry.customEntries.map((item) => (
            item.key,
            _kdbxKey2I18n(context, item.key.key),
          ))
    ];
  }
}

class CopyContextMenuItem extends MyContextMenuItem {
  CopyContextMenuItem([this.kdbxKey]);

  final KdbxKey? kdbxKey;

  static List<MenuItem<CopyContextMenuItem>> buildSubmenuItem(
    BuildContext context,
    KdbxEntry kdbxEntry,
  ) {
    return _KdbxKeyContextMenuItem._getKdbxKeyI18n(context, kdbxEntry)
        .map((item) => MenuItem(
              label: item.$2,
              enabled: (kdbxEntry.getActualString(item.$1) ?? '').isNotEmpty,
              value: CopyContextMenuItem(item.$1),
            ))
        .toList();
  }
}

class AutoFillContextMenuItem extends MyContextMenuItem {
  AutoFillContextMenuItem([this.kdbxKey]);

  final KdbxKey? kdbxKey;

  static List<MenuItem<AutoFillContextMenuItem>> buildSubmenuItem(
    BuildContext context,
    KdbxEntry kdbxEntry,
  ) {
    return _KdbxKeyContextMenuItem._getKdbxKeyI18n(context, kdbxEntry)
        .map((item) => MenuItem(
              label: item.$2,
              enabled: (kdbxEntry.getActualString(item.$1) ?? '').isNotEmpty,
              value: AutoFillContextMenuItem(item.$1),
            ))
        .toList();
  }
}

typedef BuilderContextMenu<T> = ContextMenu<T> Function(BuildContext context);

class CustomContextMenuRegion<T> extends StatelessWidget {
  const CustomContextMenuRegion({
    super.key,
    required this.builder,
    required this.child,
    this.enabled = true,
    this.onItemSelected,
  });

  final Widget child;
  final bool enabled;
  final BuilderContextMenu<T> builder;
  final ValueChanged<T?>? onItemSelected;

  void _showMenu(BuildContext context, Offset position) async {
    final menu = builder(context).copyWith(position: position);
    final value = await showContextMenu(
      Navigator.of(context, rootNavigator: true).context,
      contextMenu: menu,
    );
    onItemSelected?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    return GestureDetector(
      onSecondaryTapUp: (details) {
        _showMenu(context, details.globalPosition);
      },
      child: child,
    );
  }
}
