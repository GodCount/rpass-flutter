import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';

import '../../util/common.dart';
import '../../util/route.dart';
import '../../context/kdbx.dart';
import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../widget/common.dart';
import '../../widget/extension_state.dart';
import '../password/look_account.dart';

class _RecycleBinArgs extends PageRouteArgs {
  _RecycleBinArgs({super.key});
}

class RecycleBinRoute extends PageRouteInfo<_RecycleBinArgs> {
  RecycleBinRoute({
    Key? key,
  }) : super(
          name,
          args: _RecycleBinArgs(key: key),
        );

  static const name = "RecycleBinRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_RecycleBinArgs>(
        orElse: () => _RecycleBinArgs(),
      );
      return RecycleBinPage(key: args.key);
    },
  );
}

class RecycleBinPage extends StatefulWidget {
  const RecycleBinPage({super.key});

  @override
  State<RecycleBinPage> createState() => _RecycleBinPageState();
}

class _RecycleBinPageState extends State<RecycleBinPage>
    with SecondLevelPageAutoBack<RecycleBinPage> {
  final List<KdbxObject> _selecteds = [];

  VoidCallback? _removeKdbxListener;

  KdbxObject? _showMenu;

  void _save() async {
    await kdbxSave(KdbxProvider.of(context)!);
  }

  void _deleteWarnDialog(VoidCallback confirmCallback) async {
    final t = I18n.of(context)!;
    if (await showConfirmDialog(
      title: t.completely_delete,
      message: t.delete_no_revert,
      confirm: t.delete,
    )) {
      confirmCallback();
    }
  }

  void _showRecycleBinAction(KdbxObject kdbxObject) {
    final t = I18n.of(context)!;

    showBottomSheetList(
      title: getKdbxObjectTitle(kdbxObject),
      children: [
        ListTile(
          leading: const Icon(Icons.person_search),
          title: Text(t.lookup),
          enabled: kdbxObject is KdbxEntry,
          onTap: () async {
            if (kdbxObject is KdbxEntry) {
              await context.router.popAndPush(
                LookAccountRoute(
                  kdbxEntry: kdbxObject,
                  uuid: kdbxObject.uuid,
                  readOnly: true,
                ),
              );
            }
          },
        ),
        ListTile(
          iconColor: Theme.of(context).colorScheme.primary,
          textColor: Theme.of(context).colorScheme.primary,
          leading: const Icon(Icons.restore_from_trash),
          title: Text(t.revert),
          onTap: () {
            _restoreObjects([kdbxObject]);
            context.router.pop();
          },
        ),
        ListTile(
          iconColor: Theme.of(context).colorScheme.error,
          textColor: Theme.of(context).colorScheme.error,
          leading: const Icon(Icons.delete_forever),
          title: Text(t.completely_delete),
          onTap: () => _deleteWarnDialog(
            () {
              _deletePermanentlys([kdbxObject]);
              context.router.pop();
            },
          ),
        ),
      ],
    );
  }

  void _restoreObjects(List<KdbxObject> values) {
    if (values.isEmpty) return;
    final kdbx = KdbxProvider.of(context)!;
    for (var item in values) {
      kdbx.restoreObject(item);
    }
    _save();
  }

  void _deletePermanentlys(List<KdbxObject> values) {
    if (values.isEmpty) return;
    final kdbx = KdbxProvider.of(context)!;
    for (var item in values) {
      kdbx.deletePermanently(item);
    }
    _save();
  }

  void _onItemTap(KdbxObject kdbxObject) {
    setState(() {
      if (_selecteds.contains(kdbxObject)) {
        _selecteds.remove(kdbxObject);
      } else {
        _selecteds.add(kdbxObject);
      }
    });
  }

  void _onItemLongPress(KdbxObject kdbxObject) {
    _showRecycleBinAction(kdbxObject);
  }

  @override
  void initState() {
    final kdbx = KdbxProvider.of(context)!;
    kdbx.addListener(_update);
    _removeKdbxListener = () => kdbx.removeListener(_update);
    super.initState();
  }

  void _update() {
    setState(() {
      final kdbx = KdbxProvider.of(context)!;
      final allObjects = kdbx.recycleBinObjects;
      _selecteds.removeWhere(((item) => !allObjects.contains(item)));
    });
  }

  @override
  void dispose() {
    _selecteds.clear();
    _removeKdbxListener?.call();
    _removeKdbxListener = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    final kdbx = KdbxProvider.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.recycle_bin),
        automaticallyImplyLeading:
            _selecteds.isEmpty && automaticallyImplyLeading,
        leading: _selecteds.isNotEmpty
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _selecteds.clear();
                  });
                },
                icon: const Icon(Icons.close_rounded),
              )
            : autoBack(),
        actions: _selecteds.isNotEmpty
            ? [
                IconButton(
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: () => _restoreObjects(_selecteds),
                  icon: const Icon(Icons.restore_from_trash),
                ),
                IconButton(
                  color: Theme.of(context).colorScheme.error,
                  onPressed: () =>
                      _deleteWarnDialog(() => _deletePermanentlys(_selecteds)),
                  icon: const Icon(Icons.delete_forever),
                )
              ]
            : null,
      ),
      body: ListView.builder(
        itemCount: kdbx.recycleBinObjects.length,
        itemBuilder: (context, index) {
          return _buildListItem(kdbx.recycleBinObjects[index]);
        },
      ),
    );
  }

  Widget _buildListItem(KdbxObject kdbxObject) {
    return CustomContextMenuRegion<RecycleBinItemMenu>(
      enabled: isDesktop,
      onItemSelected: (type) {
        setState(() {
          _showMenu = null;
        });

        if (type == null) {
          return;
        }
        switch (type) {
          case RecycleBinItemMenu.view:
            if (kdbxObject is KdbxEntry) {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    child: LookAccountPage(
                      kdbxEntry: kdbxObject,
                      readOnly: true,
                    ),
                  );
                },
              );
            }
            break;
          case RecycleBinItemMenu.revert:
            _restoreObjects([kdbxObject]);
            break;
          case RecycleBinItemMenu.revert_selected:
            _restoreObjects(_selecteds);
            break;
          case RecycleBinItemMenu.delete:
            _deleteWarnDialog(() => _deletePermanentlys([kdbxObject]));
            break;
          case RecycleBinItemMenu.delete_selected:
            _deleteWarnDialog(() => _deletePermanentlys(_selecteds));
            break;
        }
      },
      builder: (context) {
        final t = I18n.of(context)!;

        setState(() {
          _showMenu = kdbxObject;
        });

        return ContextMenu(
          entries: [
            MenuItem(
              label: t.lookup,
              icon: Icons.person_search,
              enabled: kdbxObject is KdbxEntry,
              value: RecycleBinItemMenu.view,
            ),
            const MenuDivider(),
            MenuItem(
              label: t.revert,
              icon: Icons.restore_from_trash,
              value: RecycleBinItemMenu.revert,
            ),
            MenuItem(
              label: t.completely_delete,
              icon: Icons.delete_forever,
              value: RecycleBinItemMenu.delete,
              color: Theme.of(context).colorScheme.error,
            ),
            const MenuDivider(),
            MenuItem(
              label: t.revert_selected,
              enabled: _selecteds.isNotEmpty,
              icon: Icons.restore_from_trash,
              value: RecycleBinItemMenu.revert_selected,
            ),
            MenuItem(
              label: t.completely_delete_selected,
              enabled: _selecteds.isNotEmpty,
              icon: Icons.delete_forever,
              value: RecycleBinItemMenu.delete_selected,
              color: Theme.of(context).colorScheme.error,
            ),
          ],
        );
      },
      child: ListTile(
        onTap: () => _onItemTap(kdbxObject),
        onLongPress: isMobile ? () => _onItemLongPress(kdbxObject) : null,
        selected: _showMenu == kdbxObject,
        leading: KdbxIconWidget(
          kdbxIcon: KdbxIconWidgetData(
            icon: kdbxObject is KdbxEntry ? KdbxIcon.Key : KdbxIcon.Folder,
          ),
        ),
        trailing:
            _selecteds.contains(kdbxObject) ? const Icon(Icons.done) : null,
        title: Text(getKdbxObjectTitle(kdbxObject)),
      ),
    );
  }
}
