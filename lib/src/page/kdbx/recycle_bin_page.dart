import 'package:flutter/material.dart';

import '../../context/kdbx.dart';
import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../widget/common.dart';

class RecycleBinPage extends StatefulWidget {
  const RecycleBinPage({super.key});

  static const routeName = "/recycle_bin";

  @override
  State<RecycleBinPage> createState() => _RecycleBinPageState();
}

class _RecycleBinPageState extends State<RecycleBinPage>
    with CommonWidgetUtil, BottomSheetUtil {
  final List<KdbxObject> _selecteds = [];
  bool _isLongPress = false;

  void _save() async {
    try {
      await KdbxProvider.of(context)!.save();
    } catch (e) {
      print(e);
      // TODO! 保存失败提示
    } finally {
      setState(() {});
    }
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
      showRecycleBinAction(
        kdbxObject,
        onRestoreTap: () {
          KdbxProvider.of(context)!.restoreObject(kdbxObject);
          _save();
        },
        onDeleteTap: () => _deleteWarnDialog(() {
          KdbxProvider.of(context)!.deletePermanently(kdbxObject);
          _save();
        }),
      );
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
