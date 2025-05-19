import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';

import '../../context/kdbx.dart';
import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../util/common.dart';
import '../../util/route.dart';
import '../../widget/common.dart';
import '../../widget/extension_state.dart';
import '../route.dart';

class _ManageGroupEntryArgs extends PageRouteArgs {
  _ManageGroupEntryArgs({
    super.key,
    required this.kdbxGroup,
  });

  final KdbxGroup kdbxGroup;
}

class ManageGroupEntryRoute extends PageRouteInfo<_ManageGroupEntryArgs> {
  ManageGroupEntryRoute({
    Key? key,
    required KdbxGroup kdbxGroup,
    KdbxUuid? uuid,
  }) : super(
          name,
          args: _ManageGroupEntryArgs(
            key: key,
            kdbxGroup: kdbxGroup,
          ),
          rawPathParams: {
            "uuid": uuid?.deBase64Uuid,
          },
        );

  static const name = "ManageGroupEntryRoute";

  static final PageInfo page = PageInfo.builder(
    name,
    builder: (context, data) {
      final args = data.argsAs<_ManageGroupEntryArgs>(
        orElse: () {
          final kdbx = KdbxProvider.of(context)!;
          final uuid = data.inheritedPathParams.optString("uuid")?.kdbxUuid;
          final kdbxGroup = uuid != null ? kdbx.findGroupByUuid(uuid) : null;

          if (kdbxGroup == null) {
            throw Exception("kdbxGroup is null, Not found by uuid: $uuid");
          }
          return _ManageGroupEntryArgs(
            kdbxGroup: kdbxGroup,
          );
        },
      );
      return ManageGroupEntryPage(
        key: args.key,
        kdbxGroup: args.kdbxGroup,
      );
    },
  );
}

class ManageGroupEntryPage extends StatefulWidget {
  const ManageGroupEntryPage({super.key, required this.kdbxGroup});

  final KdbxGroup kdbxGroup;

  @override
  State<ManageGroupEntryPage> createState() => _ManageGroupEntryPageState();
}

