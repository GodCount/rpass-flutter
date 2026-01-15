import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../i18n.dart';
import '../kdbx/kdbx.dart';
import '../page/password/look_account.dart';
import '../util/common.dart';
import 'extension_state.dart';

class MyMotion extends StatefulWidget {
  const MyMotion({
    super.key,
    this.onOpen,
    this.onClose,
    required this.child,
  });

  final VoidCallback? onOpen;
  final VoidCallback? onClose;
  final Widget child;

  @override
  State<MyMotion> createState() => _MyMotionState();
}

class _MyMotionState extends State<MyMotion> {
  SlidableController? controller;

  VoidCallback? _removeCallback;

  @override
  void initState() {
    super.initState();
    controller = Slidable.of(context);

    if (controller != null) {
      _addListener(controller!);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onOpen?.call();
      });
    }
  }

  void _animationListener() {
    if (controller!.actionPaneType.value == ActionPaneType.none) {
      widget.onClose?.call();
    }
  }

  void _removeListener() {
    _removeCallback?.call();
    _removeCallback = null;
  }

  void _addListener(SlidableController controller) {
    _removeListener();
    controller.actionPaneType.addListener(_animationListener);
    _removeCallback = () {
      controller.actionPaneType.removeListener(_animationListener);
    };
  }

  @override
  void dispose() {
    _removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class KdbxHistoryList extends StatefulWidget {
  const KdbxHistoryList({super.key, required this.kdbxEntry});

  final KdbxEntry kdbxEntry;

  @override
  State<StatefulWidget> createState() => _KdbxHistoryListState();
}

class _KdbxHistoryListState extends State<KdbxHistoryList> {
  KdbxEntry? _showMenu;

  void _remove(KdbxEntry entry) async {
    // TODO! 删除后, 同步远程,数据会重新覆盖回来,需要 kdbx.dart 兼容
    // final t = I18n.of(context)!;

    // if (await showConfirmDialog(
    //   title: t.completely_delete,
    //   message: t.delete_no_revert,
    //   confirm: t.delete,
    // )) {
    //   if (widget.kdbxEntry.history.remove(entry)) {
    //     kdbxSave(KdbxProvider.of(context)!);
    //     setState(() {});
    //   }
    // }
  }

  void _restore(KdbxEntry entry) {}

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    final history = widget.kdbxEntry.history.reversed.toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Text(
              t.timeline,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        history.isNotEmpty
            ? Expanded(
                child: isMobile
                    ? SlidableAutoCloseBehavior(
                        child: _buildHistoryList(history),
                      )
                    : _buildHistoryList(history),
              )
            : Expanded(
                child: Center(
                  child: Opacity(
                    opacity: .5,
                    child: Text(t.not_history_record),
                  ),
                ),
              )
      ],
    );
  }

  Widget _buildHistoryList(List<KdbxEntry> history) {
    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (context, index) {
        final entry = history[index];

        final child = ListTile(
          selected: _showMenu == entry,
          minTileHeight: 48,
          title: Text(
            getKdbxObjectTitle(entry),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          subtitle: Text(
            entry.times.lastModificationTime.get()!.toLocal().formatDate,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          onTap: () {
            context.router.popAndPush(LookAccountRoute(
              kdbxEntry: entry,
              uuid: entry.uuid,
              readOnly: true,
            ));
          },
        );

        return isMobile
            ? Slidable(
                groupTag: "0",
                enabled: false,
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      icon: Icons.unarchive_rounded,
                      borderRadius: BorderRadius.circular(999),
                      backgroundColor: Colors.transparent,
                      foregroundColor: Theme.of(context).colorScheme.secondary,
                      onPressed: (context) => _restore(entry),
                    ),
                    SlidableAction(
                      icon: Icons.delete_rounded,
                      borderRadius: BorderRadius.circular(999),
                      backgroundColor: Colors.transparent,
                      foregroundColor: Theme.of(context).colorScheme.error,
                      onPressed: (context) => _remove(entry),
                    ),
                    const SizedBox(
                      width: 16,
                    )
                  ],
                ),
                child: child,
              )
            : CustomContextMenuRegion<MyContextMenuItem>(
                enabled: false,
                onItemSelected: (type) {
                  setState(() {
                    _showMenu = null;
                  });
                  if (type == null) {
                    return;
                  }
                  switch (type) {
                    case RevertContextMenuItem():
                      _restore(entry);
                      break;
                    case DeleteContextMenuItem():
                      _remove(entry);
                      break;
                    default:
                      break;
                  }
                },
                builder: (context) {
                  final t = I18n.of(context)!;

                  setState(() {
                    _showMenu = entry;
                  });

                  return ContextMenu(
                    entries: [
                      MenuItem(
                        label: t.revert,
                        icon: Icons.unarchive_rounded,
                        value: MyContextMenuItem.revert(),
                      ),
                      MenuItem(
                        label: t.delete,
                        icon: Icons.delete,
                        value: MyContextMenuItem.delete(),
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ],
                  );
                },
                child: child,
              );
      },
    );
  }
}
