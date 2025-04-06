import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:rpass/src/util/common.dart';

import '../../context/kdbx.dart';
import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../util/route.dart';
import '../../widget/common.dart';
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
      final args = data.argsAs<_GroupsArgs>();
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

  void _update() {
    setState(() {});
  }

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      KdbxProvider.of(context)!.addListener(_update);
    });
    super.initState();
  }

  @override
  void dispose() {
    KdbxProvider.of(context)!.removeListener(_update);
    super.dispose();
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
          final kdbxGroup = groups[i];
          return ListTile(
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
            subtitle: kdbxGroup.times.creationTime.get() != null
                ? Text(
                    dateFormat(kdbxGroup.times.creationTime.get()!.toLocal()),
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            onTap: () {
              context.router.navigate(
                PasswordsRoute(
                  search: 'g:"${kdbxGroup.name.get() ?? ''}"',
                ),
              );
            },
            onLongPress: () => showKdbxGroupAction(
              kdbxGroup.name.get() ?? '',
              onManageTap: () {
                context.router.push(ManageGroupEntryRoute(
                  kdbxGroup: kdbxGroup,
                ));
              },
              onModifyTap: () => setKdbxGroup(
                KdbxGroupData(
                  name: kdbxGroup.name.get() ?? '',
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
            ),
          );
        },
        itemCount: groups.length,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setKdbxGroup(
          KdbxGroupData(
            name: '',
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
