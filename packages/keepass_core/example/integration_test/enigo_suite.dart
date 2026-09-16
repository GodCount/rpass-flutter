import 'package:flutter_test/flutter_test.dart';
import 'package:keepass_core/keepass_core.dart' as enigo;

/// 由 `app_test.dart` 调用，绑定的初始化在那里统一做。
void enigoTests() {
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
