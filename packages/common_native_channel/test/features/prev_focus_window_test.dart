import 'package:common_native_channel/common_native_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('common_native_channel');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return false;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test("Listener", () {
    expect(prevFocusWindow.hasListeners, false);
    final listener = PrevFocusWindowListener();
    prevFocusWindow.addListener(listener);
    expect(prevFocusWindow.hasListeners, true);
    prevFocusWindow.removeListener(listener);
    expect(prevFocusWindow.hasListeners, false);
  });

  test('activatePrevWindow', () async {
    expect(await prevFocusWindow.activatePrevWindow(), false);
  });
}
