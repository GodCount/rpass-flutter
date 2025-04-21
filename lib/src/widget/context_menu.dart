import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';

enum PasswordsItemMenu {
  edit,
  copy,
  delete,
}

enum GroupsItemMenu {
  search,
  modify,
  delete,
}

enum GroupsManageItemMenu {
  view,
  edit,
  copy,
  move,
  move_selected,
  delete,
  delete_selected
}

enum RecycleBinItemMenu {
  view,
  revert,
  revert_selected,
  delete,
  delete_selected
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
