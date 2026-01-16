import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../context/kdbx.dart';
import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../util/route.dart';
import '../../widget/extension_state.dart';
import '../../widget/form.dart';
import '../../widget/kdbx_icon.dart';

final _logger = Logger("page:edit_group_page");

class _EditGroupPageArgs extends PageRouteArgs {
  _EditGroupPageArgs({super.key, this.kdbxGroup});

  final KdbxGroup? kdbxGroup;
}

class EditGroupPageRoute extends PageRouteInfo<_EditGroupPageArgs> {
  EditGroupPageRoute({Key? key, KdbxGroup? kdbxGroup, KdbxUuid? uuid})
    : super(
        name,
        args: _EditGroupPageArgs(key: key, kdbxGroup: kdbxGroup),
        rawPathParams: {"uuid": uuid?.deBase64Uuid},
      );

  static const name = "EditGroupPageRoute";

  static final PageInfo page = PageInfo.builder(
    name,
    builder: (context, data) {
      final args = data.argsAs<_EditGroupPageArgs>(
        orElse: () {
          final kdbx = KdbxProvider.of(context)!;
          final uuid = data.inheritedPathParams.optString("uuid")?.kdbxUuid;
          final kdbxGroup = uuid != null ? kdbx.findGroupByUuid(uuid) : null;

          return _EditGroupPageArgs(kdbxGroup: kdbxGroup);
        },
      );
      return EditGroupPagePage(key: args.key, kdbxGroup: args.kdbxGroup);
    },
  );
}

class EditGroupPagePage extends StatefulWidget {
  const EditGroupPagePage({super.key, this.kdbxGroup});

  final KdbxGroup? kdbxGroup;

  @override
  State<EditGroupPagePage> createState() => _EditGroupPagePageState();
}

class _EditGroupPagePageState extends State<EditGroupPagePage>
    with SecondLevelPageAutoBack<EditGroupPagePage> {
  GlobalKey<FormState> _from = GlobalKey();

  late KdbxGroupData _kdbxGroupData = _getKdbxGroupData();

  bool _isDirty = false;

  KdbxGroupData _getKdbxGroupData() {
    return widget.kdbxGroup != null
        ? KdbxGroupData(
            name: widget.kdbxGroup!.name.get() ?? '',
            notes: widget.kdbxGroup!.notes.get() ?? '',
            enableSearching: widget.kdbxGroup!.enableSearching.get(),
            enableDisplay: widget.kdbxGroup!.enableDisplay.get(),
            kdbxIcon: KdbxIconWidgetData(
              icon: widget.kdbxGroup!.icon.get() ?? KdbxIcon.Folder,
              customIcon: widget.kdbxGroup!.customIcon,
            ),
            kdbxGroup: widget.kdbxGroup,
          )
        : KdbxGroupData(
            name: '',
            notes: '',
            kdbxIcon: KdbxIconWidgetData(icon: KdbxIcon.Folder),
          );
  }

  void _kdbxGroupSave() async {
    if (_from.currentState!.validate()) {
      _from.currentState!.save();

      final kdbx = KdbxProvider.of(context)!;

      final kdbxGroup =
          _kdbxGroupData.kdbxGroup ?? kdbx.createGroup(_kdbxGroupData.name);

      kdbxGroup.name.set(_kdbxGroupData.name);
      kdbxGroup.notes.set(_kdbxGroupData.notes);
      kdbxGroup.enableDisplay.set(_kdbxGroupData.enableDisplay);
      kdbxGroup.enableSearching.set(_kdbxGroupData.enableSearching);

      if (_kdbxGroupData.kdbxIcon.customIcon != null) {
        kdbxGroup.customIcon = _kdbxGroupData.kdbxIcon.customIcon;
      } else if (_kdbxGroupData.kdbxIcon.icon != kdbxGroup.icon.get()) {
        kdbxGroup.icon.set(_kdbxGroupData.kdbxIcon.icon);
      }

      if (await kdbxSave(KdbxProvider.of(context)!)) {
        context.router.pop(kdbxGroup.uuid);
      }
    }
  }

  @override
  void didUpdateWidget(covariant EditGroupPagePage oldWidget) {
    /// 触发整个 form 表进行重建
    if (widget.kdbxGroup != oldWidget.kdbxGroup) {
      _kdbxGroupData = _getKdbxGroupData();
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
                    kdbxIcon: _kdbxGroupData.kdbxIcon,
                    onSaved: (data) {
                      _kdbxGroupData.name = data!.$1;
                      _kdbxGroupData.kdbxIcon = _kdbxGroupData.kdbxIcon
                          .copyWith(icon: data.$2, customIcon: data.$3);
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
