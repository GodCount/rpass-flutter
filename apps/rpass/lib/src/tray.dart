import 'dart:io';

import 'package:tray_manager/tray_manager.dart';

import 'l10n/generated/localizations.dart';
import 'rpass.dart';
import 'util/common.dart';

enum SystemTrayIcon { lock, unlock }

class _SystemTray {
  Future<void> ensureInitialized() async {}

  Future<void> setIcon(SystemTrayIcon icon) async {}

  Future<void> updateTrayMenu(MyLocalizations t) async {}
}

class _DesktopSystemTray extends _SystemTray with TrayListener {
  @override
  Future<void> setIcon(SystemTrayIcon icon) async {
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
    await setIcon(SystemTrayIcon.lock);
    await trayManager.setToolTip(RpassInfo.appName);

    trayManager.addListener(this);
  }

  @override
  Future<void> updateTrayMenu(MyLocalizations t) async {
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(key: 'open', label: t.open),
          MenuItem(key: 'lock', label: t.lock),
          MenuItem.separator(),
          MenuItem(key: 'quit', label: t.quit),
        ],
      ),
    );
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu(bringAppToFront: true);
  }
}

final systemTray = kIsDesktop ? _DesktopSystemTray() : _SystemTray();
