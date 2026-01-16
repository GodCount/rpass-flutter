import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:rich_text_controller/rich_text_controller.dart';

import '../kdbx/kdbx.dart';
import '../page/route.dart';
import '../util/common.dart';
import 'chip_list.dart';
import 'common.dart';
import 'extension_state.dart';
import 'kdbx_icon.dart';

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
          icon: KdbxIconWidget(kdbxIcon: _kdbxIcon, size: 18),
        ),
      ),
    );
  }
}

typedef OnTrailingTap = Future<String?> Function();

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
    return TextFormField(
      validator: widget.validator,
      controller: _controller,
      onSaved: widget.onSaved,
      contextMenuBuilder: widget.contextMenuBuilder,
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
  }) : super(
         builder: (field) {
           return GestureDetector(
             onTap: () async {
               final text = await field.context.router.push(
                 EditNotesRoute(text: field.value ?? ""),
               );

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
         },
       );
}

typedef OnChipTap<T> = bool Function(ChipListItem<T> item);
typedef OnAddChipTap<T> =
    Future<ChipListItem<T>?> Function(List<ChipListItem<T>> list);

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

class EntryExpiresFormField extends FormField<(bool, DateTime)> {
  EntryExpiresFormField({
    super.key,
    String? label,
    super.initialValue,
    super.onSaved,
  }) : super(
         builder: (field) {
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
         },
       );
}

class EntryAutoTypeFormField extends StatelessWidget {
  const EntryAutoTypeFormField({
    super.key,
    this.label,
    required this.kdbxEntry,
    this.onSaved,
  });

  final String? label;

  final KdbxEntry kdbxEntry;

  final FormFieldSetter<String>? onSaved;

  @override
  Widget build(BuildContext context) {
    return RichWrapper(
      initialText: kdbxEntry.getAutoTypeSequence(),
      targetMatches: [
        MatchTargetItem.pattern(
          AutoTypeRichPattern.BUTTON,
          allowInlineMatching: true,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge!.copyWith(color: Colors.blueAccent),
        ),
        MatchTargetItem.pattern(
          AutoTypeRichPattern.KDBX_KEY,
          allowInlineMatching: true,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge!.copyWith(color: Colors.green),
        ),
        MatchTargetItem.pattern(
          AutoTypeRichPattern.SHORTCUT_KEY,
          allowInlineMatching: true,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge!.copyWith(color: Colors.orangeAccent),
        ),
      ],
      child: (controller) {
        return TextFormField(
          controller: controller,
          onSaved: onSaved,
          readOnly: true,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          onTap: () async {
            final text = await context.router.push(
              EditAutoTypeRoute(text: controller.text, kdbxEntry: kdbxEntry),
            );

            if (text != null && text is String) {
              controller.text = text;
            }
          },
        );
      },
    );
  }
}

class EntryAutoFillAppFormField extends StatefulWidget {
  const EntryAutoFillAppFormField({
    super.key,
    this.label,
    this.initialValue,
    this.onSaved,
  });

  final String? label;
  final String? initialValue;
  final FormFieldSetter<String>? onSaved;

  @override
  State<EntryAutoFillAppFormField> createState() =>
      _EntryAutoFillAppFormFieldState();
}

class _EntryAutoFillAppFormFieldState extends State<EntryAutoFillAppFormField> {
  late Future<AppInfo?> _future = _getAppInfo();

  Future<AppInfo?> _getAppInfo() async {
    return widget.initialValue != null
        ? InstalledAppsInstance.instance.getAppInfo(widget.initialValue!)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: widget.initialValue,
      onSaved: widget.onSaved,
      builder: (field) {
        return FutureBuilder<AppInfo?>(
          future: _future,
          builder: (context, snapshot) {
            return GestureDetector(
              onTap: () async {
                final packageName = await field.context.router.push(
                  SelectAutoFillAppRoute(),
                );
                if (field.value == packageName ||
                    field.value == null && packageName == "none") {
                  return;
                }
                if (packageName != null && packageName is String) {
                  _future = InstalledAppsInstance.instance.getAppInfo(
                    packageName,
                  );

                  field.didChange(packageName == "none" ? null : packageName);
                }
              },
              child: InputDecorator(
                isEmpty: field.value == null || field.value!.isEmpty,
                decoration: InputDecoration(
                  labelText: widget.label,
                  border: const OutlineInputBorder(),
                  prefixIcon: IconButton(
                    onPressed: null,
                    icon: snapshot.hasData
                        ? ImageFileString(
                            snapshot.data!.icon,
                            width: 18,
                            height: 18,
                            error: const Icon(Icons.android_outlined, size: 18),
                          )
                        : const Icon(Icons.android_outlined, size: 18),
                  ),
                ),
                child: snapshot.hasData || field.value != null
                    ? Text(snapshot.data?.name ?? field.value ?? "")
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}

class DropdownMenuFormField2 extends FormField<String> {
  DropdownMenuFormField2({
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
    bool enableFilter = false,
    bool? requestFocusOnTap,
  }) : super(
         builder: (FormFieldState<String> field) {
           final state = field as _DropdownMenuFormField2State;

           return DropdownMenu(
             width: width,
             menuHeight: menuHeight,
             label: label != null ? Text(label) : null,
             errorText: state.errorText,
             enableFilter: enableFilter,
             controller: state.controller,
             initialSelection: initialValue,
             expandedInsets: expandedInsets,
             requestFocusOnTap: requestFocusOnTap,
             dropdownMenuEntries: items
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
                 .toList(),
           );
         },
       );

  @override
  FormFieldState<String> createState() => _DropdownMenuFormField2State();
}

class _DropdownMenuFormField2State extends FormFieldState<String> {
  late TextEditingController controller = TextEditingController(
    text: widget.initialValue,
  );

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
