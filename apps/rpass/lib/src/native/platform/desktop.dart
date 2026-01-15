import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../channel.dart';

class DesktopNativeInstancePlatform extends NativeInstancePlatform {
  DesktopNativeInstancePlatform() {
    _channel.setMethodCallHandler(_methodCallHandler);
  }

  final MethodChannel _channel = const MethodChannel('native_channel_rpass');

  String? _targetAppName;

  @override
  String? get targetAppName => _targetAppName;

  Future<void> _methodCallHandler(MethodCall call) async {
    debugPrint("native_channel: ${call.method}, ${call.arguments}");

    switch (call.method) {
      case "prev_actived_application":
        _targetAppName = call.arguments["name"];
        break;
    }

    for (final item in listeners) {
      switch (call.method) {
        case "prev_actived_application":
          item.onTargetAppChange(_targetAppName);
          break;
      }
    }
  }

  /// 激活上一个窗口的焦点
  @override
  Future<bool> activatePrevWindow() async {
    return await _channel.invokeMethod<bool>("activate_prev_application") ??
        false;
  }
}
