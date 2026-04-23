import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lan_fill_server/lan_fill_server.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import '../../context/lan_fill_server.dart';
import '../../util/one_time_password.dart';
import '../../util/random_password.dart';
import '../../util/route.dart';
import '../../widget/form.dart';
import '../../widget/kdbx_icon.dart';
import '../route.dart';
import '../../context/kdbx.dart';
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
  _EditAccountArgs({super.key, this.kdbxEntry, this.initKdbxGroup});

  final KdbxEntry? kdbxEntry;
  final KdbxGroup? initKdbxGroup;
}

class EditAccountRoute extends PageRouteInfo<_EditAccountArgs> {
  EditAccountRoute({
    Key? key,
    KdbxEntry? kdbxEntry,
    KdbxGroup? initKdbxGroup,
    KdbxUuid? uuid,
  }) : super(
         name,
         args: _EditAccountArgs(
           key: key,
           kdbxEntry: kdbxEntry,
           initKdbxGroup: initKdbxGroup,
         ),
         rawPathParams: {"uuid": uuid?.deBase64Uuid},
       );

  static const name = "EditAccountRoute";

  static final PageInfo page = PageInfo.builder(
    name,
    builder: (context, data) {
      final args = data.argsAs<_EditAccountArgs>(
        orElse: () {
          final kdbx = KdbxProvider.of(context).kdbx!;
          final uuid = data.inheritedPathParams.optString("uuid")?.kdbxUuid;
          final kdbxEntry = uuid != null ? kdbx.findEntryByUuid(uuid) : null;

          return _EditAccountArgs(kdbxEntry: kdbxEntry);
        },
      );
      return EditAccountPage(
        key: args.key,
        kdbxEntry: args.kdbxEntry,
        initKdbxGroup: args.initKdbxGroup,
      );
    },
  );
}

class EditAccountPage extends StatefulWidget {
  const EditAccountPage({super.key, this.kdbxEntry, this.initKdbxGroup});

  final KdbxEntry? kdbxEntry;
  final KdbxGroup? initKdbxGroup;

  @override
  State<EditAccountPage> createState() => _EditAccountPageState();
}

