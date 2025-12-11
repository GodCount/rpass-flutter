import 'package:flutter/material.dart';

import '../../widget/kdbx_icon.dart';
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
  Duration? _remoteSyncCycle;
  DateTime? _lastSyncTime;
  late bool _manualSelectFillItem;
  late bool _startFocusSreach;
  FavIconSource? _favIconSource;


  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;
  bool get enableBiometric => _enableBiometric;
  Duration? get lockDelay => _lockDelay;
  bool get enableRecordKeyFilePath => _enableRecordKeyFilePath;
  String? get keyFilePath => _keyFilePath;
  bool get enableRemoteSync => _enableRemoteSync;
  Duration? get remoteSyncCycle => _remoteSyncCycle;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get manualSelectFillItem => _manualSelectFillItem;
  bool get startFocusSreach => _startFocusSreach;
  FavIconSource? get favIconSource => _favIconSource;


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

    if (!enable) {
      setKeyFilePath(null);
    } else {
      notifyListeners();
    }

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

  Future<void> setRemoteSyncCycle(Duration? cycle) async {
    if (cycle == _remoteSyncCycle) return;

    _remoteSyncCycle = cycle;

    notifyListeners();

    await _settingsService.setRemoteSyncCycle(cycle);
  }

  Future<void> setLastSyncTime(DateTime? time) async {
    if (time == _lastSyncTime) return;

    _lastSyncTime = time;

    notifyListeners();

    await _settingsService.setLastSyncTime(time);
  }

  Future<void> setManualSelectFillItem(bool enable) async {
    if (enable == _manualSelectFillItem) return;

    _manualSelectFillItem = enable;

    notifyListeners();

    await _settingsService.setManualSelectFillItem(enable);
  }


  Future<void> setStartFocusSreach(bool enable) async {
    if (enable == _startFocusSreach) return;

    _startFocusSreach = enable;

    notifyListeners();

    await _settingsService.setStartFocusSreach(enable);
  }


  Future<void> setFavIconSource(FavIconSource? value) async {
    if (value == _favIconSource) return;

    _favIconSource = value;

    notifyListeners();

    await _settingsService.setFavIconSource(value);
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
    _remoteSyncCycle = await _settingsService.getRemoteSyncCycle();
    _lastSyncTime = await _settingsService.getLastSyncTime();
    _manualSelectFillItem = await _settingsService.getManualSelectFillItem();
    _startFocusSreach = await _settingsService.getStartFocusSreach();
    _favIconSource = await _settingsService.getFavIconSource();

    notifyListeners();
  }
}
