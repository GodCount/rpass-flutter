import 'dart:io';

import 'package:tray_manager/tray_manager.dart';

import 'i18n.dart';
import 'rpass.dart';

enum SystemTrayIcon { lock, unlock }

class _SystemTray with TrayListener {
  Future<void> setIcon(SystemTrayIcon icon) async {
    final iconPath = switch (icon) {
      SystemTrayIcon.lock =>
        Platform.isMacOS
            ? "assets/icons/tray_lock.png"
            : "assets/icons/logo_lock.png",
      SystemTrayIcon.unlock =>
        Platform.isMacOS
            ? "assets/icons/tray_unlock.png"
            : "assets/icons/logo.png",
    };

    await trayManager.setIcon(iconPath, isTemplate: true);
  }

  Future<void> ensureInitialized() async {
    await setIcon(SystemTrayIcon.lock);
    await trayManager.setToolTip(RpassInfo.appName);
    await updateTrayMenu();
    trayManager.addListener(this);
  }

  Future<void> updateTrayMenu() async {
    final t = I18n.t!;
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(key: 'open', label: "打开"),
          MenuItem(key: 'lock', label: t.lock),
          MenuItem.separator(),
          MenuItem(key: 'quit', label: "退出", sublabel: "aaa"),
        ],
      ),
    );
  }

  @override
  void onTrayIconMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }
}

final systemTray = _SystemTray();
