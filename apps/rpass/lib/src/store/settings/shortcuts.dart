import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import '../../util/common.dart';
import 'service.dart';

extension ExtHotKey on HotKey {
  bool eq(HotKey hotKey) {
    bool modifiersEq = false;

    if (modifiers != null && hotKey.modifiers != null) {
      final a = modifiers!.fold<List<PhysicalKeyboardKey>>(
        [],
        (list, item) => [...list, ...item.physicalKeys],
      );
      final b = hotKey.modifiers!.fold<List<PhysicalKeyboardKey>>(
        [],
        (list, item) => [...list, ...item.physicalKeys],
      );
      modifiersEq = a.length == b.length && a.every((item) => b.contains(item));
    }

    return scope == hotKey.scope && key == hotKey.key && modifiersEq;
  }

  HotKey clone() {
    return HotKey(
      key: key,
      identifier: identifier,
      modifiers: modifiers,
      scope: scope,
    );
  }
}

enum ShortcutsTrigger {
  // Only works on macOS.
  up,
  down,
}

enum ShortcutsOpenAppAlignment { mouse, mouseCenter, mouseScreenCenter, prev }

typedef ShortcutsHotHandler =
    void Function(HotKey hotKey, ShortcutsTrigger trigger);

class ShortcutsStore with SimpleObserverListener<ShortcutsHotHandler> {
  ShortcutsStore({
    required SettingsService settingsService,
    required VoidCallback notifyListeners,
  }) : _notifyListeners = notifyListeners,
       _settingsService = settingsService;

  final VoidCallback _notifyListeners;
  final SettingsService _settingsService;

  final defaultHotKeys = genDefaultHotKeys();

  final Map<String, HotKey> hotKeys = genDefaultHotKeys();

  ShortcutsOpenAppAlignment _shortcutsOpenAppAlignment =
      ShortcutsOpenAppAlignment.mouseScreenCenter;

  ShortcutsOpenAppAlignment get shortcutsOpenAppAlignment =>
      _shortcutsOpenAppAlignment;

  static Map<String, HotKey> genDefaultHotKeys() {
    return {
      "open": HotKey(
        identifier: "open",
        modifiers: [HotKeyModifier.alt, HotKeyModifier.shift],
        key: LogicalKeyboardKey.keyP,
      ),
      "lock": HotKey(
        identifier: "lock",
        modifiers: [HotKeyModifier.alt, HotKeyModifier.shift],
        key: LogicalKeyboardKey.keyL,
      ),
      "autofill": HotKey(
        identifier: "autofill",
        modifiers: [HotKeyModifier.alt, HotKeyModifier.shift],
        key: LogicalKeyboardKey.enter,
      ),

      "autofill_UserName": HotKey(
        identifier: "autofill_UserName",
        modifiers: [HotKeyModifier.alt, HotKeyModifier.shift],
        key: LogicalKeyboardKey.digit1,
      ),
      "autofill_Email": HotKey(
        identifier: "autofill_Email",
        modifiers: [HotKeyModifier.alt, HotKeyModifier.shift],
        key: LogicalKeyboardKey.digit2,
      ),

      "autofill_Password": HotKey(
        identifier: "autofill_Password",
        modifiers: [HotKeyModifier.alt, HotKeyModifier.shift],
        key: LogicalKeyboardKey.digit3,
      ),
      "autofill_OTPAuth": HotKey(
        identifier: "autofill_OTPAuth",
        modifiers: [HotKeyModifier.alt, HotKeyModifier.shift],
        key: LogicalKeyboardKey.digit4,
      ),
    };
  }

  Future<void> setShortcutsOpenAppAlignment(
    ShortcutsOpenAppAlignment value,
  ) async {
    if (value == _shortcutsOpenAppAlignment) return;

    _shortcutsOpenAppAlignment = value;

    _notifyListeners();

    await _settingsService.setShortcutsOpenAppAlignment(value);
  }

  Future<void> setShrtcutsHot(HotKey hotKey, [bool? removed]) async {
    assert(kIsDesktop, "should be used on desktop");

    if (removed != null && removed) {
      hotKeys.remove(hotKey.identifier);
      await hotKeyManager.unregister(hotKey);
      await _settingsService.setShrtcutsHotKeys(hotKeys.values);
      return _notifyListeners();
    }

    if (!hotKeys.values.every(
      (item) => item.identifier == hotKey.identifier || !item.eq(hotKey),
    )) {
      throw Exception("shortcut key conflict.");
    }

    if (hotKeys[hotKey.identifier] == null) {
      hotKeys[hotKey.identifier] = hotKey;
    } else {
      if (hotKeys[hotKey.identifier]!.eq(hotKey)) return;
      await hotKeyManager.unregister(hotKeys[hotKey.identifier]!);
      hotKeys[hotKey.identifier] = hotKey;
    }
    await hotKeyManager.register(hotKey, keyDownHandler: _hotKeyDownHandler);
    await _settingsService.setShrtcutsHotKeys(hotKeys.values);
    _notifyListeners();
  }

  void _hotKeyDownHandler(HotKey key) {
    debugPrint("HotKey Down ${key.identifier}");
    for (final callback in listeners) {
      callback(key, ShortcutsTrigger.down);
    }
  }

  Future<void> _initRegister() async {
    for (final item in hotKeys.values) {
      await hotKeyManager.register(item, keyDownHandler: _hotKeyDownHandler);
    }
  }

  Future<void> init() async {
    if (kIsDesktop) {
      _shortcutsOpenAppAlignment = await _settingsService
          .getShortcutsOpenAppAlignment();

      final shrtcutsHotKeys = (await _settingsService.getShrtcutsHotKeys());

      if (shrtcutsHotKeys != null) {
        for (final item in shrtcutsHotKeys) {
          hotKeys[item.identifier] = item;
        }
      }

      if (kDebugMode) {
        await hotKeyManager.unregisterAll();
      }
      await _initRegister();
    }
  }
}
