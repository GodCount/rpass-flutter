import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:keepass_core/keepass_core.dart';
import 'package:lan_fill_server/lan_fill_server.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import '../../context/lan_fill_server.dart';
import '../../store/index.dart';
import '../../util/one_time_password.dart';
import '../../util/random_password.dart';
import '../../util/route.dart';
import '../../widget/form.dart';
import '../../widget/kdbx_icon.dart';
import '../route.dart';
import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../util/common.dart';
import '../../util/file.dart';
import '../../widget/chip_list.dart';
import '../../widget/common.dart';
import '../../widget/extension_state.dart';
import '../../widget/shake_widget.dart';

final _logger = Logger("page:edit_account");

class _EditAccountArgs extends PageRouteArgs {
  _EditAccountArgs({super.key});
}

class EditAccountRoute extends PageRouteInfo<_EditAccountArgs> {
  EditAccountRoute({Key? key, String? id, bool? clone})
    : super(
        name,
        args: _EditAccountArgs(key: key),
        rawPathParams: {"uuid": id, "clone": clone.toString()},
      );

  static const name = "EditAccountRoute";

  static final PageInfo page = PageInfo.builder(
    name,
    builder: (context, data) {
      final args = data.argsAs<_EditAccountArgs>(
        orElse: () => _EditAccountArgs(),
      );

      final uuid = data.inheritedPathParams.optString("uuid");
      final clone = data.inheritedPathParams.optBool("clone");

      return EditAccountPage(key: args.key, id: uuid, clone: clone ?? false);
    },
  );
}

class EditAccountPage extends StatefulWidget {
  const EditAccountPage({super.key, this.id, this.clone = false});

  final String? id;
  final bool clone;

  @override
  State<EditAccountPage> createState() => _EditAccountPageState();
}

