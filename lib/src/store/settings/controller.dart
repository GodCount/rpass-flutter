import 'package:flutter/material.dart';

import './service.dart';

class SettingsController with ChangeNotifier {
  final SettingsService _settingsService = SettingsService();

  late ThemeMode _themeMode;
  Locale? _locale;
  late bool _enableBiometric;
  Duration? _lockDelay;
  late bool _enableRecordKeyFilePath;
  String? _keyFilePath;
  late bool _enableRemoteSync;

  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;
  bool get enableBiometric => _enableBiometric;
  Duration? get lockDelay => _lockDelay;
  bool get enableRecordKeyFilePath => _enableRecordKeyFilePath;
  String? get keyFilePath => _keyFilePath;
  bool get enableRemoteSync => _enableRemoteSync;

  Future<void> setThemeMode(ThemeMode? mode) async {
    if (mode == null) return;

    if (mode == _themeMode) return;

    _themeMode = mode;

    notifyListeners();

    await _settingsService.setThemeMode(mode);
  }

  Future<void> setLocale(Locale? locale) async {
    if (locale == _locale) return;

    _locale = locale;

    notifyListeners();

    await _settingsService.setLocale(locale);
  }

  Future<void> seEnableBiometric(bool enable) async {
    if (enable == _enableBiometric) return;

    _enableBiometric = enable;

    notifyListeners();

    await _settingsService.setEnableBiometric(enable);
  }

  Future<void> setLockDelay(Duration? delay) async {
    if (delay == _lockDelay) return;

    _lockDelay = delay;

    notifyListeners();

    await _settingsService.setLockDelay(delay);
  }

  Future<void> settEnableRecordKeyFilePath(bool enable) async {
    if (enable == _enableRecordKeyFilePath) return;

    _enableRecordKeyFilePath = enable;

    notifyListeners();

    await _settingsService.setEnableRecordKeyFilePath(enable);
  }

  Future<void> setKeyFilePath(String? path) async {
    if (path == _keyFilePath) return;

    _keyFilePath = path;

    notifyListeners();

    await _settingsService.setKeyFilePath(path);
  }

  Future<void> setEnableRemoteSync(bool enable) async {
    if (enable == _enableRemoteSync) return;

    _enableRemoteSync = enable;

    notifyListeners();

    await _settingsService.setEnableRemoteSync(enable);
  }

  Future<void> init() async {
    _themeMode = await _settingsService.getThemeMode();
    _locale = await _settingsService.getLocale();
    _enableBiometric = await _settingsService.getEnableBiometric();
    _lockDelay = await _settingsService.getLockDelay();
    _enableRecordKeyFilePath =
        await _settingsService.getEnableRecordKeyFilePath();
    _keyFilePath = await _settingsService.getKeyFilePath();
    _enableRemoteSync = await _settingsService.getEnableRemoteSync();

    notifyListeners();
  }
}
