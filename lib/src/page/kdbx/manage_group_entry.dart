import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../context/kdbx.dart';
import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../util/route.dart';
import '../../widget/common.dart';
import '../../widget/extension_state.dart';
import '../password/look_account.dart';

class _ManageGroupEntryArgs extends PageRouteArgs {
  _ManageGroupEntryArgs({
    super.key,
    required this.kdbxGroup,
  });

  final KdbxGroup kdbxGroup;
}

class ManageGroupEntryRoute extends PageRouteInfo<_ManageGroupEntryArgs> {
  ManageGroupEntryRoute({
    Key? key,
    required KdbxGroup kdbxGroup,
  }) : super(
          name,
          args: _ManageGroupEntryArgs(
            key: key,
            kdbxGroup: kdbxGroup,
          ),
        );

  static const name = "ManageGroupEntryRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_ManageGroupEntryArgs>();
      return ManageGroupEntryPage(
        key: args.key,
        kdbxGroup: args.kdbxGroup,
      );
    },
  );
}

class ManageGroupEntryPage extends StatefulWidget {
  const ManageGroupEntryPage({super.key, required this.kdbxGroup});

  final KdbxGroup kdbxGroup;

  @override
  State<ManageGroupEntryPage> createState() => _ManageGroupEntryPageState();
}

class _ManageGroupEntryPageState extends State<ManageGroupEntryPage>
    with SecondLevelPageAutoBack<ManageGroupEntryPage> {
  final TextEditingController _searchController = TextEditingController();

  final KbdxSearchHandler _kbdxSearchHandler = KbdxSearchHandler();

  // 总选中
  final List<KdbxEntry> _selecteds = [];

  final List<KdbxEntry> _totalEntry = [];

  bool get _isAllSelect => _selecteds.length == _totalEntry.length;

  // 搜索选中
  List<KdbxEntry> get _selectedList =>
      _selecteds.where((item) => _totalEntry.contains(item)).toList();

  @override
  void initState() {
    _searchController.addListener(_search);
    Future.delayed(Duration.zero, () {
      _kbdxSearchHandler.setFieldOther(
        KdbxProvider.of(context)!.fieldStatistic.customFields,
      );
      _search();
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
      widget.kdbxGroup.entries,
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
    final group = await showGroupSelectorDialog(widget.kdbxGroup);
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
            context.router.pop();
            _moveSelecteds();
          },
        ),
        ListTile(
          iconColor: Theme.of(context).colorScheme.error,
          textColor: Theme.of(context).colorScheme.error,
          leading: const Icon(Icons.delete),
          title: Text(t.delete),
          onTap: () {
            context.router.pop();
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

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: autoBack(),
        title: Padding(
          padding: const EdgeInsets.only(left: 12, right: 12),
          child: TextField(
            controller: _searchController,
            cursorHeight: 16,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              isCollapsed: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 12,
              ),
              hintText: t.search,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: IconButton(
                  iconSize: 16,
                  padding: const EdgeInsets.all(4),
                  onPressed: showSearchHelpDialog,
                  icon: const Icon(
                    Icons.help_outline_rounded,
                    size: 16,
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 30,
                maxWidth: 30,
                minHeight: 24,
                maxHeight: 24,
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _searchController.text.isNotEmpty
                    ? IconButton(
                        iconSize: 16,
                        padding: const EdgeInsets.all(4),
                        onPressed: () {
                          _searchController.text = "";
                        },
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                        ),
                      )
                    : null,
              ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 30,
                maxWidth: 30,
                minHeight: 24,
                maxHeight: 24,
              ),
            ),
          ),
        ),
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
          builder: (context) => ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16.0)),
            child: LookAccountPage(
              kdbxEntry: kdbxEntry,
              readOnly: true,
            ),
          ),
        );
      },
      leading: KdbxIconWidget(
        kdbxIcon: KdbxIconWidgetData(
          icon: kdbxEntry.icon.get() ?? KdbxIcon.Key,
          customIcon: kdbxEntry.customIcon,
        ),
      ),
      trailing: _selecteds.contains(kdbxEntry) ? const Icon(Icons.done) : null,
      title: Text(getKdbxObjectTitle(kdbxEntry)),
    );
  }
}
