import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logging/logging.dart';

import '../context/kdbx.dart';
import '../i18n.dart';
import '../kdbx/kdbx.dart';
import '../page/page.dart';
import '../util/common.dart';
import '../util/file.dart';
import 'chip_list.dart';
import 'common.dart';

final _logger = Logger("widget:extension_state");

extension StatefulClipboard on State {
  void writeClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((value) {
      showToast(I18n.of(context)!.copy_done);
    }, onError: (e) {
      showError(e);
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

  Future<void> showError(Object? error) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Text(I18n.of(context)!.throw_message(error.toString())),
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

  Future<KdbxGroup?> showGroupSelectorDialog(KdbxGroup? kdbxGroup) {
    return GroupSelectorDialog.openDialog(context, value: kdbxGroup);
  }
}

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
              _logger.warning("save as attachment fail!", e);
              showError(e);
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
                    child: TimeLineListWidget(
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final entry = history[index];
                          return Card(
                            elevation: 4.0,
                            margin: const EdgeInsets.only(left: 12, right: 12),
                            shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(6.0)),
                            ),
                            child: InkWell(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(6.0)),
                              onTap: () {
                                Navigator.of(context).popAndPushNamed(
                                  LookAccountPage.routeName,
                                  arguments: entry,
                                );
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
}

class KdbxGroupData {
  KdbxGroupData({
    required this.name,
    required this.kdbxIcon,
    this.kdbxGroup,
  });

  String name;
  KdbxIconWidgetData kdbxIcon;
  KdbxGroup? kdbxGroup;
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
    } catch (e, s) {
      _logger.severe("kdbx save fail!", e, s);
      showError(e);
      return false;
    }
  }

  Future<bool> _kdbxGroupSave(KdbxGroupData data) async {
    final kdbx = KdbxProvider.of(context)!;

    final kdbxGroup = data.kdbxGroup ?? kdbx.createGroup(data.name);

    if (data.name != kdbxGroup.name.get()) {
      kdbxGroup.name.set(data.name);
    }

    if (data.kdbxIcon.customIcon != null) {
      kdbxGroup.customIcon = data.kdbxIcon.customIcon;
    } else if (data.kdbxIcon.icon != kdbxGroup.icon.get()) {
      kdbxGroup.icon.set(data.kdbxIcon.icon);
    }

    return await kdbxSave(kdbx);
  }

  Future<bool> setKdbxGroup(KdbxGroupData data) async {
    final kdbx = KdbxProvider.of(context)!;

    final result = await InputDialog.openDialog(
      context,
      title: data.kdbxGroup != null ? "修改" : "新建",
      label: "名称",
      initialValue: data.name,
      limitItems: kdbx.rootGroups
          .map((item) => item.name.get() ?? '')
          .where((item) => item.isNotEmpty && item != data.name)
          .toSet()
          .toList(),
      leadingBuilder: (state) {
        return IconButton(
          onPressed: () async {
            final reslut =
                await Navigator.of(context).pushNamed(SelectIconPage.routeName);
            if (reslut != null && reslut is KdbxIconWidgetData) {
              data.kdbxIcon = reslut;
              state.update();
            }
          },
          icon: KdbxIconWidget(
            kdbxIcon: data.kdbxIcon,
            size: 24,
          ),
        );
      },
    );
    if (result is String) {
      data.name = result;
      return _kdbxGroupSave(data);
    }
    return false;
  }
}
