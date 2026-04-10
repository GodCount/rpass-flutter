import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:common_native_channel/common_native_channel.dart';
import 'package:enigo_flutter/enigo_flutter.dart';
import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:logging/logging.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../context/kdbx.dart';
import '../context/lan_fill_server.dart';
import '../i18n.dart';
import '../kdbx/kdbx.dart';
import '../native/channel.dart';
import '../native/platform/android.dart';
import '../store/index.dart';
import '../store/settings/shortcuts.dart';
import '../tray.dart';
import '../util/common.dart';
import '../util/route.dart';
import '../widget/common.dart';
import 'auth_kdbx/load_page.dart';
import 'auth_kdbx/verify_owner_page.dart';

final _logger = Logger("page:root");

class _RootRpassAppArgs extends PageRouteArgs {
  _RootRpassAppArgs({super.key});
}

class RootRpassAppRoute extends PageRouteInfo<_RootRpassAppArgs> {
  RootRpassAppRoute({Key? key})
    : super(name, args: _RootRpassAppArgs(key: key));

  static const name = "RootRpassAppRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_RootRpassAppArgs>(
        orElse: () => _RootRpassAppArgs(),
      );
      return RootRpassApp(key: args.key);
    },
  );
}

class RootRpassApp extends StatefulWidget {
  const RootRpassApp({super.key});

  // final Widget child;

  @override
  State<RootRpassApp> createState() => _RootRpassAppState();
}