class _ManageGroupEntryPageState extends State<ManageGroupEntryPage>
    with SecondLevelPageAutoBack<ManageGroupEntryPage> {
  final TextEditingController _searchController = TextEditingController();

  final KbdxSearchHandler _kbdxSearchHandler = KbdxSearchHandler();

  // 总选中
  final List<KdbxEntry> _selecteds = [];

  final List<KdbxEntry> _totalEntry = [];

  KdbxEntry? _showMenu;

  VoidCallback? _removeKdbxListener;

  bool get _isAllSelect => _selecteds.length == _totalEntry.length;

  @override
  void initState() {
    final kdbx = KdbxProvider.of(context)!;

    _kbdxSearchHandler.setFieldOther(kdbx.fieldStatistic.customFields);

    kdbx.addListener(_search);
    _removeKdbxListener = () => kdbx.removeListener(_search);

    _searchController.addListener(_search);

    _search();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ManageGroupEntryPage oldWidget) {
    if (oldWidget.kdbxGroup.uuid != widget.kdbxGroup.uuid) {
      _selecteds.clear();
      if (_searchController.text.isNotEmpty) {
        _searchController.text = "";
      } else {
        _search();
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _selecteds.clear();
    _removeKdbxListener?.call();
    _removeKdbxListener = null;
    super.dispose();
  }

  void _search() {
    _totalEntry.clear();
    _totalEntry.addAll(_kbdxSearchHandler.search(
      _searchController.text,
      widget.kdbxGroup.entries,
    ));
    _selecteds.removeWhere(((item) => !_totalEntry.contains(item)));
    setState(() {});
  }

  void _onItemTap(KdbxEntry kdbxEntry) {
    if (_selecteds.contains(kdbxEntry)) {
      _selecteds.remove(kdbxEntry);
    } else {
      _selecteds.add(kdbxEntry);
    }
    setState(() {});
  }

  void _delete(List<KdbxEntry> kdbxEntrys) async {
    final t = I18n.of(context)!;
    if (await showConfirmDialog(
      title: t.delete,
      message: t.is_move_recycle,
    )) {
      final kdbx = KdbxProvider.of(context)!;
      for (var item in kdbxEntrys) {
        kdbx.deleteEntry(item);
      }
      await kdbxSave(kdbx);
      kdbxEntrys.clear();
      _search();
    }
  }

  void _move(List<KdbxEntry> kdbxEntrys) async {
    final group = await showGroupSelectorDialog(widget.kdbxGroup);
    if (group != null) {
      final kdbx = KdbxProvider.of(context)!;
      for (var item in kdbxEntrys) {
        kdbx.kdbxFile.move(item, group);
      }
      await kdbxSave(kdbx);
      kdbxEntrys.clear();
      _search();
    }
  }

  void _showSelectorEntryAction([KdbxEntry? kdbxEntry]) {
    final t = I18n.of(context)!;
    showBottomSheetList(
      title: t.man_selected_pass,
      children: [
        ListTile(
          leading: const Icon(Icons.person_search),
          title: Text(t.lookup),
          enabled: kdbxEntry != null,
          onTap: () {
            context.router.pop();
            context.router.platformNavigate(LookAccountRoute(
              kdbxEntry: kdbxEntry!,
              uuid: kdbxEntry.uuid,
            ));
          },
        ),
        ListTile(
          leading: const Icon(Icons.drive_file_move_rounded),
          title: Text(t.move_selected),
          enabled: _selecteds.isNotEmpty,
          onTap: () {
            context.router.pop();
            _move(_selecteds);
          },
        ),
        ListTile(
          iconColor: Theme.of(context).colorScheme.error,
          textColor: Theme.of(context).colorScheme.error,
          leading: const Icon(Icons.delete),
          title: Text(t.delete_selected),
          enabled: _selecteds.isNotEmpty,
          onTap: () {
            context.router.pop();
            _delete(_selecteds);
          },
        ),
      ],
    );
  }

  void _allSelect(bool all) {
    if (all) {
      _selecteds
        ..clear()
        ..addAll(_totalEntry);
    } else {
      _selecteds.clear();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        automaticallyImplyLeading: automaticallyImplyLeading,
        leading: autoBack(),
        title: Padding(
          padding: const EdgeInsets.only(left: 12, right: 12),
          child: TextField(
            controller: _searchController,
            cursorHeight: 16,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              isCollapsed: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 12,
              ),
              hintText: t.search,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: IconButton(
                  iconSize: 16,
                  padding: const EdgeInsets.all(4),
                  onPressed: showSearchHelpDialog,
                  icon: const Icon(
                    Icons.help_outline_rounded,
                    size: 16,
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 30,
                maxWidth: 30,
                minHeight: 24,
                maxHeight: 24,
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _searchController.text.isNotEmpty
                    ? IconButton(
                        iconSize: 16,
                        padding: const EdgeInsets.all(4),
                        onPressed: () {
                          _searchController.text = "";
                        },
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                        ),
                      )
                    : null,
              ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 30,
                maxWidth: 30,
                minHeight: 24,
                maxHeight: 24,
              ),
            ),
          ),
        ),
        actions: [
          Checkbox(
            value: _isAllSelect,
            onChanged: _totalEntry.isNotEmpty
                ? (value) => _allSelect(value ?? false)
                : null,
          ),
          IconButton(
            tooltip: t.invert_select,
            onPressed: _totalEntry.isNotEmpty && _selecteds.isNotEmpty
                ? _showSelectorEntryAction
                : null,
            icon: const Icon(Icons.menu_open_rounded),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _totalEntry.length,
        itemBuilder: (context, index) {
          return _buildListItem(_totalEntry[index]);
        },
      ),
    );
  }

  Widget _buildListItem(KdbxEntry kdbxEntry) {
    return CustomContextMenuRegion<GroupsManageItemMenu>(
      enabled: isDesktop,
      onItemSelected: (type) {
        setState(() {
          _showMenu = null;
        });

        if (type == null) {
          return;
        }
        switch (type) {
          case GroupsManageItemMenu.view:
            context.router.platformNavigate(LookAccountRoute(
              kdbxEntry: kdbxEntry,
              uuid: kdbxEntry.uuid,
            ));
            break;
          case GroupsManageItemMenu.edit:
            context.router.platformNavigate(EditAccountRoute(
              kdbxEntry: kdbxEntry,
              uuid: kdbxEntry.uuid,
            ));
            break;
          case GroupsManageItemMenu.copy:
            writeClipboard(kdbxEntry.getNonNullString(KdbxKeyCommon.USER_NAME));
            break;
          case GroupsManageItemMenu.move:
            _move([kdbxEntry]);
            break;
          case GroupsManageItemMenu.move_selected:
            _move(_selecteds);
            break;
          case GroupsManageItemMenu.delete:
            _delete([kdbxEntry]);
            break;
          case GroupsManageItemMenu.delete_selected:
            _delete(_selecteds);
            break;
        }
      },
      builder: (context) {
        final t = I18n.of(context)!;

        setState(() {
          _showMenu = kdbxEntry;
        });

        return ContextMenu(
          entries: [
            MenuItem(
              label: t.lookup,
              icon: Icons.person_search,
              value: GroupsManageItemMenu.view,
            ),
            MenuItem(
              label: t.edit_account,
              icon: Icons.edit,
              value: GroupsManageItemMenu.edit,
            ),
            const MenuDivider(),
            MenuItem(
              label: t.copy,
              icon: Icons.copy,
              value: GroupsManageItemMenu.copy,
            ),
            const MenuDivider(),
            MenuItem(
              label: t.move,
              icon: Icons.move_down,
              value: GroupsManageItemMenu.move,
            ),
            MenuItem(
              label: t.delete,
              icon: Icons.delete,
              value: GroupsManageItemMenu.delete,
              color: Theme.of(context).colorScheme.error,
            ),
            const MenuDivider(),
            MenuItem(
              label: t.move_selected,
              enabled: _selecteds.isNotEmpty,
              icon: Icons.move_down,
              value: GroupsManageItemMenu.move_selected,
            ),
            MenuItem(
              label: t.delete_selected,
              enabled: _selecteds.isNotEmpty,
              icon: Icons.delete,
              value: GroupsManageItemMenu.delete_selected,
              color: Theme.of(context).colorScheme.error,
            ),
          ],
        );
      },
      child: ListTile(
        selected: _showMenu == kdbxEntry,
        onTap: () => _onItemTap(kdbxEntry),
        onLongPress:
            isMobile ? () => _showSelectorEntryAction(kdbxEntry) : null,
        leading: KdbxIconWidget(
          kdbxIcon: KdbxIconWidgetData(
            icon: kdbxEntry.icon.get() ?? KdbxIcon.Key,
            customIcon: kdbxEntry.customIcon,
          ),
        ),
        trailing:
            _selecteds.contains(kdbxEntry) ? const Icon(Icons.done) : null,
        title: Text(getKdbxObjectTitle(kdbxEntry)),
      ),
    );
  }
}
