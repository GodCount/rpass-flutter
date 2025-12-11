import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';

import '../../context/kdbx.dart';
import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../util/common.dart';
import '../../util/route.dart';
import '../../widget/kdbx_icon.dart';
import '../../widget/extension_state.dart';
import '../route.dart';
import 'route_wrap.dart';

class _GroupsArgs extends PageRouteArgs {
  _GroupsArgs({super.key});
}

class GroupsRoute extends PageRouteInfo<_GroupsArgs> {
  GroupsRoute({
    Key? key,
  }) : super(
          name,
          args: _GroupsArgs(key: key),
        );

  static const name = "GroupsRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_GroupsArgs>(
        orElse: () => _GroupsArgs(),
      );
      return GroupsPage(key: args.key);
    },
  );
}

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  VoidCallback? _removeKdbxListener;

  void _update() {
    setState(() {});
  }

  @override
  void initState() {
    final kdbx = KdbxProvider.of(context)!;
    kdbx.addListener(_update);
    _removeKdbxListener = () => kdbx.removeListener(_update);
    super.initState();
  }

  @override
  void dispose() {
    _removeKdbxListener?.call();
    _removeKdbxListener = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return isDesktop ? RouteWrap(child: _buildMobile()) : _buildMobile();
  }

  Widget _buildMobile() {
    final t = I18n.of(context)!;

    final kdbx = KdbxProvider.of(context)!;

    final groups = [kdbx.kdbxFile.body.rootGroup, ...kdbx.rootGroups];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(t.group),
      ),
      body: ListView.builder(
        itemBuilder: (context, i) {
          return _GroupsItem(kdbxGroup: groups[i]);
        },
        itemCount: groups.length,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setKdbxGroup(
          KdbxGroupData(
            name: '',
            notes: '',
            kdbxIcon: KdbxIconWidgetData(
              icon: KdbxIcon.Folder,
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(56 / 2),
          ),
        ),
        child: const Icon(Icons.group_add_rounded),
      ),
    );
  }
}

class _GroupsItem extends StatefulWidget {
  const _GroupsItem({
    required this.kdbxGroup,
  });

  final KdbxGroup kdbxGroup;

  @override
  State<_GroupsItem> createState() => _GroupsItemState();
}

class _GroupsItemState extends State<_GroupsItem>
    with NavigationHistoryObserver<_GroupsItem> {
  bool _selected = false;
  bool _showMenu = false;

  @override
  void didNavigationHistory() {
    if (context.topRoute.name == ManageGroupEntryRoute.name) {
      final selected = context.topRoute.inheritedPathParams.optString("uuid") ==
          widget.kdbxGroup.uuid.deBase64Uuid;

      if (selected != _selected) {
        setState(() {
          _selected = selected;
        });
      }
    } else if (_selected) {
      setState(() {
        _selected = false;
      });
    }
  }

  void _kdbxGroupDelete(KdbxGroup kdbxGroup) async {
    final t = I18n.of(context)!;

    if (await showConfirmDialog(
      title: t.delete,
      message: t.is_move_recycle,
    )) {
      final kdbx = KdbxProvider.of(context)!;
      kdbx.deleteGroup(kdbxGroup);
      await kdbxSave(kdbx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kdbxGroup = widget.kdbxGroup;
    return CustomContextMenuRegion<MyContextMenuItem>(
      enabled: isDesktop,
      onItemSelected: (type) {
        setState(() {
          _showMenu = false;
        });
        if (type == null) {
          return;
        }
        switch (type) {
          case SearchContextMenuItem():
            context.router.navigate(
              PasswordsRoute(
                search: 'g:"${kdbxGroup.name.get() ?? ''}"',
              ),
            );
            break;
          case ModifyContextMenuItem():
            setKdbxGroup(
              KdbxGroupData(
                name: kdbxGroup.name.get() ?? '',
                notes: kdbxGroup.notes.get() ?? '',
                enableSearching: kdbxGroup.enableSearching.get(),
                enableDisplay: kdbxGroup.enableDisplay.get(),
                kdbxIcon: KdbxIconWidgetData(
                  icon: kdbxGroup.icon.get() ?? KdbxIcon.Folder,
                  customIcon: kdbxGroup.customIcon,
                ),
                kdbxGroup: kdbxGroup,
              ),
            );
            break;
          case DeleteContextMenuItem():
            _kdbxGroupDelete(kdbxGroup);
            break;
          default:
            break;
        }
      },
      builder: (context) {
        final t = I18n.of(context)!;

        setState(() {
          _showMenu = true;
        });

        return ContextMenu(
          entries: [
            MenuItem(
              label: t.search,
              icon: Icons.search,
              value: MyContextMenuItem.search(),
            ),
            MenuItem(
              label: t.modify,
              icon: Icons.edit,
              value: MyContextMenuItem.modify(),
            ),
            const MenuDivider(),
            MenuItem(
              label: t.delete,
              enabled: kdbxGroup.parent != null,
              icon: Icons.delete,
              value: MyContextMenuItem.delete(),
              color: Theme.of(context).colorScheme.error,
            ),
          ],
        );
      },
      child: ListTile(
        selected: _selected || _showMenu,
        isThreeLine: true,
        leading: KdbxIconWidget(
          kdbxIcon: KdbxIconWidgetData(
            icon: kdbxGroup.icon.get() ?? KdbxIcon.Folder,
            customIcon: kdbxGroup.customIcon,
          ),
          size: 24,
        ),
        title: Text(
          kdbxGroup.name.get() ?? "",
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kdbxGroup.notes.get() ?? "",
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  (kdbxGroup.times.creationTime.get() ??
                          DateTime.fromMillisecondsSinceEpoch(0))
                      .toLocal()
                      .formatDate,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            ],
          ),
        ),
        onTap: () {
          context.router.platformNavigate(
            ManageGroupEntryRoute(
              kdbxGroup: kdbxGroup,
              uuid: kdbxGroup.uuid,
            ),
          );
        },
        onLongPress: isMobile
            ? () => showKdbxGroupAction(
                  kdbxGroup.name.get() ?? '',
                  onSearchTap: () {
                    context.router.navigate(
                      PasswordsRoute(
                        search: 'g:"${kdbxGroup.name.get() ?? ''}"',
                      ),
                    );
                  },
                  onModifyTap: () => setKdbxGroup(
                    KdbxGroupData(
                      name: kdbxGroup.name.get() ?? '',
                      notes: kdbxGroup.notes.get() ?? '',
                      enableSearching: kdbxGroup.enableSearching.get(),
                      enableDisplay: kdbxGroup.enableDisplay.get(),
                      kdbxIcon: KdbxIconWidgetData(
                        icon: kdbxGroup.icon.get() ?? KdbxIcon.Folder,
                        customIcon: kdbxGroup.customIcon,
                      ),
                      kdbxGroup: kdbxGroup,
                    ),
                  ),
                  onDeleteTap: kdbxGroup.parent != null
                      ? () => _kdbxGroupDelete(kdbxGroup)
                      : null,
                )
            : null,
      ),
    );
  }
}
