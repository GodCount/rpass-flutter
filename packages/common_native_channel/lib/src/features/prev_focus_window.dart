import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../common_features_interface.dart';

mixin class PrevFocusWindowListener {
  void onWindowChange(String? name) {}
}

class PrevFocusWindow extends CommonFeaturesInterface {
  PrevFocusWindow(super.methodChannel);

  @override
  final List<String> methodCalls = ["prev_actived_window"];

  final ObserverList<PrevFocusWindowListener> _listeners =
      ObserverList<PrevFocusWindowListener>();

  List<PrevFocusWindowListener> get listeners => List.unmodifiable(_listeners);

  bool get hasListeners => _listeners.isNotEmpty;

  void addListener(PrevFocusWindowListener listener) {
    _listeners.add(listener);
  }

  void removeListener(PrevFocusWindowListener listener) {
    _listeners.remove(listener);
  }

  String? _targetWindowName;

  String? get targetWindowName => _targetWindowName;

  bool get isTargetWindowExist =>
      _targetWindowName != null && _targetWindowName!.isNotEmpty;

  @override
  Future<dynamic> onMethodCallHandler(MethodCall call) async {
    debugPrint("prev_focus_window_channel: ${call.method}, ${call.arguments}");

    switch (call.method) {
      case "prev_actived_window":
        _targetWindowName = call.arguments["name"];
        break;
    }

    for (final item in listeners) {
      switch (call.method) {
        case "prev_actived_window":
          item.onWindowChange(_targetWindowName);
          break;
      }
    }
  }

  Future<bool> activatePrevWindow() async {
    return await methodChannel.invokeMethod<bool>("activate_prev_window") ??
        false;
  }
}