class _RootRpassAppState extends State<RootRpassApp>
    with
        WindowListener,
        TrayListener,
        KdbxProviderListener,
        _BackgroundLock,
        NativeChannelListener {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _locale = Store.instance.settings.locale;

    windowManager.addListener(this);
    trayManager.addListener(this);
    KdbxProvider.of(context).addListener(this);
    Store.instance.settings.addListener(_settingsListener);
    Store.instance.settings.shortcutsStore.addListener(_hotKeyHandler);
    NativeInstancePlatform.instance.addListener(this);

    _updateTrayMenu();
  }

  void _updateTrayMenu() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      systemTray.updateTrayMenu(I18n.of(context)!);
    });
  }

  void _settingsListener() {
    if (_locale != Store.instance.settings.locale) {
      _locale = Store.instance.settings.locale;
      _updateTrayMenu();
    }
  }

  void _hotKeyHandler(HotKey hotKey, ShortcutsTrigger trigger) async {
    final kdbxProvider = KdbxProvider.of(context);
    switch (hotKey.identifier) {
      case "open":
        {
          await windowManager.setSkipTaskbar(true);
          if (await windowManager.isFocused()) {
            await windowManager.hide();
            // 返还焦点,忽略异常
            unawaited(prevFocusWindow.activatePrevWindow());
          } else {
            final alignment = Store
                .instance
                .settings
                .shortcutsStore
                .shortcutsOpenAppAlignment;

            switch (alignment) {
              case ShortcutsOpenAppAlignment.mouse:
                {
                  final location = enigo.location();
                  await windowManager.setPosition(
                    Offset(location.$1.toDouble(), location.$2.toDouble()),
                  );
                  windowManager.show(inactive: true);
                }
                break;
              case ShortcutsOpenAppAlignment.mouseCenter:
                {
                  final location = enigo.location();
                  final size = await windowManager.getSize();
                  await windowManager.setPosition(
                    Offset(
                      location.$1 - (size.width / 2),
                      location.$2 - (size.height / 2),
                    ),
                  );
                  windowManager.show(inactive: true);
                }
                break;
              case ShortcutsOpenAppAlignment.mouseScreenCenter:
                {
                  final location = enigo.location();
                  await windowManager.setPosition(
                    Offset(location.$1.toDouble(), location.$2.toDouble()),
                  );
                  await windowManager.center();
                  windowManager.show(inactive: true);
                }
                break;
              case ShortcutsOpenAppAlignment.prev:
                windowManager.show(inactive: true);
                break;
            }
          }
        }
        break;
      case "lock":
        {
          if (kdbxProvider.kdbx != null) {
            kdbxProvider.setKdbx(null);
            context.router.replaceAll([LoadKdbxRoute()]);
            cancelBackgroundLockTimer();
          }
        }
        break;
      case "autofill":
        {
          if (kdbxProvider.selectedKdbxEntry != null) {
            await Future.delayed(const Duration(milliseconds: 500));
            kdbxProvider.selectedKdbxEntry!.autoFill();
          }
        }
        break;
      default:
        {
          if (hotKey.identifier.startsWith("autofill_")) {
            final key = hotKey.identifier.split("_")[1];

            if (kdbxProvider.selectedKdbxEntry != null) {
              await Future.delayed(const Duration(milliseconds: 500));
              kdbxProvider.selectedKdbxEntry!.autoFill(KdbxKey(key));
            }
          }
        }
        break;
    }
  }

  @override
  void onKdbxChanged(Kdbx? kdbx) {
    systemTray.setIcon(
      kdbx != null ? SystemTrayIcon.unlock : SystemTrayIcon.lock,
    );
  }

  @override
  void onSelectedKdbxEntryChanged(KdbxEntry? kdbxEntry) {}

  @override
  void onTrayIconMouseDown() {
    windowManager.setSkipTaskbar(false);
    windowManager.show(inactive: true);
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    final kdbxProvider = KdbxProvider.of(context);

    switch (menuItem.key) {
      case "lock":
        {
          if (kdbxProvider.kdbx != null) {
            kdbxProvider.setKdbx(null);
            context.router.replaceAll([LoadKdbxRoute()]);
            cancelBackgroundLockTimer();
          }
        }
        break;
      case "open":
        windowManager.setSkipTaskbar(false);
        windowManager.show(inactive: true);
        break;
      case "quit":
        windowManager.destroy();
        break;
    }
  }

  @override
  void onWindowClose() {
    windowManager.hide();
  }

  @override
  void onRequestAutofill(AutofillMetadata metadata) async {
    final kdbx = KdbxProvider.of(context).kdbx;

    if (kdbx != null) {
      List<AutofillDataset> result = await kdbx.autofillSearch(metadata);

      if (result.isEmpty && Store.instance.settings.manualSelectFillItem) {
        final kdbxEntry = await KdbxEntrySelectorDialog.openDialog(context);
        final dataset = kdbxEntry?.toAutofillDataset(metadata.fieldTypes);

        if (dataset != null) result.add(dataset);
      }

      await NativeInstancePlatform.instance.autofillService.responseDataset(
        result,
      );
    } else {
      await NativeInstancePlatform.instance.autofillService.responseDataset(
        null,
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    KdbxProvider.of(context).removeListener(this);
    Store.instance.settings.removeListener(_settingsListener);
    Store.instance.settings.shortcutsStore.removeListener(_hotKeyHandler);
    NativeInstancePlatform.instance.removeListener(this);
  }

  @override
  Widget build(BuildContext context) {
    return LanFillServerProvider(child: AutoRouter());
  }
}

class _CallbackWindowListener with WindowListener {
  _CallbackWindowListener(this._onWindowEvent);

  final ValueChanged<String> _onWindowEvent;

  @override
  void onWindowEvent(String eventName) {
    _onWindowEvent(eventName);
  }
}

// 后台触发锁定
mixin _BackgroundLock on State<RootRpassApp> {
  VoidCallback? _dispose;

  SimpleTimestampTimer? _timerVerifyOwner;
  SimpleTimestampTimer? _timerLockKdbx;

  bool _isVerifyOwnerRoute = false;

  @override
  void initState() {
    super.initState();

    if (kIsMobile) {
      final appLifecycleListener = AppLifecycleListener(
        onPause: _start,
        onResume: _cancel,
      );
      _dispose = appLifecycleListener.dispose;
    } else if (kIsDesktop) {
      final windowListener = _CallbackWindowListener(_onWindowEvent);
      windowManager.addListener(windowListener);
      _dispose = () => windowManager.removeListener(windowListener);
    }
  }

  void cancelBackgroundLockTimer() {
    _cancel();
  }

  void _onWindowEvent(String eventName) async {

    if (Platform.isMacOS && eventName == "blur") {
      // macos 下不存在 hide 事件, 只有 win 才有
      // 修复 在mac下面执行 windowManager.hide() 后回调到这里拿到的 isVisible 可能不准确
      // 判断可能 hide 操作是有延迟
      await Future.delayed(const Duration(milliseconds: 60));
      eventName = (!await windowManager.isVisible()) ? "hide" : "blur";
    }

    if (eventName == "minimize" || eventName == "hide") {
      _start();
    } else if (eventName == "focus") {
      _cancel();
    }
  }

  void _start() {
    _cancel();

    final kdbx = KdbxProvider.of(context).kdbx;
    if (kdbx == null) return;

    final lockDelay = Store.instance.settings.lockDelay;
    if (lockDelay == null) return;

    _timerVerifyOwner = SimpleTimestampTimer(lockDelay, _runTimerVerifyOwner);
  }

  void _runTimerVerifyOwner() async {
    _timerVerifyOwner?.cancel();
    _timerVerifyOwner = null;

    if (!_isVerifyOwnerRoute) {
      _isVerifyOwnerRoute = true;
      context.router
          .push(VerifyOwnerRoute())
          .whenComplete(() => _isVerifyOwnerRoute = false);
    }

    final lockDelay = Store.instance.settings.lockDelay;
    if (lockDelay == null) return;
    _timerLockKdbx = SimpleTimestampTimer(lockDelay, _runTimerLockKdbx);
  }

  void _runTimerLockKdbx() {

    _timerLockKdbx?.cancel();
    _timerLockKdbx = null;
    _isVerifyOwnerRoute = false;
    KdbxProvider.of(context).setKdbx(null);
    context.router.replaceAll([LoadKdbxRoute()]);
  }

  void _cancel() {
    if (_timerVerifyOwner != null) {
      _timerVerifyOwner!.cancel();
      _timerVerifyOwner = null;
    }

    if (_timerLockKdbx != null) {
      _timerLockKdbx!.cancel();
      _timerLockKdbx = null;
    }
  }

  @override
  void dispose() {
    super.dispose();
    _cancel();
    _dispose?.call();
    _dispose = null;
  }
}
