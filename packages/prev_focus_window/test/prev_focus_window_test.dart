import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prev_focus_window/prev_focus_window.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('prev_focus_window');

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
    expect(PrevFocusWindow.instance.hasListeners, false);
    final listener = PrevFocusWindowListener();
    PrevFocusWindow.instance.addListener(listener);
    expect(PrevFocusWindow.instance.hasListeners, true);
    PrevFocusWindow.instance.removeListener(listener);
    expect(PrevFocusWindow.instance.hasListeners, false);
  });

  test('activatePrevWindow', () async {
    expect(await PrevFocusWindow.instance.activatePrevWindow(), false);
  });
}
