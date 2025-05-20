import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import '../../util/route.dart';
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
  _EditAccountArgs({
    super.key,
    this.kdbxEntry,
  });

  final KdbxEntry? kdbxEntry;
}

class EditAccountRoute extends PageRouteInfo<_EditAccountArgs> {
  EditAccountRoute({
    Key? key,
    KdbxEntry? kdbxEntry,
    KdbxUuid? uuid,
  }) : super(
          name,
          args: _EditAccountArgs(
            key: key,
            kdbxEntry: kdbxEntry,
          ),
          rawPathParams: {
            "uuid": uuid?.deBase64Uuid,
          },
        );

  static const name = "EditAccountRoute";

  static final PageInfo page = PageInfo.builder(
    name,
    builder: (context, data) {
      final args = data.argsAs<_EditAccountArgs>(
        orElse: () {
          final kdbx = KdbxProvider.of(context)!;
          final uuid = data.inheritedPathParams.optString("uuid")?.kdbxUuid;
          final kdbxEntry = uuid != null ? kdbx.findEntryByUuid(uuid) : null;

          return _EditAccountArgs(
            kdbxEntry: kdbxEntry,
          );
        },
      );
      return EditAccountPage(
        key: args.key,
        kdbxEntry: args.kdbxEntry,
      );
    },
  );
}

class EditAccountPage extends StatefulWidget {
  const EditAccountPage({
    super.key,
    this.kdbxEntry,
  });

  final KdbxEntry? kdbxEntry;

  @override
  State<EditAccountPage> createState() => _EditAccountPageState();
}

