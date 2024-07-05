import 'package:flutter/material.dart';

import '../index.dart';
import './service.dart';

class SettingsController with ChangeNotifier {


  late Store _store;

  final SettingsService _settingsService = SettingsService();

  late ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode? mode) async {
    if (mode == null) return;

    if (mode == _themeMode) return;

    _themeMode = mode;

    notifyListeners();

    await _settingsService.setThemeMode(mode);
  }

  Future<void> clear() async {
    await _settingsService.clear();
    notifyListeners();
  }

  Future<void> init(Store store) async {
    _store = store;
    _themeMode = await _settingsService.getThemeMode();
    notifyListeners();
  }
}
