import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:lan_fill_server/lan_fill_server.dart';

import '../../util/fetch_favicon.dart';
import '../shared_preferences/index.dart';
import 'shortcuts.dart';

class SettingsService with SharedPreferencesService {
  Future<ThemeMode> getThemeMode() async {
    final mode = (await getInt("theme_mode")) ?? ThemeMode.system.index;
    return ThemeMode.values.firstWhere((m) => m.index == mode);
  }

  Future<bool> setThemeMode(ThemeMode mode) => setInt("theme_mode", mode.index);

  Future<Color> getThemeSeedColor() async {
    final color = (await getString("theme_seed_color")) ?? "FF659BFF";
    return Color(int.parse(color, radix: 16));
  }

  Future<bool> setThemeSeedColor(Color color) {
    return setString("theme_seed_color", color.toARGB32().toRadixString(16));
  }

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
    return cycle == null || cycle > 0
        ? Duration(seconds: cycle ?? 86400)
        : null;
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

  Future<bool> getStartFocusSreach() async {
    return await getBool("start_focus_sreach") ?? false;
  }

  Future<bool> setStartFocusSreach(bool enbale) {
    return setBool("start_focus_sreach", enbale);
  }

  Future<FaviconSource?> getFaviconSource() async {
    final value = await getInt("favicon_source");
    return value != null && value > 0 && value < FaviconSource.values.length
        ? FaviconSource.values[value]
        : null;
  }

  Future<bool> setFaviconSource(FaviconSource? value) {
    if (value == null) return remove("favicon_source");

    return setInt("favicon_source", FaviconSource.values.indexOf(value));
  }

  Future<Iterable<HotKey>?> getShrtcutsHotKeys() async {
    final jsonStr = await getString("shrtcuts_hot_keys");

    if (jsonStr == null) return null;

    final List<dynamic> data = jsonDecode(jsonStr);
    return data.map((item) => HotKey.fromJson(item));
  }

  Future<bool> setShrtcutsHotKeys(Iterable<HotKey>? hotKeys) async {
    return hotKeys != null
        ? setString(
            "shrtcuts_hot_keys",
            jsonEncode(hotKeys.map((item) => item.toJson()).toList()),
          )
        : remove("shrtcuts_hot_keys");
  }

  Future<ShortcutsOpenAppAlignment> getShortcutsOpenAppAlignment() async {
    final value = await getInt("shortcuts_open_app_alignment");
    return value != null &&
            value > 0 &&
            value < ShortcutsOpenAppAlignment.values.length
        ? ShortcutsOpenAppAlignment.values[value]
        : ShortcutsOpenAppAlignment.mouseScreenCenter;
  }

  Future<bool> setShortcutsOpenAppAlignment(ShortcutsOpenAppAlignment? value) {
    if (value == null) return remove("shortcuts_open_app_alignment");

    return setInt(
      "shortcuts_open_app_alignment",
      ShortcutsOpenAppAlignment.values.indexOf(value),
    );
  }

  Future<StoredSecurityContext> getStoredSecurityContext() async {
    final jsonStr = await getString("stored_security_context");

    StoredSecurityContext? context;

    if (jsonStr != null) {
      try {
        context = StoredSecurityContext.formJson(jsonDecode(jsonStr));
      } catch (e) {
        debugPrint("$e");
      }
    }

    if (context == null) {
      context = generateSecurityContext();
      setStoredSecurityContext(context);
    }
    return context;
  }

  Future<bool> setStoredSecurityContext(StoredSecurityContext? context) {
    return context != null
        ? setString("stored_security_context", jsonEncode(context.toJson()))
        : remove("stored_security_context");
  }

  Future<List<String>> getTrustFingerprints() async {
    return await getStringList("trust_fingerprints") ?? [];
  }

  Future<bool> setTrustFingerprints(List<String>? list) async {
    return list != null
        ? setStringList("trust_fingerprints", list)
        : remove("trust_fingerprints");
  }

  @override
  Future<bool> clear() => super.clear();
}