class _EditAccountPageState extends State<EditAccountPage>
    with SecondLevelPageAutoBack<EditAccountPage> {
  GlobalKey<FormState> _from = GlobalKey();

  late KdbxEntry _kdbxEntry = widget.kdbxEntry ?? _createKdbxEntry();

  late Set<KdbxKey> _entryFields = _kdbxEntry.customEntries
      .map((item) => item.key)
      .toSet();

  late Set<KdbxKey> _urlsFields = _kdbxEntry.moreUrlsKeys.toSet();

  Set<KdbxKey> _deleteFields = {};

  bool _isDirty = false;

  @override
  void didUpdateWidget(covariant EditAccountPage oldWidget) {
    /// 触发整个 form 表进行重建
    if (widget.kdbxEntry != oldWidget.kdbxEntry) {
      _kdbxEntry = widget.kdbxEntry ?? _createKdbxEntry();
      _entryFields = _kdbxEntry.customEntries.map((item) => item.key).toSet();
      _urlsFields = _kdbxEntry.moreUrlsKeys.toSet();
      _deleteFields = {};
      _from = GlobalKey();
    }
    super.didUpdateWidget(oldWidget);
  }

  KdbxEntry _createKdbxEntry() {
    return KdbxProvider.of(context).kdbx!.createVirtualEntry()..setString(
      KdbxKeyCommon.PASSWORD,
      PlainValue(randomPassword(length: 10)),
    );
  }

  void _kdbxEntrySave() async {
    if (_from.currentState!.validate()) {
      _from.currentState!.save();
      _kdbxDeleteSaved();

      if (await kdbxSave(KdbxProvider.of(context).kdbx!)) {
        if (isDesktop) {
          context.router.platformNavigate(
            LookAccountRoute(kdbxEntry: _kdbxEntry, uuid: _kdbxEntry.uuid),
          );
        } else {
          context.router.pop(true);
        }
      }
    }
  }

  void _kdbxDeleteSaved() {
    for (final item in _deleteFields) {
      _kdbxEntry.setString(item, null);
    }
  }

  void _kdbxEntryGroupSaved(KdbxGroup? group) {
    final kdbx = KdbxProvider.of(context).kdbx!;
    if (group != null && _kdbxEntry.parent != group) {
      kdbx.kdbxFile.move(_kdbxEntry, group);
    }
  }

  void _entryFieldSaved(EntryFieldSaved field) {
    debugPrint("_entryFieldSaved===>  ${field.key} == ${field.runtimeType}");
    if (field is EntryBinaryFieldSaved) {
      final binarys = field.value;
      final oldBinaryKeys = _kdbxEntry.binaryEntries.map((item) => item.key);
      // 删除不包含
      for (var key in oldBinaryKeys) {
        if (!binarys.any((item) => item.key == key)) {
          _kdbxEntry.removeBinary(key);
        }
      }
      for (var binary in binarys) {
        if (_kdbxEntry.getBinary(binary.key) == null) {
          // TODO! isProtected 应该怎么设置
          _kdbxEntry.createBinary(
            isProtected: binary.value.isProtected,
            name: binary.key.key,
            bytes: binary.value.value,
          );
        }
      }
    } else if (field is EntryAutoTypeFieldSaved) {
      _kdbxEntry.setAutoTyprSequence(field.value);
    } else if (field is EntryAutoFillAppFieldSaved) {
      _kdbxEntry.setString(
        field.key,
        field.value != null ? PlainValue(field.value) : null,
      );
    } else if (field is EntryTagsFieldSaved) {
      _kdbxEntry.tagList = field.value;
    } else if (field is EntryTextFieldSaved) {
      final oldValue = _kdbxEntry.getString(field.key)?.getText() ?? "";
      final newValue = field.value?.getText() ?? "";

      if (newValue != oldValue) {
        if (field.renameKdbxKey != null) {
          _kdbxEntry.renameKey(field.key, field.renameKdbxKey!);
        }

        _kdbxEntry.setString(field.renameKdbxKey ?? field.key, field.value);
      }
    } else if (field is EntryTitleFieldSaved) {
      if (field.customIcon != null) {
        _kdbxEntry.customIcon = field.customIcon;
      } else {
        _kdbxEntry.icon.set(field.icon);
        _kdbxEntry.customIcon = null;
      }
      _kdbxEntry.setString(field.key, field.value);
    } else if (field is EntryExpiresFieldSaved) {
      _kdbxEntry.times.expires.set(field.value.$1);
      _kdbxEntry.times.expiryTime.set(field.value.$2.toUtc());
    } else {
      _logger.warning("untreated class $field");
    }
  }

  void _entryUrlDelete(KdbxKey key) {
    setState(() {
      _urlsFields.remove(key);
      if (_kdbxEntry.stringEntries.any((item) => item.key == key)) {
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

  void _entryFieldDelete(KdbxKey key) {
    setState(() {
      _entryFields.remove(key);
      if (_kdbxEntry.stringEntries.any((item) => item.key == key)) {
        _isDirty = true;
        _deleteFields.add(key);
      }
    });
  }

  void _addEntryField() async {
    final t = I18n.of(context)!;
    final kdbx = KdbxProvider.of(context).kdbx!;

    final limitItmes = [
      ...defaultKdbxKeys,
      ..._entryFields,
    ].map((item) => item.key).toList();

    final result = await InputDialog.openDialog(
      context,
      title: t.add,
      label: t.new_field,
      promptItmes: kdbx.fieldStatistic.customFields
          .where((item) => !limitItmes.contains(item))
          .toList(),
      limitItems: limitItmes,
    );
    if (result != null && result is String) {
      setState(() {
        _entryFields.add(KdbxKey(result));
        _deleteFields.remove(KdbxKey(result));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;
    final kdbx = KdbxProvider.of(context).kdbx!;

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
            KdbxEntryGroup(
              initialValue: _kdbxEntry.parent != kdbx.virtualGroup
                  ? _kdbxEntry.parent
                  : widget.initKdbxGroup ?? kdbx.kdbxFile.body.rootGroup,
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

  final KdbxKey key;
  final T value;
}

class EntryTitleFieldSaved extends EntryFieldSaved<StringValue> {
  EntryTitleFieldSaved({
    required super.key,
    required super.value,
    required this.icon,
    this.customIcon,
  });

  final KdbxIcon icon;
  final KdbxCustomIcon? customIcon;
}

class EntryTextFieldSaved extends EntryFieldSaved<StringValue?> {
  EntryTextFieldSaved({
    required super.key,
    required super.value,
    this.renameKdbxKey,
  });
  final KdbxKey? renameKdbxKey;
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

class EntryBinaryFieldSaved
    extends EntryFieldSaved<List<MapEntry<KdbxKey, KdbxBinary>>> {
  EntryBinaryFieldSaved({required super.key, required super.value});
}

class EntryExpiresFieldSaved extends EntryFieldSaved<(bool, DateTime)> {
  EntryExpiresFieldSaved({required super.key, required super.value});
}

typedef OnEntryFidleDeleted = void Function(KdbxKey key);
typedef OnEntryFieldSaved = void Function(EntryFieldSaved field);

class KdbxEntryGroup extends FormField<KdbxGroup> {
  KdbxEntryGroup({super.key, super.initialValue, super.onSaved})
    : super(
        builder: (field) {
          return Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: GestureDetector(
              onTap: () async {
                final result = await field.showGroupSelectorDialog(field.value);

                if (result != null) {
                  field.didChange(result);
                }
              },
              child: InputDecorator(
                isEmpty: field.value == null,
                decoration: InputDecoration(
                  labelText: I18n.of(field.context)!.group,
                  border: const OutlineInputBorder(),
                ),
                child: field.value != null
                    ? Text(field.value!.name.get() ?? '')
                    : null,
              ),
            ),
          );
        },
      );
}

class EntryField extends StatefulWidget {
  const EntryField({
    super.key,
    required this.kdbxKey,
    required this.kdbxEntry,
    this.onDeleted,
    required this.onSaved,
  });

  final KdbxKey kdbxKey;
  final KdbxEntry kdbxEntry;
  final OnEntryFidleDeleted? onDeleted;
  final OnEntryFieldSaved onSaved;

  @override
  State<EntryField> createState() => _EntryFieldState();
}

class _EntryFieldState extends State<EntryField> {
  KdbxKey? _renameKdbxKey;

  List<KdbxKey> _binaryKeys = [];

  String? _value;
  AuthOneTimePassword? _otp;

  late final List<DropdownMenuEntry<String>> _dropdownMenuEntries =
      KdbxProvider.of(context).kdbx!.fieldStatistic
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
    _value = widget.kdbxEntry.getString(widget.kdbxKey)?.getText();
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
    final kdbx = KdbxProvider.of(context).kdbx!;
    final limitItmes = {
      ...defaultKdbxKeys,
      ...widget.kdbxEntry.stringEntries.map((item) => item.key),
    }.map((item) => item.key).toList();

    limitItmes.remove(widget.kdbxKey.key);

    if (_renameKdbxKey != null) {
      limitItmes.remove(_renameKdbxKey!.key);
    }

    final result = await InputDialog.openDialog(
      context,
      title: t.rename,
      label: t.new_field,
      initialValue: _renameKdbxKey?.key ?? widget.kdbxKey.key,
      promptItmes: kdbx.fieldStatistic.customFields
          .where((item) => !limitItmes.contains(item))
          .toList(),
      limitItems: limitItmes,
    );
    if (result != null && result is String) {
      setState(() {
        _renameKdbxKey = KdbxKey(result);
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

    switch (widget.kdbxKey.key) {
      case KdbxKeyCommon.KEY_URL:
      case KdbxKeyURLS.KEY_URL1:
      case KdbxKeyURLS.KEY_URL2:
      case KdbxKeyURLS.KEY_URL3:
      case KdbxKeyURLS.KEY_URL4:
      case KdbxKeyURLS.KEY_URL5:
        return (value) =>
            value != null &&
                value.isNotEmpty &&
                !CommonRegExp.domain.hasMatch(value)
            ? t.format_error(CommonRegExp.domain.pattern)
            : null;
      case KdbxKeyCommon.KEY_EMAIL:
        return (value) =>
            value != null &&
                value.isNotEmpty &&
                !CommonRegExp.email.hasMatch(value)
            ? t.format_error(CommonRegExp.email.pattern)
            : null;
      case KdbxKeyCommon.KEY_OTP:
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
        value: value != null ? PlainValue(value) : null,
      ),
    );
  }

  KdbxKey _uniqueBinaryName(String filepath) {
    final fileName = path.basename(filepath);
    final lastIndex = fileName.lastIndexOf('.');
    final baseName = lastIndex > -1
        ? fileName.substring(0, lastIndex)
        : fileName;
    final ext = lastIndex > -1 ? fileName.substring(lastIndex + 1) : 'ext';
    for (var i = 0; i < 1000; i++) {
      final k = i == 0 ? KdbxKey(fileName) : KdbxKey('$baseName$i.$ext');
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
    if (widget.kdbxEntry.isCustomKey(widget.kdbxKey) || isUrl) {
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
    final kdbx = KdbxProvider.of(context).kdbx!;

    final initialValue = widget.kdbxEntry.getString(widget.kdbxKey)?.getText();

    switch (widget.kdbxKey.key) {
      case KdbxKeyCommon.KEY_TITLE:
        return EntryTitleFormField(
          initialValue: initialValue,
          label: widget.kdbxKey.key.fromKdbxKeyToI18n(context),
          kdbxIcon: KdbxIconWidgetData(
            icon: widget.kdbxEntry.icon.get() ?? KdbxIcon.Key,
            customIcon: widget.kdbxEntry.customIcon,
          ),
          onSaved: (data) {
            widget.onSaved(
              EntryTitleFieldSaved(
                key: widget.kdbxKey,
                value: PlainValue(data!.$1),
                icon: data.$2,
                customIcon: data.$3,
              ),
            );
          },
          onChanged: _onChanged,
        );
      case KdbxKeyCommon.KEY_URL:
      case KdbxKeyCommon.KEY_USER_NAME:
      case KdbxKeyCommon.KEY_EMAIL:
        return ShakeFormField<String>(
          validator: _entryFieldValidator(),
          builder: (context, validator) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return DropdownMenuFormField2(
                  width: constraints.biggest.width,
                  initialValue: initialValue,
                  dropdownMenuEntries: _dropdownMenuEntries,
                  label: widget.kdbxKey.key.fromKdbxKeyToI18n(context),
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
      case KdbxKeyCommon.KEY_PASSWORD:
        return EntryTextFormField(
          initialValue: initialValue,
          label: widget.kdbxKey.key.fromKdbxKeyToI18n(context),
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
      case KdbxKeyCommon.KEY_OTP:
        return EntryTextFormField(
          initialValue: initialValue,
          label: widget.kdbxKey.key.fromKdbxKeyToI18n(context),
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
      case KdbxKeyCommon.KEY_NOTES:
        return EntryNotesFormField(
          initialValue: initialValue,
          label: widget.kdbxKey.key.fromKdbxKeyToI18n(context),
          onSaved: _kdbxTextFieldSaved,
          onChanged: _onChanged,
        );
      case KdbxKeySpecial.KEY_AUTO_TYPE:
        return EntryAutoTypeFormField(
          label: widget.kdbxKey.key.fromKdbxKeyToI18n(context),
          kdbxEntry: widget.kdbxEntry,
          onSaved: (value) {
            widget.onSaved(
              EntryAutoTypeFieldSaved(key: widget.kdbxKey, value: value!),
            );
          },
        );
      case KdbxKeySpecial.KEY_AUTO_FILL_PACKAGE_NAME:
        return EntryAutoFillAppFormField(
          label: widget.kdbxKey.key.fromKdbxKeyToI18n(context),
          initialValue: initialValue,
          onSaved: (value) {
            widget.onSaved(
              EntryAutoFillAppFieldSaved(key: widget.kdbxKey, value: value),
            );
          },
        );
      case KdbxKeySpecial.KEY_TAGS:
        final tags = widget.kdbxEntry.tagList;
        return ChipListFormField(
          label: widget.kdbxKey.key.fromKdbxKeyToI18n(context),
          initialValue: kdbx.fieldStatistic
              .getStatistic(widget.kdbxKey)
              .map(
                (item) => ChipListItem(
                  value: item,
                  label: item,
                  select: tags.contains(item),
                  deletable: false,
                ),
              )
              .toList(),
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
      case KdbxKeySpecial.KEY_ATTACH:
        return ChipListFormField(
          label: widget.kdbxKey.key.fromKdbxKeyToI18n(context),
          initialValue: widget.kdbxEntry.binaryEntries
              .map(
                (item) => ChipListItem(
                  value: item,
                  label: item.key.key,
                  deletable: !item.value.isProtected,
                ),
              )
              .toList(),
          onChanged: (list) {
            _binaryKeys = list.map((item) => item.value.key).toList();
          },
          onChipTap: (item) {
            showBinaryAction(item);
            return false;
          },
          onAddChipTap: (list) async {
            try {
              final (filepath, bytes) = await SimpleFile.openFile();
              final map = MapEntry(
                _uniqueBinaryName(filepath),
                KdbxBinary(isInline: false, isProtected: false, value: bytes),
              );
              return ChipListItem(value: map, label: map.key.key);
            } catch (e) {
              if (e is! CancelException) {
                _logger.warning("open file fail!", e);
                showError(e);
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
      case KdbxKeySpecial.KEY_EXPIRES:
        return EntryExpiresFormField(
          label: widget.kdbxKey.key.fromKdbxKeyToI18n(context),
          initialValue: (
            widget.kdbxEntry.times.expires.get() ?? false,
            widget.kdbxEntry.times.expiryTime.get()?.toLocal() ??
                DateTime(4001, 7, 1, 18, 11, 58),
          ),
          onSaved: (value) {
            widget.onSaved(
              EntryExpiresFieldSaved(key: widget.kdbxKey, value: value!),
            );
          },
        );
      case KdbxKeyURLS.KEY_URL1:
      case KdbxKeyURLS.KEY_URL2:
      case KdbxKeyURLS.KEY_URL3:
      case KdbxKeyURLS.KEY_URL4:
      case KdbxKeyURLS.KEY_URL5:
        return ShakeFormField<String>(
          validator: _entryFieldValidator(),
          builder: (context, validator) {
            return EntryTextFormField(
              initialValue: initialValue,
              label: widget.kdbxKey.key.fromKdbxKeyToI18n(context),
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
          label: (_renameKdbxKey?.key ?? widget.kdbxKey.key).fromKdbxKeyToI18n(
            context,
          ),
          onSaved: _kdbxTextFieldSaved,
          onChanged: _onChanged,
          contextMenuBuilder: _contextMenuBuilder,
        );
    }
  }

  Future<ChipListItem<String>?> _addTag(List<ChipListItem<String>> list) async {
    final t = I18n.of(context)!;
    final kdbx = KdbxProvider.of(context).kdbx!;

    final result = await InputDialog.openDialog(
      context,
      title: t.label,
      label: t.new_label,
      limitItems: [
        ...kdbx.fieldStatistic.getStatistic(KdbxKeySpecial.TAGS),
        ...list.map((item) => item.value),
      ],
    );

    if (result != null && result is String) {
      return ChipListItem(value: result, label: result, select: true);
    }

    return null;
  }
}
