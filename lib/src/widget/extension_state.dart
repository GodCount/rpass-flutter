import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logging/logging.dart';

import '../context/biometric.dart';
import '../context/kdbx.dart';
import '../i18n.dart';
import '../kdbx/kdbx.dart';
import '../page/route.dart';
import '../util/common.dart';
import '../util/file.dart';
import '../util/route.dart';
import 'chip_list.dart';
import 'common.dart';
import 'extension_state.dart';
import 'kdbx_history_list.dart';
import 'kdbx_icon.dart';

export "context_menu.dart";

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
  Future<void> showError(Object? error) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content:
              SelectableText(I18n.of(context)!.throw_message(error.toString())),
          actions: [
            TextButton(
              onPressed: () {
                context.router.pop();
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
      ));
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
                context.router.pop();
              },
              child: Text(cancel ?? t.cancel),
            ),
            TextButton(
              onPressed: () {
                context.router.pop(true);
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

  void showSearchHelpDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final t = I18n.of(context)!;

        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(t.search_rule),
                subtitle: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(t.rule_detail),
                ),
              ),
              ListTile(
                isThreeLine: true,
                title: Text(t.field_name),
                subtitle: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('title(t) url'),
                      const SizedBox(height: 6),
                      const Text('user(u) email(e)'),
                      const SizedBox(height: 6),
                      const Text('note(n) password(p)'),
                      const SizedBox(height: 6),
                      const Text('OTPAuth(otp) tag'),
                      const SizedBox(height: 6),
                      const Text('group(g)'),
                      const SizedBox(height: 6),
                      Text(t.custom_field),
                    ],
                  ),
                ),
              ),
              ListTile(
                isThreeLine: true,
                title: Text(t.search_eg),
                subtitle: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.search_eg_1),
                      const SizedBox(height: 6),
                      Text(t.search_eg_2),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.router.pop();
              },
              child: Text(t.confirm),
            ),
          ],
        );
      },
    );
  }
}

extension StatefulBottomSheet on State {
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
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 1,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
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
        title: Text(I18n.of(context)!.save),
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
            context.router.pop();
          }
        },
      )
    ]);
  }

  void showKdbxGroupAction(
    String title, {
    GestureTapCallback? onSearchTap,
    GestureTapCallback? onModifyTap,
    GestureTapCallback? onDeleteTap,
  }) {
    final t = I18n.of(context)!;
    showBottomSheetList(
      title: title,
      children: [
        ListTile(
          leading: const Icon(Icons.search),
          title: Text(t.search),
          onTap: onSearchTap != null
              ? () {
                  context.router.pop();
                  onSearchTap();
                }
              : null,
        ),
        ListTile(
          iconColor: Theme.of(context).colorScheme.primary,
          textColor: Theme.of(context).colorScheme.primary,
          leading: const Icon(Icons.edit),
          title: Text(t.modify),
          onTap: onModifyTap != null
              ? () {
                  context.router.pop();
                  onModifyTap();
                }
              : null,
        ),
        ListTile(
          iconColor: Theme.of(context).colorScheme.error,
          textColor: Theme.of(context).colorScheme.error,
          leading: const Icon(Icons.delete),
          title: Text(t.delete),
          enabled: onDeleteTap != null,
          onTap: onDeleteTap != null
              ? () {
                  context.router.pop();
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
        return KdbxHistoryList(
          kdbxEntry: kdbxEntry,
        );
      },
    );
  }

  Future<DateTime?> showDateTimePicker(
    BuildContext context, {
    DateTime? minimumDate,
    DateTime? maximumDate,
    DateTime? initialDateTime,
  }) async {
    if (initialDateTime != null &&
        minimumDate != null &&
        initialDateTime.isBefore(minimumDate)) {
      initialDateTime = minimumDate;
    }

    if (initialDateTime != null &&
        maximumDate != null &&
        initialDateTime.isAfter(maximumDate)) {
      initialDateTime = maximumDate;
    }

    final result = await showModalBottomSheet(
      context: context,
      builder: (context) {
        final t = I18n.of(context)!;

        DateTime? dateTime = initialDateTime;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, right: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(
                    width: 40,
                  ),
                  Text(
                    t.expires_time,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: () {
                      context.router.pop(dateTime);
                    },
                    icon: const Icon(Icons.done),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                minimumDate: minimumDate,
                maximumDate: maximumDate,
                initialDateTime: initialDateTime,
                dateOrder: DatePickerDateOrder.ymd,
                onDateTimeChanged: (value) {
                  dateTime = value;
                },
              ),
            )
          ],
        );
      },
    );
    return result is DateTime ? result : null;
  }
}

