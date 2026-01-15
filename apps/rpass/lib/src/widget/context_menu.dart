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

typedef BuildMenuItemValue<T> = T Function(KdbxKey key);

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
      case KdbxKeyURLS.KEY_URL1:
        return t.domain_num(1);
      case KdbxKeyURLS.KEY_URL2:
        return t.domain_num(2);
      case KdbxKeyURLS.KEY_URL3:
        return t.domain_num(3);
      case KdbxKeyURLS.KEY_URL4:
        return t.domain_num(4);
      case KdbxKeyURLS.KEY_URL5:
        return t.domain_num(5);
      default:
        return key;
    }
  }

  static List<MenuItem<T>> _buildKdbxKeyMenuItem<T>(
    BuildContext context,
    KdbxEntry kdbxEntry,
    BuildMenuItemValue<T> buildValue,
  ) {
    final urls = [KdbxKeyCommon.URL, ...kdbxEntry.moreUrlsKeys];
    return [
      ...KdbxKeyCommon.excludeURL.map(
        (item) => MenuItem(
          label: _kdbxKey2I18n(context, item.key),
          enabled: kdbxEntry.getNonNullString(item).isNotEmpty,
          value: buildValue(item),
        ),
      ),
      urls.length > 1
          ? MenuItem.submenu(
              label: I18n.of(context)!.domain,
              items: [KdbxKeyCommon.URL, ...kdbxEntry.moreUrlsKeys]
                  .map(
                    (item) => MenuItem(
                      label: _kdbxKey2I18n(context, item.key),
                      enabled: kdbxEntry.getNonNullString(item).isNotEmpty,
                      value: buildValue(item),
                    ),
                  )
                  .toList(),
            )
          : MenuItem(
              label: _kdbxKey2I18n(context, KdbxKeyCommon.KEY_URL),
              enabled: kdbxEntry.getNonNullString(KdbxKeyCommon.URL).isNotEmpty,
              value: buildValue(KdbxKeyCommon.URL),
            ),
      MenuItem.submenu(
        label: I18n.of(context)!.custom_field,
        enabled: kdbxEntry.customEntries.isNotEmpty,
        items: kdbxEntry.customEntries
            .map(
              (item) => MenuItem(
                label: _kdbxKey2I18n(context, item.key.key),
                enabled: kdbxEntry.getNonNullString(item.key).isNotEmpty,
                value: buildValue(item.key),
              ),
            )
            .toList(),
      ),
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
    return _KdbxKeyContextMenuItem._buildKdbxKeyMenuItem(
      context,
      kdbxEntry,
      (key) => CopyContextMenuItem(key),
    );
  }
}

class AutoFillContextMenuItem extends MyContextMenuItem {
  AutoFillContextMenuItem([this.kdbxKey]);

  final KdbxKey? kdbxKey;

  static List<MenuItem<AutoFillContextMenuItem>> buildSubmenuItem(
    BuildContext context,
    KdbxEntry kdbxEntry,
  ) {
    return _KdbxKeyContextMenuItem._buildKdbxKeyMenuItem(
      context,
      kdbxEntry,
      (key) => AutoFillContextMenuItem(key),
    );
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
