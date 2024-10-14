import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:path/path.dart' as path;

import '../../context/kdbx.dart';
import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../util/common.dart';
import '../../util/file.dart';
import '../../widget/chip_list.dart';
import '../../widget/common.dart';
import '../page.dart';

class EditAccountPage extends StatefulWidget {
  const EditAccountPage({super.key});

  static const routeName = "/edit_account";

  @override
  State<EditAccountPage> createState() => _EditAccountPageState();
}

class _EditAccountPageState extends State<EditAccountPage>
    with CommonWidgetUtil {
  final GlobalKey<FormState> _from = GlobalKey();

  Set<KdbxKey>? _entryFields;

  KdbxEntry? _kdbxEntry;

  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _kdbxEntrySave() async {
    if (_from.currentState!.validate()) {
      _from.currentState!.save();
      if (await kdbxSave(KdbxProvider.of(context)!)) {
        Navigator.of(context).pop(true);
      }
    }
  }

  void _kdbxEntryGroupSave(KdbxGroup? group) {
    final kdbx = KdbxProvider.of(context)!;

    if (group != null && _kdbxEntry!.parent != group) {
      kdbx.kdbxFile.move(_kdbxEntry!, group);
    }
  }

  void _entryFieldSaved(EntryFieldSaved field) {
    if (field is EntryBinaryFieldSaved) {
      final binarys = field.value;
      final oldBinaryKeys = _kdbxEntry!.binaryEntries.map((item) => item.key);
      // 删除不包含
      for (var key in oldBinaryKeys) {
        if (!binarys.any((item) => item.key == key)) {
          _kdbxEntry!.removeBinary(key);
        }
      }
      for (var binary in binarys) {
        if (_kdbxEntry!.getBinary(binary.key) == null) {
          // TODO! isProtected 应该怎么设置
          _kdbxEntry!.createBinary(
            isProtected: binary.value.isProtected,
            name: binary.key.key,
            bytes: binary.value.value,
          );
        }
      }
    } else if (field is EntryTagsFieldSaved) {
      _kdbxEntry!.tagList = field.value;
    } else if (field is EntryTextFieldSaved) {
      if (field.renameKdbxKey != null) {
        _kdbxEntry!.renameKey(field.key, field.renameKdbxKey!);
      }
      _kdbxEntry!.setString(field.renameKdbxKey ?? field.key, field.value);
    } else if (field is EntryTitleFieldSaved) {
      if (field.customIcon != null) {
        _kdbxEntry!.customIcon = field.customIcon;
      } else {
        _kdbxEntry!.icon.set(field.icon);
        _kdbxEntry!.customIcon = null;
      }
      _kdbxEntry!.setString(field.key, field.value);
    } else {
      // TODO! 不可能出现的情况
    }
  }

  void _entryFieldDelete(KdbxKey key) {
    setState(() {
      _entryFields!.remove(key);
    });
  }

  void _addEntryField() async {
    final t = I18n.of(context)!;
    final kdbx = KdbxProvider.of(context)!;

    final limitItmes = [
      ...KdbxKeyCommon.all,
      ...KdbxKeySpecial.all,
      ..._entryFields!
    ].map((item) => item.key).toList();

    final result = await InputDialog.openDialog(
      context,
      title: t.add,
      label: "新建字段",
      promptItmes: kdbx.fieldStatistic.customFields
          .where((item) => !limitItmes.contains(item))
          .toList(),
      limitItems: limitItmes,
    );
    if (result != null && result is String) {
      setState(() {
        _entryFields!.add(KdbxKey(result));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;
    final kdbx = KdbxProvider.of(context)!;

    _kdbxEntry ??= ModalRoute.of(context)!.settings.arguments as KdbxEntry?;

    _kdbxEntry ??= kdbx.createVirtualEntry()
      ..setString(
        KdbxKeyCommon.PASSWORD,
        PlainValue(
          randomPassword(length: 10),
        ),
      );

    final defaultFields = [
      ...KdbxKeyCommon.all,
      ...KdbxKeySpecial.all,
    ];

    _entryFields ??= _kdbxEntry!.stringEntries
        .where((item) => !defaultFields.contains(item.key))
        .map((item) => item.key)
        .toSet();

    final children = [
      KdbxEntryGroup(
        initialValue: _kdbxEntry!.parent != null &&
                _kdbxEntry!.parent != kdbx.virtualGroup
            ? _kdbxEntry!.parent
            : kdbx.kdbxFile.body.rootGroup,
        onSaved: _kdbxEntryGroupSave,
      ),
      ...KdbxKeyCommon.all.map(
        (item) => EntryField(
          kdbxKey: item,
          kdbxEntry: _kdbxEntry!,
          slidableEnabled: false,
          onSaved: _entryFieldSaved,
        ),
      ),
      ..._entryFields!.map(
        (item) => EntryField(
          kdbxKey: item,
          kdbxEntry: _kdbxEntry!,
          onDeleted: _entryFieldDelete,
          onSaved: _entryFieldSaved,
        ),
      ),
      _buildAddFieldWidget(),
      ...KdbxKeySpecial.all.map(
        (item) => EntryField(
          kdbxKey: item,
          kdbxEntry: _kdbxEntry!,
          slidableEnabled: false,
          onSaved: _entryFieldSaved,
        ),
      ),
      const SizedBox(height: 42)
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(t.edit_account),
      ),
      body: Form(
        key: _from,
        onChanged: () {
          setState(() {
            _isDirty = true;
          });
        },
        child: SlidableAutoCloseBehavior(
          child: ListView.separated(
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
          ),
        ),
      ),
      floatingActionButton: _isDirty
          ? FloatingActionButton(
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
          label: const Text("添加字段"),
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
                  final kdbx = KdbxProvider.of(field.context)!;

                  final result = await SimpleSelectorDialog.openDialog(
                    field.context,
                    title: "选择分组",
                    value: field.value,
                    items: kdbx.rootGroups
                        .map((item) => SimpleSelectorDialogItem(
                              value: item,
                              label: item.name.get() ?? '',
                            ))
                        .toList(),
                  );

                  if (result != null && result is KdbxGroup) {
                    field.didChange(result);
                  }
                },
                child: InputDecorator(
                  isEmpty: field.value == null,
                  decoration: const InputDecoration(
                    labelText: "分组",
                    border: OutlineInputBorder(),
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
    this.slidableEnabled = true,
    required this.onSaved,
  });

  final KdbxKey kdbxKey;
  final KdbxEntry kdbxEntry;
  final bool slidableEnabled;
  final OnEntryFidleDeleted? onDeleted;
  final OnEntryFieldSaved onSaved;

  @override
  State<EntryField> createState() => _EntryFieldState();
}

class _EntryFieldState extends State<EntryField>
    with CommonWidgetUtil, BottomSheetUtil {
  KdbxKey? _renameKdbxKey;

  final bool _displayScanner = Platform.isAndroid || Platform.isIOS;
  List<KdbxKey> _binaryKeys = [];

  void _onRenameKdbxKey() async {
    final t = I18n.of(context)!;
    final kdbx = KdbxProvider.of(context)!;
    final limitItmes = {
      ...KdbxKeyCommon.all,
      ...KdbxKeySpecial.all,
      ...widget.kdbxEntry.stringEntries.map((item) => item.key)
    }.map((item) => item.key).toList();

    limitItmes.remove(widget.kdbxKey.key);

    if (_renameKdbxKey != null) {
      limitItmes.remove(_renameKdbxKey!.key);
    }

    final result = await InputDialog.openDialog(
      context,
      title: "重命名",
      label: "新建字段",
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
    return Slidable(
      groupTag: "0",
      enabled: widget.slidableEnabled,
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
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: _buildFormFieldFactory(),
      ),
    );
  }

  String _kdbKey2I18n() {
    final t = I18n.of(context)!;
    switch (widget.kdbxKey.key) {
      case KdbxKeyCommon.KEY_TITLE:
        return t.domain_title;
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
      default:
        return _renameKdbxKey?.key ?? widget.kdbxKey.key;
    }
  }

  FormFieldValidator<String?>? _entryFieldValidator() {
    final t = I18n.of(context)!;

    switch (widget.kdbxKey.key) {
      case KdbxKeyCommon.KEY_URL:
        return (value) =>
            value!.isNotEmpty && !CommonRegExp.domain.hasMatch(value)
                ? t.format_error(CommonRegExp.domain.pattern)
                : null;
      case KdbxKeyCommon.KEY_EMAIL:
        return (value) =>
            value!.isNotEmpty && !CommonRegExp.email.hasMatch(value)
                ? t.format_error(CommonRegExp.email.pattern)
                : null;
      case KdbxKeyCommon.KEY_OTP:
        return (value) =>
            value!.isNotEmpty && !CommonRegExp.oneTimePassword.hasMatch(value)
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
        return DropdownMenuFormField(
          initialValue: widget.kdbxEntry.getString(widget.kdbxKey)?.getText(),
          itmes: kdbx.fieldStatistic.getStatistic(widget.kdbxKey)!.toList(),
          label: _kdbKey2I18n(),
          onSaved: _kdbxTextFieldSaved,
          expandedInsets: const EdgeInsets.all(0),
          validator: _entryFieldValidator(),
          menuHeight: 150,
        );
      case KdbxKeyCommon.KEY_PASSWORD:
        return EntryTextFormField(
          initialValue: widget.kdbxEntry.getString(widget.kdbxKey)?.getText(),
          label: _kdbKey2I18n(),
          trailingIcon: const Icon(Icons.create),
          onTrailingTap: () async {
            final password = await Navigator.of(context)
                .pushNamed(GenPassword.routeName, arguments: true);
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
                  final optUrl = await Navigator.of(context)
                      .pushNamed(QrCodeScannerPage.routeName);
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
                // TODO! 提示错误
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
      default:
        return EntryTextFormField(
          initialValue: widget.kdbxEntry.getString(widget.kdbxKey)?.getText(),
          label: _kdbKey2I18n(),
          onSaved: _kdbxTextFieldSaved,
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

  late TextEditingController _controller;
  late KdbxIconWidgetData _kdbxIcon;

  @override
  void initState() {
    _controller = TextEditingController(text: widget.initialValue);
    _kdbxIcon = widget.kdbxIcon;
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: _globalKey,
      controller: _controller,
      onSaved: (value) {
        widget.onSaved((value!, _kdbxIcon.icon, _kdbxIcon.customIcon));
      },
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        prefixIcon: IconButton(
          onPressed: () async {
            final reslut =
                await Navigator.of(context).pushNamed(SelectIconPage.routeName);
            if (reslut != null && reslut is KdbxIconWidgetData) {
              setState(() {
                _kdbxIcon = reslut;
                // 使 textform 触发 from 的 onChange
                _globalKey.currentState?.didChange(_controller.text);
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
  });

  final String? label;
  final String? initialValue;
  final Widget? trailingIcon;
  final OnTrailingTap? onTrailingTap;

  final FormFieldSetter<String>? onSaved;
  final FormFieldValidator<String>? validator;

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
    return TextFormField(
      validator: widget.validator,
      controller: _controller,
      onSaved: widget.onSaved,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        suffixIcon:
            (widget.trailingIcon != null && widget.onTrailingTap != null)
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
              final text = await Navigator.of(field.context)
                  .pushNamed(EditNotes.routeName,
                      arguments: EditNotesArgs(
                        text: field.value ?? '',
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
                  ? Text(field.value!)
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
    Widget? trailingIcon,
    OnTrailingTap? onTrailingTap,
    String? label,
    super.initialValue,
    EdgeInsets? expandedInsets,
    required List<String> itmes,
    super.onSaved,
    super.autovalidateMode = AutovalidateMode.disabled,
    super.validator,
  }) : super(builder: (FormFieldState<String> field) {
          final state = field as _DropdownMenuFormFieldState;

          final Widget? trailing = trailingIcon != null
              ? GestureDetector(
                  onTap: onTrailingTap != null
                      ? () async {
                          state.controller.text =
                              await onTrailingTap() ?? state.controller.text;
                        }
                      : null,
                  child: trailingIcon,
                )
              : null;

          return DropdownMenu(
            width: width,
            menuHeight: menuHeight,
            trailingIcon: trailing,
            label: label != null ? Text(label) : null,
            errorText: state.errorText,
            selectedTrailingIcon: trailing,
            enableFilter: true,
            enableSearch: true,
            controller: state.controller,
            initialSelection: initialValue,
            expandedInsets: expandedInsets,
            requestFocusOnTap: true,
            dropdownMenuEntries: itmes
                .map((value) => DropdownMenuEntry(value: value, label: value))
                .toList(),
          );
        });

  @override
  FormFieldState<String> createState() => _DropdownMenuFormFieldState();
}

class _DropdownMenuFormFieldState extends FormFieldState<String> {
  late TextEditingController controller;

  @override
  void initState() {
    controller = TextEditingController(text: widget.initialValue);
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
