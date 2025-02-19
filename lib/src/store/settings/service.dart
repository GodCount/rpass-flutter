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

  Future<bool> getEnableBiometric() async {
    return await getBool("enable_biometric") ?? false;
  }

  Future<bool> setEnableBiometric(bool enable) async {
    return await setBool("enable_biometric", enable);
  }

  Future<Duration?> getLockDelay() async {
    final delay = await getInt("lock_delay_seconds");
    return delay != null ? Duration(seconds: delay) : null;
  }

  Future<bool> setLockDelay(Duration? delay) async {
    if (delay != null) {
      return setInt("lock_delay_seconds", delay.inSeconds);
    } else {
      return remove("lock_delay_seconds");
    }
  }

  @override
  Future<bool> clear() => super.clear();
}
