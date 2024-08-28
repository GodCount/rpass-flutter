import 'package:flutter/material.dart';

import '../index.dart';
import './service.dart';

class SettingsController with ChangeNotifier {
  late Store _store;

  final SettingsService _settingsService = SettingsService();

  late ThemeMode _themeMode;
  Locale? _locale;

  late bool _enableBiometric;

  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;
  bool get enableBiometric => _enableBiometric;

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

  Future<void> init(Store store) async {
    _store = store;
    _themeMode = await _settingsService.getThemeMode();
    _locale = await _settingsService.getLocale();
    _enableBiometric = await _settingsService.getEnableBiometric();
    notifyListeners();
  }
}
