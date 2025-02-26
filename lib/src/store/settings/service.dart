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
    // 默认值 30秒
    // 小于0则表示永不
    return delay == null || delay > 0 ? Duration(seconds: delay ?? 30) : null;
  }

  Future<bool> setLockDelay(Duration? delay) async {
    return setInt("lock_delay_seconds", delay != null ? delay.inSeconds : -1);
  }

  Future<bool> getEnableRecordKeyFilePath() async {
    return await getBool("record_key_file_path") ?? true;
  }

  Future<bool> setEnableRecordKeyFilePath(bool enable) async {
    return setBool("record_key_file_path", enable);
  }

  Future<String?> getKeyFilePath() async {
    return await getString("key_file_path");
  }

  Future<bool> setKeyFilePath(String? path) async {
    return path == null
        ? remove("key_file_path")
        : setString("key_file_path", path);
  }

  @override
  Future<bool> clear() => super.clear();
}
