import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:keepass_core/keepass_core.dart';
import 'package:logging/logging.dart';

import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../store/index.dart';
import '../../util/common.dart';
import '../../util/route.dart';
import '../../widget/extension_state.dart';
import '../../widget/form.dart';
import '../../widget/kdbx_icon.dart';
import '../route.dart';

// ignore: unused_element
final _logger = Logger("page:edit_group_page");

class _EditGroupPageArgs extends PageRouteArgs {
  _EditGroupPageArgs({super.key});
}

class EditGroupPageRoute extends PageRouteInfo<_EditGroupPageArgs> {
  EditGroupPageRoute({Key? key, String? id})
    : super(
        name,
        args: _EditGroupPageArgs(key: key),
        rawPathParams: {"uuid": id},
      );

  static const name = "EditGroupPageRoute";

  static final PageInfo page = PageInfo.builder(
    name,
    builder: (context, data) {
      final args = data.argsAs<_EditGroupPageArgs>(
        orElse: () => _EditGroupPageArgs(),
      );

      final uuid = data.inheritedPathParams.optString("uuid");

      return EditGroupPagePage(key: args.key, id: uuid);
    },
  );
}

class EditGroupPagePage extends StatefulWidget {
  const EditGroupPagePage({super.key, this.id, this.dialog = false});

  final String? id;
  final bool dialog;

  @override
  State<EditGroupPagePage> createState() => _EditGroupPagePageState();
}

class _EditGroupPagePageState extends State<EditGroupPagePage>
    with SecondLevelPageAutoBack<EditGroupPagePage> {
  GlobalKey<FormState> _from = GlobalKey();

  late GroupData _kdbxGroupData = Store.kdbx.kdbx!.newGroup();

  bool _isDirty = false;

  @override
  void initState() {
    _getKdbxGroupData();
    super.initState();
  }

  void _getKdbxGroupData() async {
    final kdbxController = Store.kdbx;

    if (widget.id != null && widget.id != _kdbxGroupData.id) {
      try {
        _kdbxGroupData = await kdbxController.kdbx!.getGroup(id: widget.id!);
        setState(() {});
      } on KdbxError_NotFound {
        context.router.pop();
      } catch (e, s) {
        showError(e, s);
      }
    }
  }

  void _kdbxGroupSave() async {
    if (_from.currentState!.validate()) {
      _from.currentState!.save();

      if (await kdbxAction(KdbxAction.updateGroup(_kdbxGroupData))) {
        if (isDesktop && widget.dialog) {
          context.router.platformNavigate(
            ManageGroupEntryRoute(id: _kdbxGroupData.id),
          );
        } else {
          context.router.pop(_kdbxGroupData);
        }
      }
    }
  }

  @override
  void didUpdateWidget(covariant EditGroupPagePage oldWidget) {
    /// 触发整个 form 表进行重建
    if (widget.id != oldWidget.id) {
      if (widget.id != null) {
        _getKdbxGroupData();
      } else {
        _kdbxGroupData = Store.kdbx.kdbx!.newGroup();
      }
      _from = GlobalKey();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: automaticallyImplyLeading,
        leading: autoBack(),
        title: Text(t.edit_group),
      ),
      body: Form(
        key: _from,
        onChanged: () {
          if (!_isDirty) {
            setState(() {
              _isDirty = true;
            });
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          child: Column(
            children: [
              // 项目信息
              _cardColumn([
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(Icons.assessment_rounded),
                      ),
                      Text(
                        t.project_info,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: EntryTitleFormField(
                    initialValue: _kdbxGroupData.name,
                    label: t.title,
                    kdbxIcon: KdbxIconWidgetData(
                      icon:
                          _kdbxGroupData.icon ??
                          KdbxIconType.Folder.toKdbxIcon(),
                    ),
                    onSaved: (data) {
                      _kdbxGroupData.name = data!.$1;
                      _kdbxGroupData.icon = data.$2;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonFormField<bool>(
                    initialValue: _kdbxGroupData.enableDisplay,
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(t.enable_display_null_subtitle),
                      ),
                      DropdownMenuItem(
                        value: true,
                        child: Text(t.enable_display_true_subtitle),
                      ),
                      DropdownMenuItem(
                        value: false,
                        child: Text(t.enable_display_false_subtitle),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: t.display,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) {},
                    onSaved: (value) {
                      _kdbxGroupData.enableDisplay = value;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonFormField<bool>(
                    initialValue: _kdbxGroupData.enableSearching,
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(t.enable_searching_null_subtitle),
                      ),
                      DropdownMenuItem(
                        value: true,
                        child: Text(t.enable_searching_true_subtitle),
                      ),
                      DropdownMenuItem(
                        value: false,
                        child: Text(t.enable_searching_false_subtitle),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: t.search,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) {},
                    onSaved: (value) {
                      _kdbxGroupData.enableSearching = value;
                    },
                  ),
                ),
              ]),
              // 附加信息
              _cardColumn([
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(Icons.add_box_rounded),
                      ),
                      Text(
                        t.additional_info,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextFormField(
                    initialValue: _kdbxGroupData.notes,
                    decoration: InputDecoration(
                      labelText: t.description,
                      border: const OutlineInputBorder(),
                    ),
                    minLines: 1,
                    maxLines: 6,
                    onSaved: (value) {
                      _kdbxGroupData.notes = value!;
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 42),
            ],
          ),
        ),
      ),
      floatingActionButton: _isDirty
          ? FloatingActionButton(
              heroTag: const ValueKey("edit_group_float"),
              onPressed: _kdbxGroupSave,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(56 / 2)),
              ),
              child: const Icon(Icons.save),
            )
          : null,
    );
  }

  Widget _cardColumn(List<Widget> children) {
    return Card(
      margin: const EdgeInsets.all(6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
      ),
      child: ClipRRect(
        child: Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 12),
          child: Column(spacing: 12, children: children),
        ),
      ),
    );
  }
}
