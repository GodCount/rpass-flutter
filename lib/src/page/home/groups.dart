import 'package:flutter/material.dart';

import '../../context/kdbx.dart';
import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../widget/common.dart';
import '../../widget/extension_state.dart';
import '../page.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => GroupsPageState();
}

class GroupsPageState extends State<GroupsPage>
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
      padding: const EdgeInsets.all(8),
      width: 128,
      height: 128,
      child: Card(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(6.0)),
        ),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(6.0)),
          onTap: () {
            Home.of(context)!
                .toPasswordPageSearch('g:"${kdbxGroup.name.get() ?? ''}"');
          },
          onLongPress: () => showKdbxGroupAction(
            kdbxGroup.name.get() ?? '',
            onManageTap: () {
              Navigator.of(context)
                  .pushNamed(ManageGroupEntry.routeName, arguments: kdbxGroup);
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
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
                softWrap: false,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            ],
          ),
        ),
      ),
    );
  }
}
