import 'package:flutter/material.dart';

typedef OnChipDeletedTap<T> = void Function(ChipListItem<T> item);
typedef OnChipTap<T> = void Function(ChipListItem<T> item);
typedef OnAddChipTap = void Function();

class ChipListItem<T> {
  ChipListItem({
    required this.value,
    required this.label,
    this.select = false,
    this.deletable = true,
  });

  T value;
  String label;

  bool select;
  bool deletable;
}

class ChipList<T> extends StatefulWidget {
  const ChipList({
    super.key,
    required this.items,
    this.onDeleted,
    this.onChipTap,
    this.onAddChipTap,
    this.maxHeight = double.infinity,
  });

  final List<ChipListItem<T>> items;
  final OnChipDeletedTap<T>? onDeleted;
  final OnChipTap<T>? onChipTap;
  final OnAddChipTap? onAddChipTap;
  final double maxHeight;

  @override
  State<ChipList<T>> createState() => _ChipListState<T>();
}

class _ChipListState<T> extends State<ChipList<T>> {
  @override
  Widget build(BuildContext context) {
    final children = widget.items
        .map((item) => ElevatedButton.icon(
              iconAlignment: IconAlignment.end,
              style: TextButton.styleFrom(
                padding: (item.deletable && widget.onDeleted != null)
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
                elevation: widget.onChipTap == null ? 0 : null,
                overlayColor:
                    widget.onChipTap == null ? Colors.transparent : null,
                enabledMouseCursor:
                    widget.onChipTap == null ? SystemMouseCursors.basic : null,
              ),
              onPressed: () {
                widget.onChipTap?.call(item);
              },
              label: Text(item.label),
              icon: (item.deletable && widget.onDeleted != null)
                  ? SizedBox(
                      height: 32,
                      width: 32,
                      child: IconButton(
                        iconSize: 16,
                        onPressed: () => widget.onDeleted!(item),
                        icon: const Icon(Icons.delete),
                      ),
                    )
                  : null,
            ))
        .toList();

    if (widget.onAddChipTap != null) {
      children.add(
        ElevatedButton(
          onPressed: widget.onAddChipTap,
          child: const Icon(Icons.add),
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: children,
        ),
      ),
    );
  }
}
