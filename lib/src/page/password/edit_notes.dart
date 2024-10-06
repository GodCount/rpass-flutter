import 'package:flutter/material.dart';

import '../../i18n.dart';

class EditNotesArgs {
  EditNotesArgs({required this.text, this.readOnly = false});

  final String text;
  final bool readOnly;
}

class EditNotes extends StatefulWidget {
  const EditNotes({super.key});

  static const routeName = "/edit_notes";

  @override
  State<EditNotes> createState() => _EditNotesState();
}

class _EditNotesState extends State<EditNotes> {
  String? _text;

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    final args = ModalRoute.of(context)!.settings.arguments as EditNotesArgs;

    return Scaffold(
      appBar: AppBar(
        title: Text(args.readOnly ? "查看备注" : "编辑备注"),
      ),
      body: Card(
        margin: const EdgeInsets.all(6),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(6.0)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 6, right: 6),
          child: TextFormField(
            autofocus: true,
            maxLines: null,
            minLines: 6,
            keyboardType: TextInputType.multiline,
            initialValue: args.text,
            readOnly: args.readOnly,
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _text != null
            ? () {
                Navigator.of(context).pop(_text);
              }
            : null,
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