class _EditAccountPageState extends State<EditAccountPage>
    with SecondLevelPageAutoBack<EditAccountPage> {
  GlobalKey<FormState> _from = GlobalKey();

  late KdbxEntry _kdbxEntry = widget.kdbxEntry ?? _createKdbxEntry();

  late Set<KdbxKey> _entryFields =
      _kdbxEntry.customEntries.map((item) => item.key).toSet();

  bool _isDirty = false;

  @override
  void didUpdateWidget(covariant EditAccountPage oldWidget) {
    /// 触发整个 form 表进行重建
    if (widget.kdbxEntry != null && widget.kdbxEntry != oldWidget.kdbxEntry) {
      _kdbxEntry = widget.kdbxEntry ?? _createKdbxEntry();
      _entryFields = _kdbxEntry.customEntries.map((item) => item.key).toSet();
      _from = GlobalKey();
    }
    super.didUpdateWidget(oldWidget);
  }

  KdbxEntry _createKdbxEntry() {
    return KdbxProvider.of(context)!.createVirtualEntry()
      ..setString(
        KdbxKeyCommon.PASSWORD,
        PlainValue(
          randomPassword(length: 10).$1,
        ),
      );
  }

  void _kdbxEntrySave() async {
    if (_from.currentState!.validate()) {
      _from.currentState!.save();
      if (await kdbxSave(KdbxProvider.of(context)!)) {
        context.router.pop(true);
      }
    }
  }

  void _kdbxEntryGroupSave(KdbxGroup? group) {
    final kdbx = KdbxProvider.of(context)!;
    if (group != null && _kdbxEntry.parent != group) {
      kdbx.kdbxFile.move(_kdbxEntry, group);
    }
  }

  void _entryFieldSaved(EntryFieldSaved field) {
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
    } else if (field is EntryTagsFieldSaved) {
      _kdbxEntry.tagList = field.value;
    } else if (field is EntryTextFieldSaved) {
      if (field.renameKdbxKey != null) {
        _kdbxEntry.renameKey(field.key, field.renameKdbxKey!);
      }
      _kdbxEntry.setString(field.renameKdbxKey ?? field.key, field.value);
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
    debugPrint("_entryFieldSaved ${DateTime.now()}");
  }

  void _entryFieldDelete(KdbxKey key) {
    setState(() {
      _entryFields.remove(key);
      if (_kdbxEntry.stringEntries.any((item) => item.key == key)) {
        _isDirty = true;
      }
    });
  }

  void _addEntryField() async {
    final t = I18n.of(context)!;
    final kdbx = KdbxProvider.of(context)!;

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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;
    final kdbx = KdbxProvider.of(context)!;

    final children = [
      KdbxEntryGroup(
        initialValue:
            _kdbxEntry.parent != kdbx.virtualGroup
                ? _kdbxEntry.parent
                : kdbx.kdbxFile.body.rootGroup,
        onSaved: _kdbxEntryGroupSave,
      ),
      ...KdbxKeyCommon.all.map(
        (item) => EntryField(
          kdbxKey: item,
          kdbxEntry: _kdbxEntry,
          onSaved: _entryFieldSaved,
        ),
      ),
      ..._entryFields.map(
        (item) => EntryField(
          kdbxKey: item,
          kdbxEntry: _kdbxEntry,
          onDeleted: _entryFieldDelete,
          onSaved: _entryFieldSaved,
        ),
      ),
      _buildAddFieldWidget(),
      ...KdbxKeySpecial.all.map(
        (item) => EntryField(
          kdbxKey: item,
          kdbxEntry: _kdbxEntry,
          onSaved: _entryFieldSaved,
        ),
      ),
      const SizedBox(height: 42)
    ];

    final child = ListView.separated(
      padding: const EdgeInsets.only(top: 24, bottom: 24),
      separatorBuilder: (context, index) {
        return const SizedBox(
          height: 12,
        );
      },
      itemBuilder: (context, index) {
        return children[index];
      },
      itemCount: children.length,
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
                borderRadius: BorderRadius.all(
                  Radius.circular(56 / 2),
                ),
              ),
              child: const Icon(Icons.save),
            )
          : null,
    );
  }

  Widget _buildAddFieldWidget() {
    return Column(
      children: [
        TextButton.icon(
          onPressed: _addEntryField,
          label: Text(I18n.of(context)!.add_field),
          icon: const Icon(Icons.add),
        )
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

class EntryTextFieldSaved extends EntryFieldSaved<StringValue> {
  EntryTextFieldSaved({
    required super.key,
    required super.value,
    this.renameKdbxKey,
  });
  final KdbxKey? renameKdbxKey;
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

typedef OnTrailingTap = Future<String?> Function();

class KdbxEntryGroup extends FormField<KdbxGroup> {
  KdbxEntryGroup({super.key, super.initialValue, super.onSaved})
      : super(
          builder: (field) {
            return Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: GestureDetector(
                onTap: () async {
                  final result =
                      await field.showGroupSelectorDialog(field.value);

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

  final bool _displayScanner = Platform.isAndroid || Platform.isIOS;
  List<KdbxKey> _binaryKeys = [];

  void _onRenameKdbxKey() async {
    final t = I18n.of(context)!;
    final kdbx = KdbxProvider.of(context)!;
    final limitItmes = {
      ...defaultKdbxKeys,
      ...widget.kdbxEntry.stringEntries.map((item) => item.key)
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

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: _buildFormFieldFactory(),
    );

    return isMobile
        ? Slidable(
            groupTag: "0",
            enabled: widget.kdbxEntry.isCustomKey(widget.kdbxKey),
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
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
                const SizedBox(
                  width: 16,
                )
              ],
            ),
            child: child,
          )
        : child;
  }

  String _kdbKey2I18n() {
    final t = I18n.of(context)!;
    switch (widget.kdbxKey.key) {
      case KdbxKeyCommon.KEY_TITLE:
        return t.title;
      case KdbxKeyCommon.KEY_URL:
        return t.domain;
      case KdbxKeyCommon.KEY_USER_NAME:
        return t.account;
      case KdbxKeyCommon.KEY_EMAIL:
        return t.email;
      case KdbxKeyCommon.KEY_PASSWORD:
        return t.password;
      case KdbxKeyCommon.KEY_OTP:
        return t.otp;
      case KdbxKeyCommon.KEY_NOTES:
        return t.description;
      case KdbxKeySpecial.KEY_TAGS:
        return t.label;
      case KdbxKeySpecial.KEY_ATTACH:
        return t.attachment;
      case KdbxKeySpecial.KEY_EXPIRES:
        return t.expires_time;
      default:
        return _renameKdbxKey?.key ?? widget.kdbxKey.key;
    }
  }

  FormFieldValidator<String?>? _entryFieldValidator() {
    final t = I18n.of(context)!;

    switch (widget.kdbxKey.key) {
      case KdbxKeyCommon.KEY_URL:
        return (value) => value != null &&
                value.isNotEmpty &&
                !CommonRegExp.domain.hasMatch(value)
            ? t.format_error(CommonRegExp.domain.pattern)
            : null;
      case KdbxKeyCommon.KEY_EMAIL:
        return (value) => value != null &&
                value.isNotEmpty &&
                !CommonRegExp.email.hasMatch(value)
            ? t.format_error(CommonRegExp.email.pattern)
            : null;
      case KdbxKeyCommon.KEY_OTP:
        return (value) => value != null &&
                value.isNotEmpty &&
                !CommonRegExp.oneTimePassword.hasMatch(value)
            ? t.format_error(CommonRegExp.oneTimePassword.pattern)
            : null;
      default:
        return null;
    }
  }

  void _kdbxTextFieldSaved(String? value) {
    widget.onSaved(EntryTextFieldSaved(
      key: widget.kdbxKey,
      renameKdbxKey: _renameKdbxKey,
      value: PlainValue(value),
    ));
  }

  KdbxKey _uniqueBinaryName(String filepath) {
    final fileName = path.basename(filepath);
    final lastIndex = fileName.lastIndexOf('.');
    final baseName =
        lastIndex > -1 ? fileName.substring(0, lastIndex) : fileName;
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
    if (widget.kdbxEntry.isCustomKey(widget.kdbxKey)) {
      final t = I18n.of(context)!;

      return AdaptiveTextSelectionToolbar.buttonItems(
        buttonItems: [
          ...editableTextState.contextMenuButtonItems,
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
    final kdbx = KdbxProvider.of(context)!;
    switch (widget.kdbxKey.key) {
      case KdbxKeyCommon.KEY_TITLE:
        return EntryTitleFormField(
          initialValue: widget.kdbxEntry.getString(widget.kdbxKey)?.getText(),
          label: _kdbKey2I18n(),
          kdbxIcon: KdbxIconWidgetData(
            icon: widget.kdbxEntry.icon.get() ?? KdbxIcon.Key,
            customIcon: widget.kdbxEntry.customIcon,
          ),
          onSaved: (data) {
            widget.onSaved(EntryTitleFieldSaved(
              key: widget.kdbxKey,
              value: PlainValue(data!.$1),
              icon: data.$2,
              customIcon: data.$3,
            ));
          },
        );
      case KdbxKeyCommon.KEY_URL:
      case KdbxKeyCommon.KEY_USER_NAME:
      case KdbxKeyCommon.KEY_EMAIL:
        return ShakeFormField<String>(
          validator: _entryFieldValidator(),
          builder: (context, validator) {
            return DropdownMenuFormField(
              initialValue:
                  widget.kdbxEntry.getString(widget.kdbxKey)?.getText(),
              items: kdbx.fieldStatistic.getStatistic(widget.kdbxKey)!.toList(),
              label: _kdbKey2I18n(),
              onSaved: _kdbxTextFieldSaved,
              expandedInsets: const EdgeInsets.all(0),
              validator: validator,
              menuHeight: 150,
            );
          },
        );
      case KdbxKeyCommon.KEY_PASSWORD:
        return EntryTextFormField(
          initialValue: widget.kdbxEntry.getString(widget.kdbxKey)?.getText(),
          label: _kdbKey2I18n(),
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
        );
      case KdbxKeyCommon.KEY_OTP:
        return EntryTextFormField(
          initialValue: widget.kdbxEntry.getString(widget.kdbxKey)?.getText(),
          label: _kdbKey2I18n(),
          trailingIcon:
              _displayScanner ? const Icon(Icons.qr_code_scanner) : null,
          onTrailingTap: _displayScanner
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
          validator: _entryFieldValidator(),
        );
      case KdbxKeyCommon.KEY_NOTES:
        return EntryNotesFormField(
          initialValue: widget.kdbxEntry.getString(widget.kdbxKey)?.getText(),
          label: _kdbKey2I18n(),
          onSaved: _kdbxTextFieldSaved,
        );
      case KdbxKeySpecial.KEY_TAGS:
        final tags = widget.kdbxEntry.tagList;
        return ChipListFormField(
          label: _kdbKey2I18n(),
          initialValue: kdbx.fieldStatistic
              .getStatistic(widget.kdbxKey)!
              .map((item) => ChipListItem(
                    value: item,
                    label: item,
                    select: tags.contains(item),
                    deletable: false,
                  ))
              .toList(),
          onChipTap: (item) {
            item.select = !item.select;
            return true;
          },
          onAddChipTap: _addTag,
          onSaved: (list) {
            widget.onSaved(EntryTagsFieldSaved(
              key: widget.kdbxKey,
              value: list!
                  .where((item) => item.select)
                  .map((item) => item.value)
                  .toList(),
            ));
          },
        );
      case KdbxKeySpecial.KEY_ATTACH:
        return ChipListFormField(
          label: _kdbKey2I18n(),
          initialValue: widget.kdbxEntry.binaryEntries
              .map((item) => ChipListItem(
                    value: item,
                    label: item.key.key,
                    deletable: !item.value.isProtected,
                  ))
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
                  KdbxBinary(
                    isInline: false,
                    isProtected: false,
                    value: bytes,
                  ));
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
            widget.onSaved(EntryBinaryFieldSaved(
              key: widget.kdbxKey,
              value: list!.map((item) => item.value).toList(),
            ));
          },
        );
      case KdbxKeySpecial.KEY_EXPIRES:
        return EntryExpiresFormField(
          label: _kdbKey2I18n(),
          initialValue: (
            widget.kdbxEntry.times.expires.get() ?? false,
            widget.kdbxEntry.times.expiryTime.get()?.toLocal() ??
                DateTime(4001, 7, 1, 18, 11, 58),
          ),
          onSaved: (value) {
            widget.onSaved(EntryExpiresFieldSaved(
              key: widget.kdbxKey,
              value: value!,
            ));
          },
        );
      default:
        return EntryTextFormField(
          initialValue: widget.kdbxEntry.getString(widget.kdbxKey)?.getText(),
          label: _kdbKey2I18n(),
          onSaved: _kdbxTextFieldSaved,
          contextMenuBuilder: _contextMenuBuilder,
        );
    }
  }

  Future<ChipListItem<String>?> _addTag(List<ChipListItem<String>> list) async {
    final t = I18n.of(context)!;
    final kdbx = KdbxProvider.of(context)!;

    final result = await InputDialog.openDialog(
      context,
      title: t.label,
      label: t.new_label,
      limitItems: [
        ...kdbx.fieldStatistic.getStatistic(KdbxKeySpecial.TAGS)!,
        ...list.map((item) => item.value)
      ],
    );

    if (result != null && result is String) {
      return ChipListItem(
        value: result,
        label: result,
        select: true,
      );
    }

    return null;
  }
}

class EntryTitleFormField extends StatefulWidget {
  const EntryTitleFormField({
    super.key,
    required this.kdbxIcon,
    this.label,
    this.initialValue,
    required this.onSaved,
  });

  final String? label;
  final String? initialValue;
  final KdbxIconWidgetData kdbxIcon;

  final FormFieldSetter<(String, KdbxIcon, KdbxCustomIcon?)> onSaved;

  @override
  State<EntryTitleFormField> createState() => _EntryTitleFormFieldState();
}

class _EntryTitleFormFieldState extends State<EntryTitleFormField> {
  final GlobalKey<FormFieldState<String>> _globalKey = GlobalKey();

  late KdbxIconWidgetData _kdbxIcon = widget.kdbxIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: _globalKey,
      initialValue: widget.initialValue,
      onSaved: (value) {
        widget.onSaved((value!, _kdbxIcon.icon, _kdbxIcon.customIcon));
      },
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        prefixIcon: IconButton(
          onPressed: () async {
            final reslut = await context.router.push(SelectIconRoute());
            if (reslut != null && reslut is KdbxIconWidgetData) {
              setState(() {
                _kdbxIcon = reslut;
                // 使 textform 触发 from 的 onChange
                _globalKey.currentState?.didChange(
                  _globalKey.currentState?.value,
                );
              });
            }
          },
          icon: KdbxIconWidget(
            kdbxIcon: _kdbxIcon,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class EntryTextFormField extends StatefulWidget {
  const EntryTextFormField({
    super.key,
    this.label,
    this.initialValue,
    this.trailingIcon,
    this.onTrailingTap,
    this.onSaved,
    this.validator,
    this.contextMenuBuilder = _defaultContextMenuBuilder,
  });

  final String? label;
  final String? initialValue;
  final Widget? trailingIcon;
  final OnTrailingTap? onTrailingTap;

  final FormFieldSetter<String>? onSaved;
  final FormFieldValidator<String>? validator;
  final EditableTextContextMenuBuilder? contextMenuBuilder;

  static Widget _defaultContextMenuBuilder(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    return AdaptiveTextSelectionToolbar.editableText(
      editableTextState: editableTextState,
    );
  }

  @override
  State<EntryTextFormField> createState() => _EntryTextFormFieldState();
}

class _EntryTextFormFieldState extends State<EntryTextFormField> {
  late TextEditingController _controller;

  @override
  void initState() {
    _controller = TextEditingController(text: widget.initialValue);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShakeFormField<String>(
      validator: widget.validator,
      builder: (context, validator) {
        return TextFormField(
          validator: validator,
          controller: _controller,
          onSaved: widget.onSaved,
          contextMenuBuilder: widget.contextMenuBuilder,
          decoration: InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(),
            suffixIcon: (widget.trailingIcon != null &&
                    widget.onTrailingTap != null)
                ? Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: IconButton(
                      onPressed: () async {
                        _controller.text =
                            await widget.onTrailingTap!() ?? _controller.text;
                      },
                      icon: widget.trailingIcon!,
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}

class EntryNotesFormField extends FormField<String> {
  EntryNotesFormField({
    super.key,
    String? label,
    super.initialValue,
    super.onSaved,
  }) : super(builder: (field) {
          return GestureDetector(
            onTap: () async {
              final text = await field.context.router.push(EditNotesRoute(
                text: field.value ?? "",
              ));

              if (text != null && text is String) {
                field.didChange(text);
              }
            },
            child: InputDecorator(
              isEmpty: field.value == null || field.value!.isEmpty,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
              ),
              child: field.value != null && field.value!.isNotEmpty
                  ? Text(field.value!, maxLines: 3)
                  : null,
            ),
          );
        });
}

typedef OnChipTap<T> = bool Function(ChipListItem<T> item);
typedef OnAddChipTap<T> = Future<ChipListItem<T>?> Function(
    List<ChipListItem<T>> list);

class ChipListFormField<T> extends FormField<List<ChipListItem<T>>> {
  ChipListFormField({
    super.key,
    String? label,
    OnChipTap<T>? onChipTap,
    OnAddChipTap<T>? onAddChipTap,
    ValueChanged<List<ChipListItem<T>>>? onChanged,
    required List<ChipListItem<T>> initialValue,
    super.onSaved,
    super.autovalidateMode = AutovalidateMode.disabled,
  }) : super(
          initialValue: initialValue,
          builder: (field) {
            void onChangedHandler(List<ChipListItem<T>> value) {
              field.didChange(value);
              onChanged?.call(value);
            }

            return InputDecorator(
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
              ),
              child: ChipList<T>(
                maxHeight: 150,
                items: field.value!,
                onChipTap: onChipTap != null
                    ? (item) {
                        if (onChipTap(item)) {
                          onChangedHandler(field.value!);
                        }
                      }
                    : null,
                onDeleted: (item) {
                  final list = field.value!;
                  list.remove(item);
                  onChangedHandler(list);
                },
                onAddChipTap: onAddChipTap != null
                    ? () async {
                        final item = await onAddChipTap(field.value!);
                        if (item != null) {
                          final list = field.value!;
                          list.add(item);
                          onChangedHandler(list);
                        }
                      }
                    : null,
              ),
            );
          },
        );
}

class DropdownMenuFormField extends FormField<String> {
  DropdownMenuFormField({
    super.key,
    double? width,
    double? menuHeight,
    String? label,
    super.initialValue,
    EdgeInsets? expandedInsets,
    required List<String> items,
    super.onSaved,
    super.autovalidateMode = AutovalidateMode.disabled,
    super.validator,
  }) : super(builder: (FormFieldState<String> field) {
          final state = field as _DropdownMenuFormFieldState;

          return DropdownMenu(
            width: width,
            menuHeight: menuHeight,
            label: label != null ? Text(label) : null,
            errorText: state.errorText,
            enableFilter: true,
            enableSearch: true,
            controller: state.controller,
            initialSelection: initialValue,
            expandedInsets: expandedInsets,
            requestFocusOnTap: true,
            dropdownMenuEntries: items
                .map((value) => DropdownMenuEntry(value: value, label: value))
                .toList(),
          );
        });

  @override
  FormFieldState<String> createState() => _DropdownMenuFormFieldState();
}

class _DropdownMenuFormFieldState extends FormFieldState<String> {
  late TextEditingController controller =
      TextEditingController(text: widget.initialValue);

  @override
  void initState() {
    controller.addListener(_handleControllerChanged);
    super.initState();
  }

  @override
  void dispose() {
    controller.removeListener(_handleControllerChanged);
    controller.dispose();
    super.dispose();
  }

  @override
  void reset() {
    controller.text = widget.initialValue ?? "";
    super.reset();
  }

  void _handleControllerChanged() {
    if (controller.text != value) {
      didChange(controller.text);
    }
  }
}

class EntryExpiresFormField extends FormField<(bool, DateTime)> {
  EntryExpiresFormField({
    super.key,
    String? label,
    super.initialValue,
    super.onSaved,
  }) : super(builder: (field) {
          return GestureDetector(
            onTap: () async {
              final result = await field.showDateTimePicker(
                field.context,
                minimumDate: DateTime(2024, 7, 1, 18, 11, 58),
                maximumDate: DateTime(4001, 7, 1, 18, 11, 58),
                initialDateTime: field.value?.$2,
              );
              if (result != null) {
                field.didChange((field.value?.$1 ?? false, result));
              }
            },
            child: InputDecorator(
              isEmpty: false,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Checkbox(
                    value: field.value?.$1 ?? false,
                    onChanged: (value) {
                      if (field.value != null) {
                        field.didChange((value ?? false, field.value!.$2));
                      }
                    },
                  ),
                ),
              ),
              child: field.value != null
                  ? Text(field.value!.$2.toLocal().formatDate)
                  : null,
            ),
          );
        });
}
