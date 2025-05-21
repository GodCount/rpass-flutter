import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:rich_text_controller/rich_text_controller.dart';

import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../util/route.dart';
import '../../widget/chip_list.dart';

class _EditAutoTypeArgs extends PageRouteArgs {
  _EditAutoTypeArgs({
    super.key,
    required this.text,
    this.kdbxEntry,
  });
  final String text;
  final KdbxEntry? kdbxEntry;
}

class EditAutoTypeRoute extends PageRouteInfo<_EditAutoTypeArgs> {
  EditAutoTypeRoute({
    Key? key,
    required String text,
    KdbxEntry? kdbxEntry,
  }) : super(
          name,
          args: _EditAutoTypeArgs(
            key: key,
            text: text,
            kdbxEntry: kdbxEntry,
          ),
        );

  static const name = "EditAutoTypeRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_EditAutoTypeArgs>(
        orElse: () => _EditAutoTypeArgs(
          text: "",
        ),
      );
      return EditAutoTypePage(
        key: args.key,
        text: args.text,
        kdbxEntry: args.kdbxEntry,
      );
    },
  );
}

class EditAutoTypePage extends StatefulWidget {
  const EditAutoTypePage({
    super.key,
    required this.text,
    this.kdbxEntry,
  });

  final String text;
  final KdbxEntry? kdbxEntry;

  @override
  State<EditAutoTypePage> createState() => _EditAutoTypePageState();
}

class _EditAutoTypePageState extends State<EditAutoTypePage> {
  RichTextController? _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _insertTextAtCursor(String textToInsert) {
    final selection = _controller!.selection;

    final start =
        selection.start == -1 ? _controller!.text.length : selection.start;

    final end = selection.end == -1 ? start : selection.end;

    _controller!.text = _controller!.text.replaceRange(
      start,
      end,
      textToInsert,
    );

    _focusNode.requestFocus();

    /// 请求焦点时,会全选文本 !!!!
    /// 在下一帧移动光标到指定位置
    /// TODO! 可能会因为全选文本后又移动光标导致闪烁

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller!.selection = TextSelection.collapsed(
        offset: start + textToInsert.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    _controller ??= RichTextController(
      text: widget.text,
      onMatch: (_) {},
      targetMatches: [
        MatchTargetItem.pattern(
          AutoTypeRichPattern.BUTTON,
          allowInlineMatching: true,
          style: Theme.of(context)
              .textTheme
              .bodyLarge!
              .copyWith(color: Colors.blueAccent),
        ),
        MatchTargetItem.pattern(
          AutoTypeRichPattern.KDBX_KEY,
          allowInlineMatching: true,
          style: Theme.of(context)
              .textTheme
              .bodyLarge!
              .copyWith(color: Colors.green),
        ),
        MatchTargetItem.pattern(
          AutoTypeRichPattern.SHORTCUT_KEY,
          allowInlineMatching: true,
          style: Theme.of(context)
              .textTheme
              .bodyLarge!
              .copyWith(color: Colors.orangeAccent),
        )
      ],
    );

    List<String> customFields = [];

    if (widget.kdbxEntry != null) {
      customFields = widget.kdbxEntry!.stringEntries
          .where((item) => !defaultKdbxKeys.contains(item.key))
          .map((item) => item.key.key)
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        // TODO! 翻译
        title: Text("编辑自动填充序列"),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextFormField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  title: Text("默认字段"),
                  subtitle: ChipList(
                    onChipTap: (item) => _insertTextAtCursor(item.value),
                    items: KdbxKeyCommon.all
                        .map((item) => ChipListItem(
                              label: "{${item.key}}",
                              value: "{${item.key}}",
                            ))
                        .toList(),
                  ),
                ),
                if (customFields.isNotEmpty)
                  ListTile(
                    title: Text("自定义字段"),
                    subtitle: ChipList(
                      onChipTap: (item) => _insertTextAtCursor(item.value),
                      items: customFields
                          .map((item) => ChipListItem(
                                label: "{S:$item}",
                                value: "{S:$item}",
                              ))
                          .toList(),
                    ),
                  ),
                ListTile(
                  title: Text("键盘键"),
                  subtitle: ChipList(
                    onChipTap: (item) => _insertTextAtCursor(item.value),
                    items: AutoTypeKeys.BUTTON
                        .map((item) => ChipListItem(
                              label: item,
                              value: item,
                            ))
                        .toList(),
                  ),
                )
              ],
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: const ValueKey("edit_auto_type_float"),
        onPressed: () {
          if (_controller!.text != widget.text) {
            context.router.pop(_controller!.text);
          } else {
            context.router.pop();
          }
        },
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(56 / 2),
          ),
        ),
        child: const Icon(Icons.done),
      ),
    );
  }
}
