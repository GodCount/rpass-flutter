import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

mixin class SharedPreferencesService {
  final _prefs = SharedPreferences.getInstance();

  @protected
  Future<Object?> get(String key) async => (await _prefs).get(key);

  @protected
  Future<bool?> getBool(String key) async => (await _prefs).getBool(key);

  @protected
  Future<int?> getInt(String key) async => (await _prefs).getInt(key);

  @protected
  Future<double?> getDouble(String key) async =>
      (await _prefs).getDouble(key);

  @protected
  Future<String?> getString(String key) async =>
      (await _prefs).getString(key);

  @protected
  Future<List<String>?> getStringList(String key) async =>
      (await _prefs).getStringList(key);

  @protected
  Future<bool> containsKey(String key) async =>
      (await _prefs).containsKey(key);

  @protected
  Future<bool> setBool(String key, bool value) async =>
      (await _prefs).setBool(key, value);

  @protected
  Future<bool> setInt(String key, int value) async =>
      (await _prefs).setInt(key, value);

  @protected
  Future<bool> setDouble(String key, double value) async =>
      (await _prefs).setDouble(key, value);

  @protected
  Future<bool> setString(String key, String value) async =>
      (await _prefs).setString(key, value);

  @protected
  Future<bool> setStringList(String key, List<String> value) async =>
      (await _prefs).setStringList(key, value);

  @protected
  Future<bool> remove(String key) async => (await _prefs).remove(key);

  @protected
  Future<bool> clear() async => (await _prefs).clear();

  @protected
  Future<bool> reload() async => (await _prefs).clear();
}
