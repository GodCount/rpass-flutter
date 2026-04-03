import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'common_features_interface.dart';
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

  @visibleForTesting
  late final List<CommonFeaturesInterface> features = [prevFocusWindow];

  Future<dynamic> _methodCallHandler(MethodCall call) async {
    for (final feature in features) {
      if (feature.methodCalls.contains(call.method)) {
        return feature.onMethodCallHandler(call);
      }
    }
  }
}