class _EditAccountPageState extends State<EditAccountPage>
    with SecondLevelPageAutoBack<EditAccountPage> {
  GlobalKey<FormState> _from = GlobalKey();

  late EntryData _kdbxEntry = EntryData(parent: "empty");

  late GroupData _groupData = Store.kdbx.rootGroup();

  Set<String> _entryFields = {};
  Set<String> _urlsFields = {};
  Set<String> _deleteFields = {};

  bool _isDirty = false;

  @override
  void initState() {
    _getKdbxEntry();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant EditAccountPage oldWidget) {
    /// 触发整个 form 表进行重建
    if (widget.id != oldWidget.id) {
      _getKdbxEntry();
    }
    super.didUpdateWidget(oldWidget);
  }

  Future<void> _getKdbxEntry() async {
    try {
      final kdbxController = Store.kdbx;

      _kdbxEntry =
          widget.id != null
                ? await kdbxController.kdbx!.getEntry(id: widget.id!)
                : kdbxController.kdbx!.newEntry()
            ..fields[KdbxKeyCommon.PASSWORD] = FieldValue.protected(
              randomPassword(length: 10),
            );

      if (widget.id != null && widget.clone) {
        _kdbxEntry = _kdbxEntry.clone();
      }

      _groupData =
          kdbxController.getGroup(_kdbxEntry.parent) ??
          kdbxController.rootGroup();

      _entryFields = _kdbxEntry.customEntries.map((item) => item.key).toSet();
      _urlsFields = _kdbxEntry.moreUrlsKeys.toSet();
      _deleteFields = {};
      _from = GlobalKey();

      setState(() {});
    } on KdbxError_NotFound {
      context.router.pop();
    } catch (e, s) {
      showError(e, s);
    }
  }

  void _kdbxEntrySave() async {
    if (_from.currentState!.validate()) {
      _from.currentState!.save();
      _kdbxDeleteSaved();

      if (await kdbxAction(KdbxAction.updateEntry(_kdbxEntry))) {
        if (isDesktop) {
          context.router.platformNavigate(LookAccountRoute(id: _kdbxEntry.id));
        } else {
          context.router.pop(_kdbxEntry.id);
        }
      }
    }
  }

  void _kdbxDeleteSaved() {
    for (final item in _deleteFields) {
      _kdbxEntry.fields.remove(item);
    }
  }

  void _kdbxEntryGroupSaved(GroupData? group) {
    if (group != null && _kdbxEntry.parent != group.id) {
      _kdbxEntry.parent = group.id;
    }
  }

  void _entryFieldSaved(EntryFieldSaved field) {
    debugPrint("_entryFieldSaved===>  ${field.key} == ${field.runtimeType}");
    if (field is EntryBinaryFieldSaved) {
      _kdbxEntry.attachments
        ..clear()
        ..addAll(field.value);
    } else if (field is EntryAutoTypeFieldSaved) {
      _kdbxEntry.autotype ??= AutoType(
        enabled: true,
        associations: [],
        defaultSequence: field.value,
        dataTransferObfuscation: DataTransferObfuscation.none,
      );
      _kdbxEntry.autotype!.defaultSequence = field.value;
    } else if (field is EntryAutoFillAppFieldSaved) {
      if (field.value != null) {
        _kdbxEntry.fields[field.key] = FieldValue.plaintext(field.value!);
      } else {
        _kdbxEntry.fields.remove(field.key);
      }
    } else if (field is EntryTagsFieldSaved) {
      _kdbxEntry.tags
        ..clear()
        ..addAll(field.value);
    } else if (field is EntryTextFieldSaved) {
      final oldValue = _kdbxEntry.fields[field.key];

      if (field.renameKdbxKey != null) {
        _kdbxEntry.fields.remove(field.key);
      }

      final value = field.value ?? oldValue;

      if (value != null) {
        _kdbxEntry.fields[field.renameKdbxKey ?? field.key] = value;
      }
    } else if (field is EntryTitleFieldSaved) {
      _kdbxEntry.icon = field.icon;
      _kdbxEntry.fields[field.key] = field.value;
    } else if (field is EntryExpiresFieldSaved) {
      _kdbxEntry.times.expires = field.value.$1;
      _kdbxEntry.times.expiry = field.value.$2.toUtc();
    } else {
      _logger.warning("untreated class $field");
    }
  }

  void _entryUrlDelete(String key) {
    setState(() {
      _urlsFields.remove(key);
      if (_kdbxEntry.fields.keys.any((item) => item == key)) {
        _isDirty = true;
        _deleteFields.add(key);
      }
    });
  }

  void _addEntryUrl() async {
    final urls = KdbxKeyURLS.all.where((item) => !_urlsFields.contains(item));
    if (urls.isNotEmpty) {
      setState(() {
        final url = urls.first;
        final tmp = [url, ..._urlsFields];
        _urlsFields.addAll(KdbxKeyURLS.all.where((item) => tmp.contains(item)));
        _deleteFields.remove(url);
      });
    }
  }

  void _entryFieldDelete(String key) {
    setState(() {
      _entryFields.remove(key);
      if (_kdbxEntry.fields.keys.any((item) => item == key)) {
        _isDirty = true;
        _deleteFields.add(key);
      }
    });
  }

  void _addEntryField() async {
    final t = I18n.of(context)!;
    final kdbxProvider = Store.kdbx;

    final limitItmes = [
      ...defaultKdbxKeys,
      ..._entryFields,
    ].map((item) => item).toList();

    final result = await InputDialog.openDialog(
      context,
      title: t.add,
      label: t.new_field,
      promptItmes: kdbxProvider.fieldSummary!.customFields
          .where((item) => !limitItmes.contains(item))
          .toList(),
      limitItems: limitItmes,
    );
    if (result != null && result is String) {
      setState(() {
        _entryFields.add(result);
        _deleteFields.remove(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    final child = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: Column(
        children: [
          // 项目信息
          _cardColumn([
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            SelectGroupFormField(
              label: t.group,
              initialValue: _groupData,
              onSaved: _kdbxEntryGroupSaved,
            ),
            EntryField(
              kdbxKey: KdbxKeyCommon.TITLE,
              kdbxEntry: _kdbxEntry,
              onSaved: _entryFieldSaved,
            ),
          ]),
          // 账号信息
          _cardColumn([
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.account_box_rounded),
                  ),
                  Text(
                    t.account_info,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            EntryField(
              kdbxKey: KdbxKeyCommon.USER_NAME,
              kdbxEntry: _kdbxEntry,
              onSaved: _entryFieldSaved,
            ),
            EntryField(
              kdbxKey: KdbxKeyCommon.EMAIL,
              kdbxEntry: _kdbxEntry,
              onSaved: _entryFieldSaved,
            ),
            EntryField(
              kdbxKey: KdbxKeyCommon.PASSWORD,
              kdbxEntry: _kdbxEntry,
              onSaved: _entryFieldSaved,
            ),
            EntryField(
              kdbxKey: KdbxKeyCommon.OTP,
              kdbxEntry: _kdbxEntry,
              onSaved: _entryFieldSaved,
            ),
          ]),
          // 自动填充信息
          _cardColumn([
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.ads_click),
                  ),
                  Text(
                    t.auto_fill_info,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            if (isDesktop)
              EntryField(
                kdbxKey: KdbxKeySpecial.AUTO_TYPE,
                kdbxEntry: _kdbxEntry,
                onSaved: _entryFieldSaved,
              ),
            if (isMobile)
              EntryField(
                kdbxKey: KdbxKeySpecial.AUTO_FILL_PACKAGE_NAME,
                kdbxEntry: _kdbxEntry,
                onSaved: _entryFieldSaved,
              ),
            EntryField(
              kdbxKey: KdbxKeyCommon.URL,
              kdbxEntry: _kdbxEntry,
              onSaved: _entryFieldSaved,
            ),
            ..._urlsFields.map(
              (item) => EntryField(
                key: ValueKey(item),
                kdbxKey: item,
                kdbxEntry: _kdbxEntry,
                onDeleted: _entryUrlDelete,
                onSaved: _entryFieldSaved,
              ),
            ),
            if (_urlsFields.length < KdbxKeyURLS.all.length)
              _buildAddFieldWidget(
                label: t.add_domain,
                onPressed: _addEntryUrl,
              ),
          ]),
          // 自定义字段
          _cardColumn([
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.description_rounded),
                  ),
                  Text(
                    t.custom_field,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            ..._entryFields.map(
              (item) => EntryField(
                key: ValueKey(item),
                kdbxKey: item,
                kdbxEntry: _kdbxEntry,
                onDeleted: _entryFieldDelete,
                onSaved: _entryFieldSaved,
              ),
            ),
            _buildAddFieldWidget(label: t.add_field, onPressed: _addEntryField),
          ]),
          // 附加信息
          _cardColumn([
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            EntryField(
              kdbxKey: KdbxKeyCommon.NOTES,
              kdbxEntry: _kdbxEntry,
              onSaved: _entryFieldSaved,
            ),
            EntryField(
              kdbxKey: KdbxKeySpecial.TAGS,
              kdbxEntry: _kdbxEntry,
              onSaved: _entryFieldSaved,
            ),
            EntryField(
              kdbxKey: KdbxKeySpecial.ATTACH,
              kdbxEntry: _kdbxEntry,
              onSaved: _entryFieldSaved,
            ),
            EntryField(
              kdbxKey: KdbxKeySpecial.EXPIRES,
              kdbxEntry: _kdbxEntry,
              onSaved: _entryFieldSaved,
            ),
          ]),
          const SizedBox(height: 42),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: automaticallyImplyLeading,
        leading: autoBack(),
        title: Text(t.edit_account),
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
        child: isMobile ? SlidableAutoCloseBehavior(child: child) : child,
      ),
      floatingActionButton: _isDirty
          ? FloatingActionButton(
              heroTag: const ValueKey("edit_account_float"),
              onPressed: _kdbxEntrySave,
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

  Widget _buildAddFieldWidget({
    required VoidCallback? onPressed,
    required String label,
  }) {
    return Column(
      children: [
        TextButton.icon(
          onPressed: onPressed,
          label: Text(label),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

abstract class EntryFieldSaved<T> {
  EntryFieldSaved({required this.key, required this.value});

  final String key;
  final T value;
}

class EntryTitleFieldSaved extends EntryFieldSaved<FieldValue> {
  EntryTitleFieldSaved({
    required super.key,
    required super.value,
    required this.icon,
  });

  final KdbxIcon icon;
}

class EntryTextFieldSaved extends EntryFieldSaved<FieldValue?> {
  EntryTextFieldSaved({
    required super.key,
    required super.value,
    this.renameKdbxKey,
  });
  final String? renameKdbxKey;
}

class EntryAutoTypeFieldSaved extends EntryFieldSaved<String> {
  EntryAutoTypeFieldSaved({required super.key, required super.value});
}

class EntryAutoFillAppFieldSaved extends EntryFieldSaved<String?> {
  EntryAutoFillAppFieldSaved({required super.key, required super.value});
}

class EntryTagsFieldSaved extends EntryFieldSaved<List<String>> {
  EntryTagsFieldSaved({required super.key, required super.value});
}

class EntryBinaryFieldSaved extends EntryFieldSaved<List<Attachment>> {
  EntryBinaryFieldSaved({required super.key, required super.value});
}

class EntryExpiresFieldSaved extends EntryFieldSaved<(bool, DateTime)> {
  EntryExpiresFieldSaved({required super.key, required super.value});
}

typedef OnEntryFidleDeleted = void Function(String key);
typedef OnEntryFieldSaved = void Function(EntryFieldSaved field);

class EntryField extends StatefulWidget {
  const EntryField({
    super.key,
    required this.kdbxKey,
    required this.kdbxEntry,
    this.onDeleted,
    required this.onSaved,
  });

  final String kdbxKey;
  final EntryData kdbxEntry;
  final OnEntryFidleDeleted? onDeleted;
  final OnEntryFieldSaved onSaved;

  @override
  State<EntryField> createState() => _EntryFieldState();
}

class _EntryFieldState extends State<EntryField> {
  String? _renameKdbxKey;

  List<String> _binaryKeys = [];

  String? _value;
  AuthOneTimePassword? _otp;

  late final List<DropdownMenuEntry<String>> _dropdownMenuEntries = Store
      .kdbx
      .fieldSummary!
      .getStatistic(widget.kdbxKey)
      .map(
        (value) => DropdownMenuEntry(
          value: value,
          label: value,
          labelWidget: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      )
      .toList();

  @override
  void initState() {
    _value = widget.kdbxEntry.fields[widget.kdbxKey]?.get();
    parseOtp(_value);
    super.initState();
  }

  void parseOtp(String? value) {
    if (widget.kdbxKey == KdbxKeyCommon.OTP) {
      _otp = value != null && value.isNotEmpty
          ? AuthOneTimePassword.tryParse(value)
          : null;
    }
  }

  void _onRenameKdbxKey() async {
    final t = I18n.of(context)!;
    final kdbxController = Store.kdbx;
    final limitItmes = {
      ...defaultKdbxKeys,
      ...widget.kdbxEntry.fields.keys,
    }.toList();

    limitItmes.remove(widget.kdbxKey);

    if (_renameKdbxKey != null) {
      limitItmes.remove(_renameKdbxKey!);
    }

    final result = await InputDialog.openDialog(
      context,
      title: t.rename,
      label: t.new_field,
      initialValue: _renameKdbxKey ?? widget.kdbxKey,
      promptItmes: kdbxController.fieldSummary!.customFields
          .where((item) => !limitItmes.contains(item))
          .toList(),
      limitItems: limitItmes,
    );
    if (result != null && result is String) {
      setState(() {
        _renameKdbxKey = result;
      });
    }
  }

  void _onChanged(String? text) {
    if (_value != text) {
      _value = text;
      parseOtp(_value);
      setState(() {});
    }
  }

  void onPressedLanFill() {
    String? value = _otp != null ? _otp!.code().toString() : _value;

    if (value != null && value.isNotEmpty) {
      final lanFill = LanFillInherited.of(context)!;

      lanFill.requestRemoteAutofill(
        AutofillDto(key: "field", fields: {"field": value}),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _buildFormFieldFactory(),
    );

    if (!isMobile) return child;

    final t = I18n.of(context)!;
    final lanFill = LanFillInherited.of(context);

    final isDefaultKey = KdbxKeyCommon.all.contains(widget.kdbxKey);
    final isCustomKey = widget.kdbxEntry.isCustomKey(widget.kdbxKey);
    final isUrl = KdbxKeyURLS.all.contains(widget.kdbxKey);

    final enabled = isDefaultKey || isCustomKey || isUrl;

    return Slidable(
      groupTag: "0",
      enabled: enabled,
      startActionPane: enabled && lanFill != null
          ? ActionPane(
              motion: const ScrollMotion(),
              children: [
                const SizedBox(width: 16),
                if (_otp != null) OtpDownCount(authOneTimePassword: _otp!),
                SlidableAction(
                  icon: lanFill.serverClosed
                      ? Icons.cast_connected
                      : Icons.connect_without_contact_rounded,
                  label: t.lan_fill,
                  borderRadius: BorderRadius.circular(99),
                  backgroundColor: Colors.transparent,
                  foregroundColor: Theme.of(context).colorScheme.secondary,
                  onPressed: (context) => onPressedLanFill(),
                ),
              ],
            )
          : null,
      endActionPane: isCustomKey || isUrl
          ? ActionPane(
              motion: const ScrollMotion(),
              children: [
                if (!isUrl)
                  SlidableAction(
                    icon: Icons.drive_file_rename_outline,
                    borderRadius: BorderRadius.circular(99),
                    backgroundColor: Colors.transparent,
                    foregroundColor: Theme.of(context).colorScheme.secondary,
                    onPressed: (context) => _onRenameKdbxKey(),
                  ),
                if (widget.onDeleted != null)
                  SlidableAction(
                    icon: Icons.delete_rounded,
                    borderRadius: BorderRadius.circular(99),
                    backgroundColor: Colors.transparent,
                    foregroundColor: Theme.of(context).colorScheme.error,
                    onPressed: (context) => widget.onDeleted!(widget.kdbxKey),
                  ),
                const SizedBox(width: 16),
              ],
            )
          : null,
      child: child,
    );
  }

  FormFieldValidator<String?>? _entryFieldValidator() {
    final t = I18n.of(context)!;

    switch (widget.kdbxKey) {
      case KdbxKeyCommon.URL:
      case KdbxKeyURLS.URL1:
      case KdbxKeyURLS.URL2:
      case KdbxKeyURLS.URL3:
      case KdbxKeyURLS.URL4:
      case KdbxKeyURLS.URL5:
        return (value) =>
            value != null &&
                value.isNotEmpty &&
                !CommonRegExp.domain.hasMatch(value)
            ? t.format_error(CommonRegExp.domain.pattern)
            : null;
      case KdbxKeyCommon.EMAIL:
        return (value) =>
            value != null &&
                value.isNotEmpty &&
                !CommonRegExp.email.hasMatch(value)
            ? t.format_error(CommonRegExp.email.pattern)
            : null;
      case KdbxKeyCommon.OTP:
        return (value) =>
            value != null &&
                value.isNotEmpty &&
                AuthOneTimePassword.tryParse(value) == null
            ? t.format_error(t.otp_format_error)
            : null;
      default:
        return null;
    }
  }

  void _kdbxTextFieldSaved(String? value) {
    widget.onSaved(
      EntryTextFieldSaved(
        key: widget.kdbxKey,
        renameKdbxKey: _renameKdbxKey,
        value: value != null ? FieldValue.plaintext(value) : null,
      ),
    );
  }

  String _uniqueBinaryName(String filepath) {
    final fileName = path.basename(filepath);
    final lastIndex = fileName.lastIndexOf('.');
    final baseName = lastIndex > -1
        ? fileName.substring(0, lastIndex)
        : fileName;
    final ext = lastIndex > -1 ? fileName.substring(lastIndex + 1) : 'ext';
    for (var i = 0; i < 1000; i++) {
      final k = i == 0 ? fileName : '$baseName$i.$ext';
      if (!_binaryKeys.contains(k)) {
        return k;
      }
    }
    throw StateError('Unable to find unique name for $fileName');
  }

  Widget _contextMenuBuilder(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    final isUrl = KdbxKeyURLS.all.contains(widget.kdbxKey);
    if (kIsDesktop && (widget.kdbxEntry.isCustomKey(widget.kdbxKey) || isUrl)) {
      final t = I18n.of(context)!;

      return AdaptiveTextSelectionToolbar.buttonItems(
        buttonItems: [
          ...editableTextState.contextMenuButtonItems,
          if (!isUrl)
            ContextMenuButtonItem(
              label: t.rename_field,
              onPressed: _onRenameKdbxKey,
            ),
          if (widget.onDeleted != null)
            ContextMenuButtonItem(
              label: t.delete_field,
              onPressed: () => widget.onDeleted?.call(widget.kdbxKey),
            ),
        ],
        anchors: editableTextState.contextMenuAnchors,
      );
    }

    return AdaptiveTextSelectionToolbar.editableText(
      editableTextState: editableTextState,
    );
  }

  Widget _buildFormFieldFactory() {
    final kdbxProvider = Store.kdbx;

    final initialValue = widget.kdbxEntry.fields[widget.kdbxKey]?.get();

    switch (widget.kdbxKey) {
      case KdbxKeyCommon.TITLE:
        return EntryTitleFormField(
          initialValue: initialValue,
          label: widget.kdbxKey.fromKdbxKeyToI18n(context),
          kdbxIcon: KdbxIconWidgetData(
            icon: widget.kdbxEntry.icon ?? KdbxIconType.Key.toKdbxIcon(),
          ),
          onSaved: (data) {
            widget.onSaved(
              EntryTitleFieldSaved(
                key: widget.kdbxKey,
                value: FieldValue.plaintext(data!.$1),
                icon: data.$2,
              ),
            );
          },
          onChanged: _onChanged,
        );
      case KdbxKeyCommon.URL:
      case KdbxKeyCommon.USER_NAME:
      case KdbxKeyCommon.EMAIL:
        return ShakeFormField<String>(
          validator: _entryFieldValidator(),
          builder: (context, validator) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return DropdownMenuFormField2(
                  width: constraints.biggest.width,
                  initialValue: initialValue,
                  dropdownMenuEntries: _dropdownMenuEntries,
                  label: widget.kdbxKey.fromKdbxKeyToI18n(context),
                  onSaved: _kdbxTextFieldSaved,
                  onSelected: _onChanged,
                  expandedInsets: const EdgeInsets.all(0),
                  validator: validator,
                  menuHeight: 150,
                  enableFilter: true,
                  requestFocusOnTap: true,
                );
              },
            );
          },
        );
      case KdbxKeyCommon.PASSWORD:
        return EntryTextFormField(
          initialValue: initialValue,
          label: widget.kdbxKey.fromKdbxKeyToI18n(context),
          trailingIcon: const Icon(Icons.create),
          onTrailingTap: () async {
            final password = await context.router.push(
              GenPasswordRoute(popPassword: true),
            );
            if (password != null && password is String) {
              return password;
            }
            return null;
          },
          onSaved: _kdbxTextFieldSaved,
          onChanged: _onChanged,
        );
      case KdbxKeyCommon.OTP:
        return EntryTextFormField(
          initialValue: initialValue,
          label: widget.kdbxKey.fromKdbxKeyToI18n(context),
          trailingIcon: isMobile ? const Icon(Icons.qr_code_scanner) : null,
          onTrailingTap: isMobile
              ? () async {
                  final optUrl = await context.router.push(
                    QrCodeScannerRoute(),
                  );
                  if (optUrl != null && optUrl is String) {
                    return optUrl;
                  }
                  return null;
                }
              : null,
          onSaved: _kdbxTextFieldSaved,
          onChanged: _onChanged,
          validator: _entryFieldValidator(),
        );
      case KdbxKeyCommon.NOTES:
        return EntryNotesFormField(
          initialValue: initialValue,
          label: widget.kdbxKey.fromKdbxKeyToI18n(context),
          onSaved: _kdbxTextFieldSaved,
          onChanged: _onChanged,
        );
      case KdbxKeySpecial.AUTO_TYPE:
        return EntryAutoTypeFormField(
          label: widget.kdbxKey.fromKdbxKeyToI18n(context),
          customFields: widget.kdbxEntry.customEntries
              .map((item) => item.key)
              .toList(),
          moreUrlsFields: widget.kdbxEntry.moreUrlsKeys,
          autoTypeSequence:
              widget.kdbxEntry.autotype?.defaultSequence ??
              kdbxProvider.getAutoTypeSequence(widget.kdbxEntry.id),
          onSaved: (value) {
            widget.onSaved(
              EntryAutoTypeFieldSaved(key: widget.kdbxKey, value: value!),
            );
          },
        );
      case KdbxKeySpecial.AUTO_FILL_PACKAGE_NAME:
        return EntryAutoFillAppFormField(
          label: widget.kdbxKey.fromKdbxKeyToI18n(context),
          initialValue: initialValue,
          onSaved: (value) {
            widget.onSaved(
              EntryAutoFillAppFieldSaved(key: widget.kdbxKey, value: value),
            );
          },
        );
      case KdbxKeySpecial.TAGS:
        return ChipListFormField(
          label: widget.kdbxKey.fromKdbxKeyToI18n(context),
          initialValue: [
            for (final item in kdbxProvider.fieldSummary!.getStatistic(
              widget.kdbxKey,
            ))
              ChipListItem(
                value: item,
                label: Text(item),
                select: widget.kdbxEntry.tags.contains(item),
                deletable: false,
              ),
          ],
          onChipTap: (item) {
            item.select = !item.select;
            return true;
          },
          onAddChipTap: _addTag,
          onSaved: (list) {
            widget.onSaved(
              EntryTagsFieldSaved(
                key: widget.kdbxKey,
                value: list!
                    .where((item) => item.select)
                    .map((item) => item.value)
                    .toList(),
              ),
            );
          },
        );
      case KdbxKeySpecial.ATTACH:
        return ChipListFormField(
          label: widget.kdbxKey.fromKdbxKeyToI18n(context),
          initialValue: [
            for (final item in widget.kdbxEntry.attachments)
              ChipListItem(
                value: item,
                label: RichText(
                  text: TextSpan(
                    text: item.name,
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: " (${item.size.toStorageUnit(.KB)})",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
          ],
          onChanged: (list) {
            _binaryKeys = list.map((item) => item.value.name).toList();
          },
          onChipTap: (item) {
            showBinaryAction(item);
            return false;
          },
          onAddChipTap: (list) async {
            try {
              final t = I18n.of(context)!;
              final (filepath, bytes) = await SimpleFile.openFile();

              if (transformStorageUnit(bytes.length, .B, .KB) >= 1024 &&
                  !(await showConfirmDialog(
                    title: t.warn,
                    message: t.add_large_files_warn,
                  ))) {
                return null;
              }

              final attach = Attachment(
                id: -1,
                name: _uniqueBinaryName(filepath),
                data: bytes,
                size: bytes.length,
              );

              return ChipListItem(
                value: attach,
                label: RichText(
                  text: TextSpan(
                    text: attach.name,
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: " (${attach.size.toStorageUnit(.KB)})",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              );
            } catch (e, s) {
              if (e is! CancelException) {
                _logger.warning("open file fail!", e, s);
                showError(e, s);
              }
            }
            return null;
          },
          onSaved: (list) {
            widget.onSaved(
              EntryBinaryFieldSaved(
                key: widget.kdbxKey,
                value: list!.map((item) => item.value).toList(),
              ),
            );
          },
        );
      case KdbxKeySpecial.EXPIRES:
        return EntryExpiresFormField(
          label: widget.kdbxKey.fromKdbxKeyToI18n(context),
          initialValue: (
            widget.kdbxEntry.times.expires ?? false,
            widget.kdbxEntry.times.expiry?.toLocal() ?? DateTime.now(),
          ),
          onSaved: (value) {
            widget.onSaved(
              EntryExpiresFieldSaved(key: widget.kdbxKey, value: value!),
            );
          },
        );
      case KdbxKeyURLS.URL1:
      case KdbxKeyURLS.URL2:
      case KdbxKeyURLS.URL3:
      case KdbxKeyURLS.URL4:
      case KdbxKeyURLS.URL5:
        return ShakeFormField<String>(
          validator: _entryFieldValidator(),
          builder: (context, validator) {
            return EntryTextFormField(
              initialValue: initialValue,
              label: widget.kdbxKey.fromKdbxKeyToI18n(context),
              validator: validator,
              onSaved: _kdbxTextFieldSaved,
              onChanged: _onChanged,
              contextMenuBuilder: _contextMenuBuilder,
            );
          },
        );
      default:
        return EntryTextFormField(
          initialValue: initialValue,
          label: (_renameKdbxKey ?? widget.kdbxKey).fromKdbxKeyToI18n(context),
          onSaved: _kdbxTextFieldSaved,
          onChanged: _onChanged,
          contextMenuBuilder: _contextMenuBuilder,
        );
    }
  }

  Future<ChipListItem<String>?> _addTag(List<ChipListItem<String>> list) async {
    final t = I18n.of(context)!;
    final kdbxProvider = Store.kdbx;

    final result = await InputDialog.openDialog(
      context,
      title: t.label,
      label: t.new_label,
      limitItems: [
        ...kdbxProvider.fieldSummary!.getStatistic(KdbxKeySpecial.TAGS),
        ...list.map((item) => item.value),
      ],
    );

    if (result != null && result is String) {
      return ChipListItem(value: result, label: Text(result), select: true);
    }

    return null;
  }
}
