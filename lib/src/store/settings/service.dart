import 'package:flutter/material.dart';

import '../shared_preferences/index.dart';

class SettingsService with SharedPreferencesService {
  Future<ThemeMode> getThemeMode() async {
    final mode = (await getInt("theme_mode")) ?? ThemeMode.system.index;
    return ThemeMode.values.firstWhere((m) => m.index == mode);
  }

  Future<bool> setThemeMode(ThemeMode mode) => setInt("theme_mode", mode.index);

  Future<Locale?> getLocale() async {
    final lang = await getString("locale");
    if (lang != null) {
      final codes = lang.split("_");
      return Locale(codes[0], codes.length > 1 ? codes[1] : null);
    }
    return null;
  }

  Future<bool> setLocale(Locale? locale) {
    if (locale != null) {
      return setString("locale", locale.toString());
    } else {
      return remove("locale");
    }
  }

  @override
  Future<bool> clear() => super.clear();
}
