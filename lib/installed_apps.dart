import 'dart:io';

import 'package:flutter/services.dart';
import 'package:installed_apps/app_info.dart';

export 'app_info.dart';

/// A utility class for interacting with installed apps on the device.
class _AndroidInstalledAppsInstance extends InstalledAppsInstance {
  final MethodChannel _channel = const MethodChannel('installed_apps');

  /// Retrieves a list of installed apps on the device.
  ///
  /// Returns a list of [AppInfo] objects representing the installed apps.
  @override
  Future<List<AppInfo>> getInstalledApps([bool force = false]) async {
    return AppInfo.parseList(await _channel.invokeMethod("getInstalledApps", {
      "force": force,
    }));
  }

  @override
  Future<AppInfo?> getAppInfo(String packageName, {bool force = false}) async {
    return AppInfo.create(await _channel.invokeMethod("getAppInfo", {
      "packageName": packageName,
      "force": force,
    }));
  }

  @override
  Future<bool> startApp(String packageName) async {
    final result = await _channel.invokeMethod("startApp", {
      "packageName": packageName,
    });
    return result != null && result is bool ? result : false;
  }
}

class InstalledAppsInstance {
  static InstalledAppsInstance? _instance;

  static InstalledAppsInstance get instance {
    if (_instance != null) return _instance!;
    if (Platform.isAndroid) {
      _instance = _AndroidInstalledAppsInstance();
    } else {
      _instance = InstalledAppsInstance();
    }
    return _instance!;
  }

  Future<List<AppInfo>> getInstalledApps([bool force = false]) {
    throw UnimplementedError('getInstalledApps() has not been implemented.');
  }

  Future<AppInfo?> getAppInfo(String packageName, {bool force = false}) {
    throw UnimplementedError('getAppInfo() has not been implemented.');
  }

  Future<bool> startApp(String packageName) {
    throw UnimplementedError('startApp() has not been implemented.');
  }
}
