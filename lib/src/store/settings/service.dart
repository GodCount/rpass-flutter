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
    return locale != null
        ? setString("locale", locale.toString())
        : remove("locale");
  }

  Future<bool> getEnableBiometric() async {
    return await getBool("enable_biometric") ?? false;
  }

  Future<bool> setEnableBiometric(bool enable) {
    return setBool("enable_biometric", enable);
  }

  Future<Duration?> getLockDelay() async {
    final delay = await getInt("lock_delay_seconds");
    // 默认值 30秒
    // 小于0则表示永不
    return delay == null || delay > 0 ? Duration(seconds: delay ?? 30) : null;
  }

  Future<bool> setLockDelay(Duration? delay) {
    return setInt("lock_delay_seconds", delay != null ? delay.inSeconds : -1);
  }

  Future<bool> getEnableRecordKeyFilePath() async {
    return await getBool("record_key_file_path") ?? false;
  }

  Future<bool> setEnableRecordKeyFilePath(bool enable) {
    return setBool("record_key_file_path", enable);
  }

  Future<String?> getKeyFilePath() {
    return getString("key_file_path");
  }

  Future<bool> setKeyFilePath(String? path) {
    return path == null
        ? remove("key_file_path")
        : setString("key_file_path", path);
  }

  Future<bool> getEnableRemoteSync() async {
    return await getBool("remote_sync_kdbx") ?? true;
  }

  Future<bool> setEnableRemoteSync(bool enbale) {
    return setBool("remote_sync_kdbx", enbale);
  }

  Future<Duration?> getRemoteSyncCycle() async {
    final cycle = await getInt("remote_sync_cycle");
    // 默认值 1天
    // 小于0则表示每次启动
    return cycle == null || cycle > 0 ? Duration(seconds: cycle ?? 86400) : null;
  }

  Future<bool> setRemoteSyncCycle(Duration? cycle) {
    return setInt("remote_sync_cycle", cycle != null ? cycle.inSeconds : -1);
  }

  Future<DateTime?> getLastSyncTime() async {
    final time = await getInt("last_sync_time");
    return time != null ? DateTime.fromMillisecondsSinceEpoch(time) : null;
  }

  Future<bool> setLastSyncTime(DateTime? time) {
    return time == null
        ? remove("last_sync_time")
        : setInt("last_sync_time", time.millisecondsSinceEpoch);
  }

  Future<bool> getManualSelectFillItem() async {
    return await getBool("manual_select_fill_item") ?? false;
  }

  Future<bool> setManualSelectFillItem(bool enbale) {
    return setBool("manual_select_fill_item", enbale);
  }

  @override
  Future<bool> clear() => super.clear();
}
