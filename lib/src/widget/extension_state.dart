import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../i18n.dart';
import '../kdbx/kdbx.dart';
import '../page/page.dart';
import '../util/common.dart';
import '../util/file.dart';
import 'chip_list.dart';

extension StatefulClipboard on State {
  void writeClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((value) {
      showToast(I18n.of(context)!.copy_done);
    }, onError: (error) {
      showToast(error.toString());
    });
  }
}

extension StatefulDialog on State {
  Future<void> showAlert(String msg) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Text(msg),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(I18n.of(context)!.confirm),
            )
          ],
        );
      },
    );
  }

  Future<void> showToast(String msg) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await Fluttertoast.showToast(msg: msg);
    } else {
      await showAlert(msg);
    }
  }

  Future<bool> showConfirmDialog({
    required String title,
    required String message,
    String? cancel,
    String? confirm,
  }) async {
    final result = await showDialog(
      context: context,
      builder: (context) {
        final t = I18n.of(context)!;

        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(cancel ?? t.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(confirm ?? t.confirm),
            ),
          ],
        );
      },
    );
    return result is bool && result ? true : false;
  }
}

enum TimeLineNodeType { all, top, bottom, dot }

extension StateFulBottomSheet on State {
  void showBottomSheetList({
    String? title,
    required List<ListTile> children,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: [
            if (title != null)
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 6),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
            ...children,
          ],
        );
      },
    );
  }

  void showBinaryAction(ChipListItem<MapEntry<KdbxKey, KdbxBinary>> binary) {
    showBottomSheetList(title: binary.label, children: [
      ListTile(
        leading: const Icon(Icons.save),
        title: const Text("保存"),
        onTap: () async {
          try {
            final result = await SimpleFile.saveFile(
              data: binary.value.value.value,
              filename: binary.label,
            );
            showToast(result);
          } catch (e) {
            if (e is! CancelException) {
              // TODO! 处理异常
            }
          } finally {
            Navigator.of(context).pop();
          }
        },
      )
    ]);
  }

  void showKdbxGroupAction(
    String title, {
    GestureTapCallback? onManageTap,
    GestureTapCallback? onModifyTap,
    GestureTapCallback? onDeleteTap,
  }) {
    showBottomSheetList(
      title: title,
      children: [
        ListTile(
          leading: const Icon(Icons.manage_accounts_rounded),
          title: const Text("管理"),
          onTap: onManageTap != null
              ? () {
                  Navigator.of(context).pop();
                  onManageTap();
                }
              : null,
        ),
        ListTile(
          iconColor: Theme.of(context).colorScheme.primary,
          textColor: Theme.of(context).colorScheme.primary,
          leading: const Icon(Icons.edit),
          title: const Text("修改"),
          onTap: onModifyTap != null
              ? () {
                  Navigator.of(context).pop();
                  onModifyTap();
                }
              : null,
        ),
        ListTile(
          iconColor: Theme.of(context).colorScheme.error,
          textColor: Theme.of(context).colorScheme.error,
          leading: const Icon(Icons.delete),
          title: const Text("删除"),
          enabled: onDeleteTap != null,
          onTap: onDeleteTap != null
              ? () {
                  Navigator.of(context).pop();
                  onDeleteTap();
                }
              : null,
        ),
      ],
    );
  }

  void showEntryHistoryList(KdbxEntry kdbxEntry) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final history = kdbxEntry.history.reversed.toList();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 6),
                child: Text(
                  "时间线",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            history.isNotEmpty
                ? Expanded(
                    child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final entry = history[index];

                          TimeLineNodeType type = TimeLineNodeType.all;

                          if (history.length == 1) {
                            type = TimeLineNodeType.dot;
                          } else if (index == 0) {
                            type = TimeLineNodeType.bottom;
                          } else if (index == history.length - 1) {
                            type = TimeLineNodeType.top;
                          }

                          return ListTile(
                            leading: _timelineNode(type),
                            title: Card(
                              elevation: 4.0,
                              shape: const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(6.0)),
                              ),
                              child: InkWell(
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(6.0)),
                                onTap: () {
                                  Navigator.of(context).popAndPushNamed(
                                      LookAccountPage.routeName,
                                      arguments: entry);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    dateFormat(
                                      entry.times.lastModificationTime.get()!,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                  )
                : const Expanded(
                    child: Center(
                      child: Opacity(
                        opacity: .5,
                        child: Text("没有历史记录！"),
                      ),
                    ),
                  )
          ],
        );
      },
    );
  }

  Widget _timelineNode(TimeLineNodeType type) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (type != TimeLineNodeType.dot)
          Align(
            alignment: type == TimeLineNodeType.top
                ? const Alignment(0.0, -1.2)
                : type == TimeLineNodeType.bottom
                    ? const Alignment(0.0, 1.2)
                    : Alignment.center,
            widthFactor: 1,
            heightFactor: 2,
            child: FractionallySizedBox(
              heightFactor: type != TimeLineNodeType.all ? 0.5 : 1.2,
              child: Container(
                width: 4,
                color: Colors.amber,
              ),
            ),
          ),
        Container(
          width: 15,
          height: 15,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.amber,
          ),
        )
      ],
    );
  }
}

extension StatefulKdbx on State {
  String getKdbxObjectTitle(KdbxObject kdbxObject) {
    return kdbxObject is KdbxEntry
        ? kdbxObject.label ?? ''
        : kdbxObject is KdbxGroup
            ? kdbxObject.name.get() ?? ''
            : '';
  }

  Future<bool> kdbxSave(Kdbx kdbx) async {
    try {
      await kdbx.save();
      return true;
    } catch (e) {
      print(e);
      showToast(e.toString());
      // TODO! 记录异常
      return false;
    }
  }
}
