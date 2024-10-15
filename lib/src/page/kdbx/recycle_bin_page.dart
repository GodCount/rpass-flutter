import 'package:flutter/material.dart';

import '../page.dart';
import '../../context/kdbx.dart';
import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../widget/common.dart';
import '../../widget/extension_state.dart';
class RecycleBinPage extends StatefulWidget {
  const RecycleBinPage({super.key});

  static const routeName = "/recycle_bin";

  @override
  State<RecycleBinPage> createState() => _RecycleBinPageState();
}

class _RecycleBinPageState extends State<RecycleBinPage> {
  final List<KdbxObject> _selecteds = [];
  bool _isLongPress = false;

  void _save() async {
    await kdbxSave(KdbxProvider.of(context)!);
    setState(() {});
  }

  void _deleteWarnDialog(VoidCallback confirmCallback) async {
    final t = I18n.of(context)!;
    if (await showConfirmDialog(
      title: "永久删除",
      message: "删除项目后将无法恢复!",
      confirm: t.delete,
    )) {
      confirmCallback();
    }
  }

  void showRecycleBinAction(KdbxObject kdbxObject) {
    showBottomSheetList(
      title: getKdbxObjectTitle(kdbxObject),
      children: [
        if (kdbxObject is KdbxEntry)
          ListTile(
            leading: const Icon(Icons.person_search),
            title: const Text("查看"),
            onTap: () async {
              await Navigator.of(context).popAndPushNamed(
                LookAccountPage.routeName,
                arguments: kdbxObject,
              );
              setState(() {});
            },
          ),
        ListTile(
          iconColor: Theme.of(context).colorScheme.primary,
          textColor: Theme.of(context).colorScheme.primary,
          leading: const Icon(Icons.restore_from_trash),
          title: const Text("恢复"),
          onTap: () {
            KdbxProvider.of(context)!.restoreObject(kdbxObject);
            _save();
            Navigator.of(context).pop();
          },
        ),
        ListTile(
          iconColor: Theme.of(context).colorScheme.error,
          textColor: Theme.of(context).colorScheme.error,
          leading: const Icon(Icons.delete_forever),
          title: const Text("彻底删除"),
          onTap: () {
            KdbxProvider.of(context)!.deletePermanently(kdbxObject);

            _save();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  void _clearLongPress() {
    _isLongPress = false;
    _selecteds.clear();
  }

  void _restoreObjects() {
    if (_selecteds.isEmpty) return;
    final kdbx = KdbxProvider.of(context)!;
    for (var item in _selecteds) {
      kdbx.restoreObject(item);
    }
    _clearLongPress();
    _save();
  }

  void _deletePermanentlys() {
    if (_selecteds.isEmpty) return;
    final kdbx = KdbxProvider.of(context)!;
    for (var item in _selecteds) {
      kdbx.deletePermanently(item);
    }
    _clearLongPress();
    _save();
  }

  void _onItemTap(KdbxObject kdbxObject) {
    if (_isLongPress) {
      if (_selecteds.contains(kdbxObject)) {
        _selecteds.remove(kdbxObject);
        if (_selecteds.isEmpty) {
          _isLongPress = false;
        }
      } else {
        _selecteds.add(kdbxObject);
      }
      setState(() {});
    } else {
      showRecycleBinAction(kdbxObject);
    }
  }

  void _onItemLongPress(KdbxObject kdbxObject) {
    setState(() {
      if (_isLongPress) {
        _clearLongPress();
      } else {
        _isLongPress = true;
        _selecteds.add(kdbxObject);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final kdbx = KdbxProvider.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("回收站"),
        automaticallyImplyLeading: !_isLongPress,
        leading: _isLongPress
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _isLongPress = false;
                    _selecteds.clear();
                  });
                },
                icon: const Icon(Icons.close_rounded),
              )
            : null,
        actions: _isLongPress
            ? [
                IconButton(
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: _restoreObjects,
                  icon: const Icon(Icons.restore_from_trash),
                ),
                IconButton(
                  color: Theme.of(context).colorScheme.error,
                  onPressed: () => _deleteWarnDialog(_deletePermanentlys),
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
    return ListTile(
      onTap: () => _onItemTap(kdbxObject),
      onLongPress: () => _onItemLongPress(kdbxObject),
      leading: KdbxIconWidget(
        kdbxIcon: KdbxIconWidgetData(
          icon: kdbxObject is KdbxEntry ? KdbxIcon.Key : KdbxIcon.Folder,
        ),
      ),
      trailing: _isLongPress && _selecteds.contains(kdbxObject)
          ? const Icon(Icons.done)
          : null,
      title: Text(getKdbxObjectTitle(kdbxObject)),
    );
  }
}
