import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keepass_core/keepass_core.dart';
import 'package:logging/logging.dart';

import '../context/biometric.dart';
import '../context/lan_fill_server.dart';
import '../i18n.dart';
import '../kdbx/auto_fill.dart';
import '../kdbx/kdbx.dart';
import '../page/kdbx/edit_group_page.dart';
import '../page/route.dart';
import '../store/index.dart';
import '../theme/theme.dart';
import '../util/common.dart';
import '../util/file.dart';
import '../util/route.dart';
import 'chip_list.dart';
import 'common.dart';
import 'extension_state.dart';
import 'kdbx_history_list.dart';

export "context_menu.dart";

final _logger = Logger("widget:extension_state");

extension StatefulClipboard on State {
  void writeClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text)).then(
      (value) {
        showToast(I18n.of(context)!.copy_done);
      },
      onError: (e) {
        showError(e);
      },
    );
  }
}

extension StatefulDialog on State {
  Future<void> showError(Object error, [StackTrace? s]) async {
    String message;

    if (error is KdbxError) {
      message = "${error.runtimeType}(${error.message})";
      if (kDebugMode) {
        message += "\nRust StackTrace: ${error.backtrace}";
      }
    } else {
      message = error.toString();
    }

    if (s != null && kDebugMode) {
      message += "\nDart StackTrace: $s";
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: SelectableText(I18n.of(context)!.throw_message(message)),
          actions: [
            TextButton(
              onPressed: () {
                context.router.pop();
              },
              child: Text(I18n.of(context)!.confirm),
            ),
          ],
        );
      },
    );
  }

  Future<void> showToast(String msg) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  Future<bool> showConfirmDialog({
    required String title,
    required String message,
    bool dismissible = true,
    String? cancel,
    String? confirm,
  }) async {
    final result = await showDialog(
      context: context,
      barrierDismissible: dismissible,
      builder: (context) {
        final t = I18n.of(context)!;

        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            if (dismissible || cancel != null)
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

  Future<GroupData?> showGroupSelectorDialog({
    String? groupId,
    GroupData? groupData,
    bool? noRoot,
  }) {
    return GroupSelectorDialog.openDialog(
      context,
      value: groupData?.id ?? groupId,
      noRoot: noRoot,
    );
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
                    spacing: 6,
                    children: [
                      const Text('title(t) url[1-5]'),
                      const Text('user(u) email(e)'),
                      const Text('note(n) password(p)'),
                      const Text('OTPAuth(otp) tag'),
                      const Text('group(g)'),
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
                    spacing: 6,
                    children: [Text(t.search_eg_1), Text(t.search_eg_2)],
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

  Future<Color?> showSelectorSeedColor({Color? color, bool? empty}) async {
    final currentColor = color;
    final result = await showDialog(
      context: context,
      builder: (context) {
        final t = I18n.of(context)!;

        return AlertDialog(
          title: Text(t.seed_color),
          content: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final color in [
                ...availableColors,
                if (empty == true) Colors.transparent,
              ])
                GestureDetector(
                  onTap: () => context.router.pop(
                    color != Colors.transparent ? color : null,
                  ),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(32),
                      border: color == Colors.transparent
                          ? Border.all(color: Colors.black45)
                          : null,
                    ),
                    child:
                        color == currentColor ||
                            (currentColor == null &&
                                color == Colors.transparent)
                        ? Center(
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          )
                        : null,
                  ),
                ),
            ],
          ),
        );
      },
    );
    return result is Color ? result : null;
  }
}

