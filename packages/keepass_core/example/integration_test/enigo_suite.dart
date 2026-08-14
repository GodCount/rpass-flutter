import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepass_core/keepass_core.dart' as enigo;

/// 少数物理键在 enigo 里没有对应变体，解码时会退到一个近似键，因此往返后会变成别的键。
/// 这是 `rust/binding/src/api/enigo.rs` 里刻意保留的单向映射。
Map<PhysicalKeyboardKey, PhysicalKeyboardKey> get _substitutions => {
  PhysicalKeyboardKey.numpadEnter: PhysicalKeyboardKey.enter,
  PhysicalKeyboardKey.intlBackslash: PhysicalKeyboardKey.backslash,
  if (Platform.isLinux) ...{
    PhysicalKeyboardKey.altRight: PhysicalKeyboardKey.altLeft,
    PhysicalKeyboardKey.metaRight: PhysicalKeyboardKey.metaLeft,
  },
};

/// 由 `app_test.dart` 调用，绑定的初始化在那里统一做。
void enigoTests() {
  test('character keys map through the US layout', () {
    expect(
      enigo.testKey2Key(key: PhysicalKeyboardKey.keyA).usbHidUsage,
      0x00070004,
    );
    expect(
      enigo.testKey2Key(key: PhysicalKeyboardKey.digit1).usbHidUsage,
      0x0007001e,
    );
    expect(
      enigo.testKey2Key(key: PhysicalKeyboardKey.slash).usbHidUsage,
      0x00070038,
    );
  });

  test('named keys keep their identity', () {
    for (final key in [
      PhysicalKeyboardKey.enter,
      PhysicalKeyboardKey.escape,
      PhysicalKeyboardKey.tab,
      PhysicalKeyboardKey.space,
      PhysicalKeyboardKey.backspace,
      PhysicalKeyboardKey.capsLock,
      PhysicalKeyboardKey.f1,
      PhysicalKeyboardKey.f12,
      PhysicalKeyboardKey.arrowUp,
      PhysicalKeyboardKey.arrowDown,
      PhysicalKeyboardKey.home,
      PhysicalKeyboardKey.pageDown,
      PhysicalKeyboardKey.numpad0,
      PhysicalKeyboardKey.numpadAdd,
      PhysicalKeyboardKey.controlLeft,
      PhysicalKeyboardKey.shiftRight,
      PhysicalKeyboardKey.altLeft,
      PhysicalKeyboardKey.metaLeft,
      PhysicalKeyboardKey.audioVolumeMute,
      PhysicalKeyboardKey.mediaPlayPause,
    ]) {
      expect(enigo.testKey2Key(key: key), key, reason: '${key.debugName}');
    }
  });

  test('keys without an enigo variant still round trip', () {
    // 这些键在所有平台上都没有命名变体，解码时落到 `Key::Other`，值原样保留。
    for (final key in [
      PhysicalKeyboardKey.gameButton1,
      PhysicalKeyboardKey.usbReserved,
      PhysicalKeyboardKey.lang5,
      const PhysicalKeyboardKey(0),
    ]) {
      expect(enigo.testKey2Key(key: key), key, reason: '${key.debugName}');
    }
  });

  test('the documented substitutions are the only lossy mappings', () {
    for (final key in PhysicalKeyboardKey.knownPhysicalKeys) {
      expect(
        enigo.testKey2Key(key: key),
        _substitutions[key] ?? key,
        reason: '${key.debugName} (0x${key.usbHidUsage.toRadixString(16)})',
      );
    }
  });

  test('permission can be queried without prompting', () {
    expect(enigo.Enigo.hasPermission(openPrompt: false), isA<bool>());
  });

  test('an instance reports the display size once permitted', () {
    if (!enigo.Enigo.hasPermission(openPrompt: false)) {
      markTestSkipped('没有输入模拟权限，跳过');
      return;
    }

    final instance = enigo.Enigo.preset();
    final (width, height) = instance.mainDisplay();

    expect(width, greaterThan(0));
    expect(height, greaterThan(0));
  });
}
