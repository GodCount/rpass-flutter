import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/rpass_localizations.dart';

typedef OnChangeCallback = void Function(List<String> labels);

class LabelItem {
  LabelItem({required this.value, this.select = false, this.newly = false});

  String value;
  bool select;
  bool newly;
}

class LabelList extends StatefulWidget {
  const LabelList({
    super.key,
    required this.items,
    this.preview = false,
    this.onChange,
  });

  final List<LabelItem> items;
  final OnChangeCallback? onChange;
  final bool preview;

  @override
  State<LabelList> createState() => _LabelListState();
}

class _LabelListState extends State<LabelList> {
  late final List<LabelItem> _items;

  void _update() {
    if (widget.onChange != null) {
      widget.onChange!(_items
          .where((item) => item.select)
          .map((item) => item.value)
          .toList());
    }

    setState(() {});
  }

  @override
  void initState() {
    _items = widget.items;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [];

    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (!widget.preview) {
        children.add(ElevatedButton.icon(
          iconAlignment: IconAlignment.end,
          style: TextButton.styleFrom(
            padding: item.newly
                ? const EdgeInsets.only(
                    top: 4,
                    right: 0,
                    bottom: 4,
                    left: 24,
                  )
                : null,
            side: item.select
                ? BorderSide(color: Theme.of(context).primaryColor)
                : null,
          ),
          onPressed: () {
            item.select = !item.select;
            _update();
          },
          label: Text(item.value),
          icon: item.newly
              ? SizedBox(
                  height: 32,
                  width: 32,
                  child: IconButton(
                    iconSize: 16,
                    onPressed: () {
                      _items.removeAt(i);
                      _update();
                    },
                    icon: const Icon(Icons.delete),
                  ),
                )
              : null,
        ));
      } else {
        children.add(
          Chip(
            padding: const EdgeInsets.only(top: 0, bottom: 0, left: 8.0, right: 8.0),
            shadowColor: Theme.of(context).shadowColor,
            side: BorderSide(color: Theme.of(context).primaryColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            label: Text(item.value),
          ),
        );
      }
    }

    if (!widget.preview) {
      children.add(
        ElevatedButton(
          onPressed: _addLabel,
          child: const Icon(Icons.add),
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: children,
    );
  }

  void _addLabel() {
    final t = RpassLocalizations.of(context)!;

    String label = "";
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t.label),
          content: TextField(
            autofocus: true,
            textInputAction: TextInputAction.done,
            onChanged: (value) {
              label = value;
            },
            decoration: InputDecoration(
              hintText: t.new_label,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(t.cancel),
            ),
            TextButton(
              onPressed: () {
                if (label.isNotEmpty &&
                    !_items.any((item) => item.value == label)) {
                  Navigator.of(context).pop();
                  _items
                      .add(LabelItem(value: label, select: true, newly: true));
                  _update();
                }
              },
              child: Text(t.add),
            ),
          ],
        );
      },
    );
  }
}
