import 'package:flutter/material.dart';

import '../../context/kdbx.dart';
import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../widget/common.dart';
import '../../widget/extension_state.dart';

class ManageGroupEntry extends StatefulWidget {
  const ManageGroupEntry({super.key});

  static const routeName = "/manage_group_entry";

  @override
  State<ManageGroupEntry> createState() => _ManageGroupEntryState();
}

class _ManageGroupEntryState extends State<ManageGroupEntry> {
  final List<KdbxEntry> _selecteds = [];
  KdbxGroup? _kdbxGroup;

  void _onItemTap(KdbxEntry kdbxEntry) {
    if (_selecteds.contains(kdbxEntry)) {
      _selecteds.remove(kdbxEntry);
    } else {
      _selecteds.add(kdbxEntry);
    }
    setState(() {});
  }

  void _deleteSelecteds() async {
    final t = I18n.of(context)!;
    if (await showConfirmDialog(
      title: "删除",
      message: "是否将项目移动到回收站!",
    )) {
      final kdbx = KdbxProvider.of(context)!;
      for (var item in _selecteds) {
        kdbx.deleteEntry(item);
      }
      await kdbxSave(kdbx);
      _selecteds.clear();
      setState(() {});
    }
  }

  void _moveSelecteds() async {
    final group = await showGroupSelectorDialog(_kdbxGroup);
    if (group != null) {
      final kdbx = KdbxProvider.of(context)!;
      for (var item in _selecteds) {
        kdbx.kdbxFile.move(item, group);
      }
      await kdbxSave(kdbx);
      _selecteds.clear();
      setState(() {});
    }
  }

  void _showSelectorEntryAction() {
    showBottomSheetList(
      title: "管理选中密码",
      children: [
        ListTile(
          leading: const Icon(Icons.drive_file_move_rounded),
          title: const Text("移动"),
          onTap: () {
            Navigator.of(context).pop();
            _moveSelecteds();
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete),
          title: const Text("删除"),
          onTap: () {
            Navigator.of(context).pop();
            _deleteSelecteds();
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _selecteds.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    _kdbxGroup ??= ModalRoute.of(context)!.settings.arguments as KdbxGroup?;

    if (_kdbxGroup == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text("组内密码管理"),
        ),
        body: const Center(
          child: Text("没有找到组！"),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("组内密码管理"),
            Text(
              "(${_selecteds.length}/${_kdbxGroup!.entries.length})",
              style: Theme.of(context).textTheme.bodyLarge,
            )
          ],
        ),
        actions: [
          Checkbox(
            value: _selecteds.length == _kdbxGroup!.entries.length,
            onChanged: _kdbxGroup!.entries.isNotEmpty
                ? (value) {
                    if (value != null && value) {
                      _selecteds
                        ..clear()
                        ..addAll(_kdbxGroup!.entries);
                    } else {
                      _selecteds.clear();
                    }
                    setState(() {});
                  }
                : null,
          )
        ],
      ),
      body: ListView.builder(
        itemCount: _kdbxGroup!.entries.length,
        itemBuilder: (context, index) {
          return _buildListItem(_kdbxGroup!.entries[index]);
        },
      ),
      floatingActionButton: _selecteds.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showSelectorEntryAction,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(56 / 2),
                ),
              ),
              child: const Icon(Icons.done),
            )
          : null,
    );
  }

  Widget _buildListItem(KdbxEntry kdbxEntry) {
    return ListTile(
      onTap: () => _onItemTap(kdbxEntry),
      leading: KdbxIconWidget(
        kdbxIcon: KdbxIconWidgetData(
            icon: kdbxEntry.icon.get() ?? KdbxIcon.Key,
            customIcon: kdbxEntry.customIcon),
      ),
      trailing: _selecteds.contains(kdbxEntry) ? const Icon(Icons.done) : null,
      title: Text(getKdbxObjectTitle(kdbxEntry)),
    );
  }
}
