import 'package:flutter/services.dart';

class NativeChannel {
  NativeChannel._() {
    _channel.setMethodCallHandler(_methodCallHandler);
  }

  static final NativeChannel instance = NativeChannel._();

  final MethodChannel _channel = const MethodChannel('native_channel_rpass');

  void ensureInitialized() {}

  Future<void> _methodCallHandler(MethodCall call) async {
    print("${call.method}, ${call.arguments}");
    // switch (call.method) {}
  }

  Future<bool> activatePrevWindow() async {
    return await _channel.invokeMethod<bool>("activate_prev_application") ?? false;
  }
}
