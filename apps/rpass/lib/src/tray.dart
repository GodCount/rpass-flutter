import 'dart:io';

import 'package:tray_manager/tray_manager.dart';

import 'l10n/generated/localizations.dart';
import 'rpass.dart';
import 'util/common.dart';

enum SystemTrayIcon { lock, unlock }

class _SystemTray {
  Future<void> ensureInitialized() async {}

  Future<void> updateTrayMenu(
    MyLocalizations t, {
    bool lock = true,
    bool lanFillServer = false,
  }) async {}
}

class _DesktopSystemTray extends _SystemTray with TrayListener {
  Future<void> _setIcon(SystemTrayIcon icon) async {
    final iconPath = switch (icon) {
      SystemTrayIcon.lock =>
        Platform.isMacOS
            ? "assets/icons/tray_lock.png"
            : "assets/icons/tray_lock.ico",
      SystemTrayIcon.unlock =>
        Platform.isMacOS
            ? "assets/icons/tray_unlock.png"
            : "assets/icons/tray_unlock.ico",
    };

    await trayManager.setIcon(iconPath, isTemplate: true);
  }

  @override
  Future<void> ensureInitialized() async {
    await _setIcon(SystemTrayIcon.lock);
    await trayManager.setToolTip(RpassInfo.appName);

    trayManager.addListener(this);
  }

  @override
  Future<void> updateTrayMenu(
    MyLocalizations t, {
    bool lock = true,
    bool lanFillServer = false,
  }) async {
    final List<MenuItem> items = [
      MenuItem(key: 'lock', label: lock ? t.locked : t.lock, disabled: lock),
      lanFillServer
          ? MenuItem(key: 'close_lan_fill', label: t.close_lan_fill)
          : MenuItem(key: 'lan_fill', label: t.lan_fill),
      MenuItem.separator(),
      MenuItem(key: 'quit', label: t.quit),
    ];

    await _setIcon(lock ? .lock : .unlock);

    await trayManager.setContextMenu(Menu(items: items));
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu(bringAppToFront: true);
  }
}

final systemTray = kIsDesktop ? _DesktopSystemTray() : _SystemTray();
