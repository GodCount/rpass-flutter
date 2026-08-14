import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:keepass_core/keepass_core.dart' show initRustLib;

import 'enigo_suite.dart';
import 'kdbx_suite.dart';

/// 所有集成测试的唯一入口。
///
/// 桌面端一次运行只能启动一个宿主应用，多个 `*_test.dart` 会在第二个文件上报
/// “Unable to start the app on the device”，所以各模块的用例写成 `*_suite.dart`，
/// 由这里统一初始化并挂载。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => initRustLib());

  group('kdbx', kdbxTests);
  group('enigo', enigoTests);
}
