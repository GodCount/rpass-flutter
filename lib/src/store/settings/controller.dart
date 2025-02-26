import 'package:flutter/material.dart';

import '../index.dart';
import './service.dart';

class SettingsController with ChangeNotifier {
  late Store _store;

  final SettingsService _settingsService = SettingsService();

  late ThemeMode _themeMode;
  Locale? _locale;
  late bool _enableBiometric;
  Duration? _lockDelay;
  late bool _enableRecordKeyFilePath;
  String? _keyFilePath;

  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;
  bool get enableBiometric => _enableBiometric;
  Duration? get lockDelay => _lockDelay;
  bool get enableRecordKeyFilePath => _enableRecordKeyFilePath;
  String? get keyFilePath => _keyFilePath;

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

  Future<void> clear() async {
    await _settingsService.clear();
    await _store.loadStore();
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

  Future<void> init(Store store) async {
    _store = store;
    _themeMode = await _settingsService.getThemeMode();
    _locale = await _settingsService.getLocale();
    _enableBiometric = await _settingsService.getEnableBiometric();
    _lockDelay = await _settingsService.getLockDelay();
    _enableRecordKeyFilePath =
        await _settingsService.getEnableRecordKeyFilePath();
    _keyFilePath = await _settingsService.getKeyFilePath();

    notifyListeners();
  }
}
