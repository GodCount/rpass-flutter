import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../context/kdbx.dart';
import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../util/route.dart';
import '../../widget/common.dart';
import '../../widget/extension_state.dart';
import '../route.dart';

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
    final t = I18n.of(context)!;

    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final kdbx = KdbxProvider.of(context)!;

    final groups = [kdbx.kdbxFile.body.rootGroup, ...kdbx.rootGroups];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(t.group),
      ),
      body: GridView.count(
        crossAxisCount: width ~/ 128,
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
        children: groups.map((item) => _buildGroupItem(item)).toList(),
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

  Widget _buildGroupItem(KdbxGroup kdbxGroup) {
    return Container(
      padding: const EdgeInsets.all(4),
      width: 128,
      height: 128,
      child: Card(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(6.0)),
        ),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(6.0)),
          onTap: () {
            // TODO! 新的跳转搜索方式
            // Home.of(context)!
            //     .toPasswordPageSearch('g:"${kdbxGroup.name.get() ?? ''}"');
          },
          onLongPress: () => showKdbxGroupAction(
            kdbxGroup.name.get() ?? '',
            onManageTap: () {
              context.router.push(ManageGroupEntryRoute(kdbxGroup: kdbxGroup));
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
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                KdbxIconWidget(
                  kdbxIcon: KdbxIconWidgetData(
                    icon: kdbxGroup.icon.get() ?? KdbxIcon.Folder,
                    customIcon: kdbxGroup.customIcon,
                  ),
                  size: 64,
                ),
                Text(
                  kdbxGroup.name.get() ?? '',
                  softWrap: true,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