class KdbxGroupData {
  KdbxGroupData({
    required this.name,
    required this.notes,
    this.enableDisplay,
    this.enableSearching,
    required this.kdbxIcon,
    this.kdbxGroup,
  });

  String name;
  String notes;
  bool? enableDisplay;
  bool? enableSearching;
  KdbxIconWidgetData kdbxIcon;
  KdbxGroup? kdbxGroup;

  KdbxGroupData clone() {
    return KdbxGroupData(
      name: name,
      notes: notes,
      enableDisplay: enableDisplay,
      enableSearching: enableSearching,
      kdbxIcon: kdbxIcon,
      kdbxGroup: kdbxGroup,
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
      debugPrint("kdbxSave ${DateTime.now()}");
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

    kdbxGroup.name.set(data.name);

    kdbxGroup.notes.set(data.notes);

    kdbxGroup.enableDisplay.set(data.enableDisplay);

    kdbxGroup.enableSearching.set(data.enableSearching);

    if (data.kdbxIcon.customIcon != null) {
      kdbxGroup.customIcon = data.kdbxIcon.customIcon;
    } else if (data.kdbxIcon.icon != kdbxGroup.icon.get()) {
      kdbxGroup.icon.set(data.kdbxIcon.icon);
    }

    return await kdbxSave(kdbx);
  }

  Future<bool> setKdbxGroup(KdbxGroupData data) async {
    final result = await SetKdbxGroupDialog.openDialog(context, data);
    if (result is KdbxGroupData) {
      return _kdbxGroupSave(result);
    }
    return false;
  }

  Future<void> autoFill(KdbxEntry kdbxEntry, [KdbxKey? key]) async {
    try {
      await kdbxEntry.autoFill(key);
    } catch (e) {
      showError(e);
    }
  }
}

typedef OnDidChangeAppLifecycleState = void Function(AppLifecycleState state);

class CallbackBindingObserver extends WidgetsBindingObserver {
  CallbackBindingObserver({
    VoidCallback? didChangeMetrics,
    OnDidChangeAppLifecycleState? didChangeAppLifecycleState,
  })  : _didChangeMetrics = didChangeMetrics,
        _didChangeAppLifecycleState = didChangeAppLifecycleState;

  final VoidCallback? _didChangeMetrics;

  final OnDidChangeAppLifecycleState? _didChangeAppLifecycleState;

  @override
  void didChangeMetrics() {
    _didChangeMetrics?.call();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _didChangeAppLifecycleState?.call(state);
  }
}

abstract mixin class SrceenResizeObserver {
  void didSrceenSizeChange() {}

  void didCriticalChange({
    required bool oldIsIdeaSrceen,
    required bool oldIsSingleScreen,
  }) {}
}

class SrceenResize {
  SrceenResize._() {
    WidgetsBinding.instance.addObserver(_srceenObserver);
  }

  static final SrceenResize _instance = SrceenResize._();

  static SrceenResize get instance => _instance;

  static const double ideaSrceenWidth = 814;
  static const double singleSrceenWidth = 564;

  late Size srceenSize;
  bool isIdeaSrceen = false;
  bool isSingleScreen = false;

  late final _srceenObserver = CallbackBindingObserver(
    didChangeMetrics: _didChangeMetrics,
  );

  final List<SrceenResizeObserver> _observers = <SrceenResizeObserver>[];

  void _didChangeMetrics() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    srceenSize = view.physicalSize / view.devicePixelRatio;

    final oldIsIdeaSrceen = isIdeaSrceen;
    final oldIsSingleScreen = isSingleScreen;

    isIdeaSrceen = srceenSize.width > ideaSrceenWidth;
    isSingleScreen = srceenSize.width <= singleSrceenWidth;

    for (final SrceenResizeObserver observer in List<SrceenResizeObserver>.of(
      _observers,
    )) {
      observer.didSrceenSizeChange();

      if (oldIsIdeaSrceen != isIdeaSrceen ||
          oldIsSingleScreen != isSingleScreen) {
        observer.didCriticalChange(
          oldIsIdeaSrceen: oldIsIdeaSrceen,
          oldIsSingleScreen: oldIsSingleScreen,
        );
      }
    }
  }

  void addObserver(SrceenResizeObserver observer) {
    _observers.add(observer);
    if (_observers.length == 1) {
      _didChangeMetrics();
    }
  }