extension StatefulBottomSheet on State {
  void showBottomSheetList({
    String? title,
    List<Widget>? actions,
    required List<Widget> children,
    Widget? emptyPlaceholder,
  }) {
    showBottomSheetView(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              primary: true,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: title != null ? Text(title) : null,
              titleTextStyle: Theme.of(context).textTheme.titleLarge,
              actionsPadding: const EdgeInsets.only(right: 16),
              actions: actions,
            ),
            if (emptyPlaceholder != null)
              Expanded(
                child: children.isNotEmpty
                    ? ListView(shrinkWrap: true, children: children)
                    : emptyPlaceholder,
              ),
            if (emptyPlaceholder == null)
              ListView(shrinkWrap: true, children: children),
          ],
        );
      },
    );
  }

  void showBinaryAction(ChipListItem<Attachment> binary) {
    final t = I18n.of(context)!;
    final lanFill = LanFillInherited.of(context);
    final kdbxProvider = Store.kdbx;

    final title = binary.value.name;

    showBottomSheetList(
      title: title,
      children: [
        ListTile(
          leading: const Icon(Icons.save),
          title: Text(t.save),
          onTap: () async {
            try {
              final data =
                  binary.value.data ??
                  await kdbxProvider.kdbx!.getAttachment(id: binary.value.id);
              final result = await SimpleFile.saveFile(
                data: data,
                filename: title,
              );
              showToast(result);
            } catch (e, s) {
              if (e is! CancelException) {
                _logger.warning("save as attachment fail!", e, s);
                showError(e, s);
              }
            } finally {
              context.router.pop();
            }
          },
        ),
        if (kIsMobile)
          ListTile(
            enabled: lanFill != null,
            title: Text(t.lan_transfer),
            leading: Icon(
              lanFill?.cilentConnecting == true
                  ? Icons.connect_without_contact_rounded
                  : Icons.cast_connected,
            ),
            onTap: () async {
              context.router.pop();
              try {
                final data =
                    binary.value.data ??
                    await kdbxProvider.kdbx!.getAttachment(id: binary.value.id);
                lanFill?.updateFile(title, data);
              } catch (e, s) {
                showError(e, s);
              }
            },
          ),
      ],
    );
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

  void showEntryHistoryList(EntryData kdbxEntry) {
    showBottomSheetView(
      context: context,
      builder: (context) {
        return KdbxHistoryList(kdbxEntry: kdbxEntry);
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

    final result = await showBottomSheetView(
      context: context,
      builder: (context) {
        final t = I18n.of(context)!;

        DateTime? dateTime = initialDateTime;

        return Column(
          mainAxisSize: .min,
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              primary: true,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Text(t.expires_time),
              titleTextStyle: Theme.of(context).textTheme.titleLarge,
              actionsPadding: const EdgeInsets.only(right: 16),
              actions: [
                IconButton(
                  onPressed: () {
                    context.router.pop(dateTime);
                  },
                  icon: const Icon(Icons.done),
                ),
              ],
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
            ),
          ],
        );
      },
    );
    return result is DateTime ? result : null;
  }
}

typedef SingleTriggerFunc<T> = T Function();

extension StatefulKdbx on State {
  Future<bool> kdbxAction(KdbxAction action) async {
    return kdbxActions([action]);
  }

  Future<bool> kdbxActions(List<KdbxAction> actions) async {
    final kdbx = Store.kdbx.kdbx;
    if (kdbx != null) {
      try {
        await kdbx.actions(actions: actions);
        return true;
      } catch (e, s) {
        showError(e, s);
      }
    }
    return false;
  }

  SingleTriggerFunc<void> singleTrigger<T>(
    SingleTriggerFunc<FutureOr<T>> callback,
  ) {
    bool trigger = false;
    return () async {
      if (trigger) return;
      try {
        trigger = true;
        final completer = Completer();
        completer.complete(callback());
        return await completer.future;
      } finally {
        trigger = false;
      }
    };
  }

  void autoFill(String id, [String? key]) async {
    final kdbx = Store.kdbx.kdbx;

    if (kdbx == null) return;

    try {
      final (entry, sequence) = await kdbx.getAutoTypeSequence(id: id);
      return autoFillSequence(
        sequence,
        key: key,
        getValue: (key) => entry.getActualString(key),
      );
    } catch (e, s) {
      showError(e, s);
    }
  }

  Future<Object?> addKdbxGroup() async {
    if (isDesktop) {
      return await showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            clipBehavior: Clip.antiAlias,
            shape: Theme.of(context).dialogTheme.shape,
            constraints: BoxConstraints(maxWidth: 375, maxHeight: 600),
            child: EditGroupPagePage(),
          );
        },
      );
    } else {
      return await context.router.push(EditGroupPageRoute());
    }
  }
}

typedef OnDidChangeAppLifecycleState = void Function(AppLifecycleState state);

class CallbackBindingObserver extends WidgetsBindingObserver {
  CallbackBindingObserver({
    VoidCallback? didChangeMetrics,
    OnDidChangeAppLifecycleState? didChangeAppLifecycleState,
  }) : _didChangeMetrics = didChangeMetrics,
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
    _removeNavHistoryListener = () =>
        navigationHistory.removeListener(_navigationHistory);
  }

  void _navigationHistory() {
    if (context.router.currentPath.startsWith("/home")) {
      final isEmptyRouter = context.router.currentSegments.length == 2;

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
    _removeNavHistoryListener = () =>
        navigationHistory.removeListener(didNavigationHistory);
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
      !isDesktop || context.router.pageCount > 1;

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
        ? BackButton(
            onPressed: () {
              context.router.pop();
            },
          )
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
        final i = parent.stack.indexWhere(
          (item) => item.routeKey == router.key,
        );
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
      await router.replaceAll([route], onFailure: onFailure);
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
      final result = await context.pushRoute(
        VerifyOwnerRoute(operateConfirm: true),
      );
      return result != null && result is bool && result;
    }
  }
}
