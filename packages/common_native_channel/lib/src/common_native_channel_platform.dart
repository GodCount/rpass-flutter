import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'common_features_interface.dart';
import 'features/installed_apps.dart';
import 'features/prev_focus_window.dart';

class CommonNativeChannelPlatform extends PlatformInterface {
  CommonNativeChannelPlatform() : super(token: _token) {
    methodChannel.setMethodCallHandler(_methodCallHandler);
  }

  static final Object _token = Object();

  static CommonNativeChannelPlatform instance = CommonNativeChannelPlatform();

  @visibleForTesting
  final methodChannel = const MethodChannel('common_native_channel');

  late final PrevFocusWindow prevFocusWindow = PrevFocusWindow(methodChannel);
  late final InstalledApps installedApps = InstalledApps(methodChannel);

  @visibleForTesting
  late final List<CommonFeaturesInterface> features = [
    prevFocusWindow,
    installedApps,
  ];

  Future<void> ensureInitialized() async {
    // 进行一次通讯交互, 如果不就行的话, 直接在原生端回调, 会出现接收不到的问题
    await methodChannel.invokeMethod("ensure_initialized");
  }

  Future<dynamic> _methodCallHandler(MethodCall call) async {
    for (final feature in features) {
      if (feature.methodCalls.contains(call.method)) {
        return feature.onMethodCallHandler(call);
      }
    }
  }
}