  bool removeObserver(SrceenResizeObserver observer) {
    return _observers.remove(observer);
  }
}

mixin SecondLevelRouteUtil<T extends StatefulWidget> on State<T>
    implements SrceenResizeObserver {
  bool isEmptyRouter = true;

  bool get isSingleScreen => SrceenResize.instance.isSingleScreen;
  bool get isIdeaSrceen => SrceenResize.instance.isIdeaSrceen;

  VoidCallback? _removeNavHistoryListener;

  @override
  void initState() {
    super.initState();
    SrceenResize.instance.addObserver(this);
    final navigationHistory = context.router.navigationHistory;
    navigationHistory.addListener(_navigationHistory);
    _removeNavHistoryListener =
        () => navigationHistory.removeListener(_navigationHistory);
  }

  void _navigationHistory() {
    if (context.router.currentPath.startsWith("/home")) {
      final isEmptyRouter = context.router.currentSegments.length <= 2 ||
          context.router.currentSegments.last.name == "EmptyPageRoute";

      if (this.isEmptyRouter != isEmptyRouter) {
        this.isEmptyRouter = isEmptyRouter;
        didEmptyRouteChange();
      }
    }
  }

  void didEmptyRouteChange() {}

  @override
  void didSrceenSizeChange() {}

  @override
  void didCriticalChange({
    required bool oldIsIdeaSrceen,
    required bool oldIsSingleScreen,
  }) {}

  @override
  void dispose() {
    SrceenResize.instance.removeObserver(this);
    _removeNavHistoryListener?.call();
    _removeNavHistoryListener = null;
    super.dispose();
  }
}

mixin NavigationHistoryObserver<T extends StatefulWidget> on State<T> {
  VoidCallback? _removeNavHistoryListener;

  @override
  void initState() {
    final navigationHistory = context.router.navigationHistory;
    navigationHistory.addListener(didNavigationHistory);
    _removeNavHistoryListener =
        () => navigationHistory.removeListener(didNavigationHistory);
    super.initState();
  }

  void didNavigationHistory() {}

  @override
  void dispose() {
    _removeNavHistoryListener?.call();
    _removeNavHistoryListener = null;
    super.dispose();
  }
}

mixin SecondLevelPageAutoBack<T extends StatefulWidget> on State<T>
    implements SrceenResizeObserver {
  bool get automaticallyImplyLeading =>
      !isDesktop || context.router.pageCount > 2;

  @override
  void initState() {
    if (isDesktop) {
      SrceenResize.instance.addObserver(this);
    }
    super.initState();
  }

  @override
  void dispose() {
    if (isDesktop) {
      SrceenResize.instance.removeObserver(this);
    }
    super.dispose();
  }

  @override
  didCriticalChange({
    required bool oldIsIdeaSrceen,
    required bool oldIsSingleScreen,
  }) {
    if (SrceenResize.instance.isSingleScreen != oldIsSingleScreen) {
      setState(() {});
    }
  }

  @override
  void didSrceenSizeChange() {}

  Widget? autoBack() {
    if (!isDesktop) return null;

    return SrceenResize.instance.isSingleScreen
        ? BackButton(onPressed: () {
            context.router.pop();
          })
        : null;
  }
}

extension PlatformStackRouter on StackRouter {
  void _updateTabs(StackRouter router) {
    if (this != router) {
      final parent = router.parent();

      if (parent != null &&
          parent is TabsRouter &&
          parent.stack[parent.activeIndex].routeKey != router.key) {
        final i =
            parent.stack.indexWhere((item) => item.routeKey == router.key);
        if (i != -1) {
          parent.setActiveIndex(i);
        }
      }
    }
  }

  Future<void> platformNavigate(
    PageRouteInfo<Object?> route, {
    OnNavigationFailure? onFailure,
  }) async {
    if (isDesktop) {
      final router = findStackScope(route);
      _updateTabs(router);
      await router.replaceAll(
        [
          const NamedRoute("EmptyPageRoute"),
          route,
        ],
        onFailure: onFailure,
      );
    } else {
      await push(route, onFailure: onFailure);
    }
  }
}

extension OperateConfirmVerifyOwner on State {
  Future<bool> operateConfirm() async {
    final bimetric = Biometric.of(context);
    if (bimetric.enable) {
      try {
        await bimetric.verifyOwner(context);
        return true;
      } catch (e) {
        return false;
      }
    } else {
      final result = await context.pushRoute(VerifyOwnerRoute(
        operateConfirm: true,
      ));
      return result != null && result is bool && result;
    }
  }
}
