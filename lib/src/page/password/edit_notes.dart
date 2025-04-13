import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../i18n.dart';
import '../../util/route.dart';

@Deprecated(
  '使用构造函数传参'
  '弃用 Arguments 路由传参',
)
class EditNotesArgs {
  EditNotesArgs({required this.text, this.readOnly = false});

  final String text;
  final bool readOnly;
}

class _EditNotesArgs extends PageRouteArgs {
  _EditNotesArgs({
    super.key,
    required this.text,
    this.readOnly = false,
  });
  final String text;
  final bool readOnly;
}

class EditNotesRoute extends PageRouteInfo<_EditNotesArgs> {
  EditNotesRoute({
    Key? key,
    required String text,
    bool readOnly = false,
  }) : super(
          name,
          args: _EditNotesArgs(
            key: key,
            text: text,
            readOnly: readOnly,
          ),
        );

  static const name = "EditNotesRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_EditNotesArgs>(
        orElse: () => _EditNotesArgs(
          text: "",
          readOnly: true,
        ),
      );
      return EditNotesPage(
        key: args.key,
        text: args.text,
        readOnly: args.readOnly,
      );
    },
  );
}

class EditNotesPage extends StatefulWidget {
  const EditNotesPage({
    super.key,
    required this.text,
    this.readOnly = false,
  });

  final String text;
  final bool readOnly;

  @override
  State<EditNotesPage> createState() => _EditNotesPageState();
}

class _EditNotesPageState extends State<EditNotesPage> {
  String? _text;

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.readOnly ? t.look_notes : t.edit_notes),
      ),
      body: Container(
        height: double.infinity,
        margin: const EdgeInsets.all(6),
        child: TextFormField(
          autofocus: true,
          maxLines: null,
          minLines: 6,
          keyboardType: TextInputType.multiline,
          initialValue: widget.text,
          readOnly: widget.readOnly,
          decoration: const InputDecoration(
            border: InputBorder.none,
          ),
          onChanged: (value) {
            if (_text == null) {
              setState(() {
                _text = value;
              });
            } else {
              _text = value;
            }
          },
        ),
      ),
      floatingActionButton: _text != null
          ? FloatingActionButton(
              heroTag: const ValueKey("edit_notes_float"),
              onPressed: () {
                context.router.pop(_text);
              },
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(56 / 2),
                ),
              ),
              child: const Icon(Icons.done),
            )
          : null,
    );
  }
}
