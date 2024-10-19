import 'package:flutter/material.dart';

import '../../context/kdbx.dart';
import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../widget/common.dart';
import '../../widget/extension_state.dart';
import '../page.dart';

class ManageGroupEntry extends StatefulWidget {
  const ManageGroupEntry({super.key});

  static const routeName = "/manage_group_entry";

  @override
  State<ManageGroupEntry> createState() => _ManageGroupEntryState();
}

class _ManageGroupEntryState extends State<ManageGroupEntry> {
  final TextEditingController _searchController = TextEditingController();

  final KbdxSearchHandler _kbdxSearchHandler = KbdxSearchHandler();

  // 总选中
  final List<KdbxEntry> _selecteds = [];
  KdbxGroup? _kdbxGroup;

  final List<KdbxEntry> _totalEntry = [];

  bool get _isAllSelect => _selecteds.length == _totalEntry.length;

  // 搜索选中
  List<KdbxEntry> get _selectedList =>
      _selecteds.where((item) => _totalEntry.contains(item)).toList();

  @override
  void initState() {
    _searchController.addListener(_search);
    Future.delayed(Duration.zero, () {
      _kbdxSearchHandler
          .setFieldOther(KdbxProvider.of(context)!.fieldStatistic.customFields);
    });
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _selecteds.clear();
    super.dispose();
  }

  void _search() {
    _totalEntry.clear();
    _totalEntry.addAll(_kbdxSearchHandler.search(
      _searchController.text,
      _kdbxGroup?.entries ?? [],
    ));
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

  void _deleteSelecteds() async {
    final t = I18n.of(context)!;
    if (await showConfirmDialog(
      title: t.delete,
      message: t.is_move_recycle,
    )) {
      final kdbx = KdbxProvider.of(context)!;
      for (var item in _selecteds) {
        kdbx.deleteEntry(item);
      }
      await kdbxSave(kdbx);
      _selecteds.clear();
      _search();
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
      _search();
    }
  }

  void _showSelectorEntryAction() {
    final t = I18n.of(context)!;
    showBottomSheetList(
      title: t.man_selected_pass,
      children: [
        ListTile(
          leading: const Icon(Icons.drive_file_move_rounded),
          title: Text(t.move),
          onTap: () {
            Navigator.of(context).pop();
            _moveSelecteds();
          },
        ),
        ListTile(
          iconColor: Theme.of(context).colorScheme.error,
          textColor: Theme.of(context).colorScheme.error,
          leading: const Icon(Icons.delete),
          title: Text(t.delete),
          onTap: () {
            Navigator.of(context).pop();
            _deleteSelecteds();
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

  void _invertSelect() {
    final uuids = _selecteds.map((item) => item.uuid).toList();
    final result = _totalEntry.where((item) => !uuids.contains(item.uuid));
    _selecteds
      ..clear()
      ..addAll(result);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    bool isFirst = _kdbxGroup == null;

    _kdbxGroup ??= ModalRoute.of(context)!.settings.arguments as KdbxGroup?;

    if (_kdbxGroup == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(t.man_group_pass),
        ),
        body: Center(
          child: Text(t.empty_group),
        ),
      );
    }

    if (isFirst) {
      _search();
    }

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 18.0),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(999),
                right: Radius.circular(999),
              ),
            ),
            hintText: t.search,
          ),
        ),
        actions: const [
          SizedBox(
            width: 56.0,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _totalEntry.length,
        itemBuilder: (context, index) {
          return _buildListItem(_totalEntry[index]);
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
        color: NavigationBarTheme.of(context).backgroundColor ??
            Theme.of(context).colorScheme.surfaceContainer,
        child: Row(
          children: [
            Checkbox(
              value: _isAllSelect,
              onChanged: _totalEntry.isNotEmpty
                  ? (value) => _allSelect(value ?? false)
                  : null,
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _totalEntry.isNotEmpty
                  ? () => _allSelect(!_isAllSelect)
                  : null,
              child: Opacity(
                opacity: _totalEntry.isNotEmpty ? 1.0 : 0.45,
                child: Text(
                  t.all_select(
                    _selectedList.length,
                    _totalEntry.length,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: _totalEntry.isNotEmpty ? _invertSelect : null,
              child: Text(t.invert_select),
            ),
            const Expanded(child: SizedBox()),
            IconButton(
              onPressed:
                  _selecteds.isNotEmpty ? _showSelectorEntryAction : null,
              icon: const Icon(Icons.menu_open_rounded),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(KdbxEntry kdbxEntry) {
    return ListTile(
      onTap: () => _onItemTap(kdbxEntry),
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          routeSettings: RouteSettings(
            name: LookAccountPage.routeName_readOnly,
            arguments: kdbxEntry,
          ),
          builder: (context) => const LookAccountPage(),
        );
      },
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
