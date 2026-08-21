import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:keepass_core/keepass_core.dart';

import '../../store/index.dart';
import '../../util/common.dart';
import '../../util/route.dart';
import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../widget/kdbx_icon.dart';
import '../../widget/extension_state.dart';
import '../password/look_account.dart';

class _RecycleBinArgs extends PageRouteArgs {
  _RecycleBinArgs({super.key});
}

class RecycleBinRoute extends PageRouteInfo<_RecycleBinArgs> {
  RecycleBinRoute({Key? key}) : super(name, args: _RecycleBinArgs(key: key));

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
    with SecondLevelPageAutoBack<RecycleBinPage>, KdbxProviderListener {
  final List<Object> _objects = [];

  final List<Object> _selecteds = [];

  Object? _showMenu;

  @override
  void initState() {
    Store.kdbx.addListener(this);
    onKdbxSaved();
    super.initState();
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

  void _showRecycleBinAction(Object object) {
    final t = I18n.of(context)!;

    showBottomSheetList(
      title: object is GroupData
          ? object.name
          : object is EntryData
          ? object.getLabel()
          : "",
      children: [
        ListTile(
          leading: const Icon(Icons.person_search),
          title: Text(t.lookup),
          enabled: object is EntryData,
          onTap: () async {
            if (object is EntryData) {
              await context.router.popAndPush(LookAccountRoute(id: object.id));
            }
          },
        ),
        ListTile(
          iconColor: Theme.of(context).colorScheme.primary,
          textColor: Theme.of(context).colorScheme.primary,
          leading: const Icon(Icons.restore_from_trash),
          title: Text(t.revert),
          onTap: () {
            _restoreObjects([object]);
            context.router.pop();
          },
        ),
        ListTile(
          iconColor: Theme.of(context).colorScheme.error,
          textColor: Theme.of(context).colorScheme.error,
          leading: const Icon(Icons.delete_forever),
          title: Text(t.completely_delete),
          onTap: () => _deleteWarnDialog(() {
            _deletePermanentlys([object]);
            context.router.pop();
          }),
        ),
      ],
    );
  }

  void _restoreObjects(List<Object> values) async {
    if (values.isEmpty) return;

    await kdbxAction(
      KdbxAction.restore(
        values
            .map(
              (item) => item is GroupData
                  ? item.id
                  : item is EntryData
                  ? item.id
                  : null,
            )
            .where((item) => item != null)
            .cast<String>()
            .toList(),
      ),
    );
  }

  void _deletePermanentlys(List<Object> values) async {
    if (values.isEmpty) return;
    await kdbxAction(
      KdbxAction.delete(
        values
            .map(
              (item) => item is GroupData
                  ? item.id
                  : item is EntryData
                  ? item.id
                  : null,
            )
            .where((item) => item != null)
            .cast<String>()
            .toList(),
      ),
    );
  }

  void _onItemTap(Object kdbxObject) {
    setState(() {
      if (_selecteds.contains(kdbxObject)) {
        _selecteds.remove(kdbxObject);
      } else {
        _selecteds.add(kdbxObject);
      }
    });
  }

  void _onItemLongPress(Object kdbxObject) {
    _showRecycleBinAction(kdbxObject);
  }

  @override
  void onKdbxSaved() async {
    final (groups, entrys) = await Store.kdbx.kdbx!.getRecycleItems();
    _objects.clear();
    _objects.addAll(groups);
    _objects.addAll(entrys);
    _selecteds.removeWhere(((item) => !_objects.contains(item)));
    setState(() {});
  }

  @override
  void dispose() {
    _selecteds.clear();
    Store.kdbx.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

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
                ),
              ]
            : null,
      ),
      body: ListView.builder(
        itemCount: _objects.length,
        itemBuilder: (context, index) {
          return _buildListItem(_objects[index]);
        },
      ),
    );
  }

  Widget _buildListItem(Object kdbxObject) {
    return CustomContextMenuRegion<MyContextMenuItem>(
      enabled: isDesktop,
      onItemSelected: (type) {
        setState(() {
          _showMenu = null;
        });

        if (type == null) {
          return;
        }
        switch (type) {
          case ViewContextMenuItem():
            if (kdbxObject is EntryData) {
              context.router.platformNavigate(
                LookAccountRoute(id: kdbxObject.id),
              );
            }
            break;
          case RevertContextMenuItem(selected: final selected):
            _restoreObjects(selected ? _selecteds : [kdbxObject]);
            break;
          case DeleteContextMenuItem(selected: final selected):
            _deleteWarnDialog(
              () => _deletePermanentlys(selected ? _selecteds : [kdbxObject]),
            );
            break;
          default:
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
              enabled: kdbxObject is EntryData,
              value: MyContextMenuItem.view(),
            ),
            const MenuDivider(),
            MenuItem(
              label: t.revert,
              icon: Icons.restore_from_trash,
              value: MyContextMenuItem.revert(),
            ),
            MenuItem(
              label: t.completely_delete,
              icon: Icons.delete_forever,
              value: MyContextMenuItem.delete(),
              color: Theme.of(context).colorScheme.error,
            ),
            const MenuDivider(),
            MenuItem(
              label: t.revert_selected,
              enabled: _selecteds.isNotEmpty,
              icon: Icons.restore_from_trash,
              value: MyContextMenuItem.revert(true),
            ),
            MenuItem(
              label: t.completely_delete_selected,
              enabled: _selecteds.isNotEmpty,
              icon: Icons.delete_forever,
              value: MyContextMenuItem.delete(true),
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
            icon: kdbxObject is EntryData
                ? KdbxIconType.Key.toKdbxIcon()
                : KdbxIconType.Folder.toKdbxIcon(),
          ),
        ),
        trailing: _selecteds.contains(kdbxObject)
            ? const Icon(Icons.done)
            : null,
        title: Text(
          kdbxObject is GroupData
              ? kdbxObject.name
              : kdbxObject is EntryData
              ? kdbxObject.getLabel()
              : "",
        ),
      ),
    );
  }
}
