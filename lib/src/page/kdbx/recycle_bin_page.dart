import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../util/route.dart';
import '../route.dart';
import '../../context/kdbx.dart';
import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../widget/common.dart';
import '../../widget/extension_state.dart';

class _RecycleBinArgs extends PageRouteArgs {
  _RecycleBinArgs({super.key});
}

class RecycleBinRoute extends PageRouteInfo<_RecycleBinArgs> {
  RecycleBinRoute({
    Key? key,
  }) : super(
          name,
          args: _RecycleBinArgs(key: key),
        );

  static const name = "RecycleBinRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_RecycleBinArgs>();
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
    with SecondLevelPageAutoBack<RecycleBinPage> {
  final List<KdbxObject> _selecteds = [];
  bool _isLongPress = false;

  void _save() async {
    await kdbxSave(KdbxProvider.of(context)!);
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

  void _showRecycleBinAction(KdbxObject kdbxObject) {
    final t = I18n.of(context)!;

    showBottomSheetList(
      title: getKdbxObjectTitle(kdbxObject),
      children: [
        if (kdbxObject is KdbxEntry)
          ListTile(
            leading: const Icon(Icons.person_search),
            title: Text(t.lookup),
            onTap: () async {
              await context.router.popAndPush(
                LookAccountRoute(kdbxEntry: kdbxObject),
              );
              setState(() {});
            },
          ),
        ListTile(
          iconColor: Theme.of(context).colorScheme.primary,
          textColor: Theme.of(context).colorScheme.primary,
          leading: const Icon(Icons.restore_from_trash),
          title: Text(t.revert),
          onTap: () {
            KdbxProvider.of(context)!.restoreObject(kdbxObject);
            _save();
            context.router.pop();
          },
        ),
        ListTile(
          iconColor: Theme.of(context).colorScheme.error,
          textColor: Theme.of(context).colorScheme.error,
          leading: const Icon(Icons.delete_forever),
          title: Text(t.completely_delete),
          onTap: () => _deleteWarnDialog(
            () {
              KdbxProvider.of(context)!.deletePermanently(kdbxObject);
              _save();
              context.router.pop();
            },
          ),
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
      _showRecycleBinAction(kdbxObject);
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
  void initState() {
    Future.delayed(Duration.zero, () {
      KdbxProvider.of(context)!.addListener(_onKdbxSave);
    });
    super.initState();
  }

  void _onKdbxSave() {
    setState(() {});
  }

  @override
  void dispose() {
    _selecteds.clear();
    KdbxProvider.of(context)!.removeListener(_onKdbxSave);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    final kdbx = KdbxProvider.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.recycle_bin),
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
            : autoBack(),
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
