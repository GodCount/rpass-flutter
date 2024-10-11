import 'package:flutter/material.dart';

import '../../context/kdbx.dart';
import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../widget/common.dart';
import '../page.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => GroupsPageState();
}

class KdbxGroupData {
  KdbxGroupData({
    required this.name,
    required this.kdbxIcon,
    this.kdbxGroup,
  });

  String name;
  KdbxIconWidgetData kdbxIcon;
  KdbxGroup? kdbxGroup;
}

class GroupsPageState extends State<GroupsPage>
    with AutomaticKeepAliveClientMixin, CommonWidgetUtil, BottomSheetUtil {
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

  void _kdbxGroupSave(KdbxGroupData data) async {
    final kdbx = KdbxProvider.of(context)!;

    final kdbxGroup = data.kdbxGroup ?? kdbx.createGroup(data.name);

    if (data.name != kdbxGroup.name.get()) {
      kdbxGroup.name.set(data.name);
    }

    if (data.kdbxIcon.customIcon != null) {
      kdbxGroup.customIcon = data.kdbxIcon.customIcon;
    } else if (data.kdbxIcon.icon != kdbxGroup.icon.get()) {
      kdbxGroup.icon.set(data.kdbxIcon.icon);
    }

    await kdbxSave(kdbx);
  }

  void _kdbxGroupDelete(KdbxGroup kdbxGroup) async {
    if (await showConfirmDialog(
      title: "删除",
      message: "是否将项目移动到回收站!",
    )) {
      final kdbx = KdbxProvider.of(context)!;
      kdbx.deleteGroup(kdbxGroup);
      await kdbxSave(kdbx);
    }
  }

  void _setKdbxGroup(KdbxGroupData data) async {
    final kdbx = KdbxProvider.of(context)!;

    final result = await InputDialog.openDialog(
      context,
      title: "修改",
      label: "新的名称",
      initialValue: data.name,
      limitItems: kdbx.rootGroups
          .map((item) => item.name.get() ?? '')
          .where((item) => item.isNotEmpty && item != data.name)
          .toSet()
          .toList(),
      leadingBuilder: (state) {
        return IconButton(
          onPressed: () async {
            final reslut =
                await Navigator.of(context).pushNamed(SelectIconPage.routeName);
            if (reslut != null && reslut is KdbxIconWidgetData) {
              data.kdbxIcon = reslut;
              state.setState(() {});
            }
          },
          icon: KdbxIconWidget(
            kdbxIcon: data.kdbxIcon,
            size: 24,
          ),
        );
      },
    );
    if (result is String) {
      data.name = result;
      _kdbxGroupSave(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = I18n.of(context)!;

    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final kdbx = KdbxProvider.of(context)!;

    final groups = kdbx.rootGroups;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(t.setting),
      ),
      body: GridView.count(
        crossAxisCount: width ~/ 128,
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
        children: groups.map((item) => _buildGroupItem(item)).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _setKdbxGroup(
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
                .toPasswordPageSearch("g:${kdbxGroup.name.get() ?? ''}");
          },
          onLongPress: () => showKdbxGroupAction(
            kdbxGroup.name.get() ?? '',
            onModifyTap: () => _setKdbxGroup(
              KdbxGroupData(
                name: kdbxGroup.name.get() ?? '',
                kdbxIcon: KdbxIconWidgetData(
                  icon: kdbxGroup.icon.get() ?? KdbxIcon.Folder,
                  customIcon: kdbxGroup.customIcon,
                ),
                kdbxGroup: kdbxGroup,
              ),
            ),
            onDeleteTap: () => _kdbxGroupDelete(kdbxGroup),
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
