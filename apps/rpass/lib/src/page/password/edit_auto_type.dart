import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:rich_text_controller/rich_text_controller.dart';

import '../../context/kdbx.dart';
import '../../i18n.dart';
import '../../kdbx/auto_type.dart';
import '../../kdbx/extension.dart';
import '../../kdbx/kdbx.dart';
import '../../util/route.dart';
import '../../widget/chip_list.dart';

class _EditAutoTypeArgs extends PageRouteArgs {
  _EditAutoTypeArgs({super.key, required this.text});
  final String text;
}

class EditAutoTypeRoute extends PageRouteInfo<_EditAutoTypeArgs> {
  EditAutoTypeRoute({Key? key, required String text, KdbxEntry? kdbxEntry})
    : super(
        name,
        args: _EditAutoTypeArgs(key: key, text: text),
        rawPathParams: {"uuid": kdbxEntry?.uuid.string},
      );

  static const name = "EditAutoTypeRoute";

  static final PageInfo page = PageInfo.builder(
    name,
    builder: (context, data) {
      final args = data.argsAs<_EditAutoTypeArgs>(
        orElse: () => _EditAutoTypeArgs(text: ""),
      );

      final kdbx = KdbxProvider.of(context).kdbx!;
      final uuid = data.inheritedPathParams.optString("uuid")?.kdbxUuid;

      final kdbxEntry = uuid != null ? kdbx.findEntryByUuid(uuid) : null;

      return EditAutoTypePage(
        key: args.key,
        text: args.text,
        kdbxEntry: kdbxEntry,
      );
    },
  );
}

class EditAutoTypePage extends StatefulWidget {
  const EditAutoTypePage({super.key, required this.text, this.kdbxEntry});

  final String text;
  final KdbxEntry? kdbxEntry;

  @override
  State<EditAutoTypePage> createState() => _EditAutoTypePageState();
}

class _EditAutoTypePageState extends State<EditAutoTypePage> {
  late final RichTextController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = RichTextController(
      text: widget.text,
      onMatch: (_) {},
      targetMatches: [
        MatchTargetItem.pattern(
          AutoTypeRichPattern.BUTTON,
          allowInlineMatching: true,
          style: const TextStyle(color: Colors.blueAccent),
        ),
        MatchTargetItem.pattern(
          AutoTypeRichPattern.KDBX_KEY,
          allowInlineMatching: true,
          style: const TextStyle(color: Colors.green),
        ),
        MatchTargetItem.pattern(
          AutoTypeRichPattern.SHORTCUT_KEY,
          allowInlineMatching: true,
          style: const TextStyle(color: Colors.orangeAccent),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _insertTextAtCursor(String textToInsert) {
    final selection = _controller.selection;

    final start = selection.start == -1
        ? _controller.text.length
        : selection.start;

    final end = selection.end == -1 ? start : selection.end;

    _controller.text = _controller.text.replaceRange(start, end, textToInsert);

    _focusNode.requestFocus();

    /// 请求焦点时,会全选文本 !!!!
    /// 在下一帧移动光标到指定位置
    /// TODO! 可能会因为全选文本后又移动光标导致闪烁

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.selection = TextSelection.collapsed(
        offset: start + textToInsert.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    List<String> customFields = [];
    List<String> moreUrlsFields = [];

    if (widget.kdbxEntry != null) {
      customFields = widget.kdbxEntry!.customEntries;
      moreUrlsFields = widget.kdbxEntry!.moreUrlsKeys;
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.edit_auto_fill_sequence)),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextFormField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  title: Text(t.default_field),
                  subtitle: ChipList(
                    onChipTap: (item) => _insertTextAtCursor(item.value),
                    items: [
                      for (final item in [
                        ...KdbxKeyCommon.excludeURL,
                        KdbxKeyCommon.URL,
                        ...moreUrlsFields,
                      ])
                        ChipListItem(
                          value: "{$item}",
                          label: Text("{$item}"),
                        ),
                    ],
                  ),
                ),
                if (customFields.isNotEmpty)
                  ListTile(
                    title: Text(t.custom_field),
                    subtitle: ChipList(
                      onChipTap: (item) => _insertTextAtCursor(item.value),
                      items: [
                        for (final item in customFields)
                          ChipListItem(
                            value: "{S:$item}",
                            label: Text("{S:$item}"),
                          ),
                      ],
                    ),
                  ),
                ListTile(
                  title: Text(t.keyboard_key),
                  subtitle: ChipList(
                    onChipTap: (item) => _insertTextAtCursor(item.value),
                    items: [
                      for (final item in AutoTypeKeys.BUTTON)
                        ChipListItem(value: item, label: Text(item)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: const ValueKey("edit_auto_type_float"),
        onPressed: () {
          if (_controller.text != widget.text) {
            context.router.pop(_controller.text);
          } else {
            context.router.pop();
          }
        },
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(56 / 2)),
        ),
        child: const Icon(Icons.done),
      ),
    );
  }
}
