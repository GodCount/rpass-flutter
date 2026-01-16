import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

mixin class PrevFocusWindowListener {
  void onWindowChange(String? name) {}
}

class PrevFocusWindow extends PlatformInterface {
  PrevFocusWindow._() : super(token: _token) {
    _methodChannel.setMethodCallHandler(_methodCallHandler);
  }

  static final Object _token = Object();

  static final PrevFocusWindow instance = PrevFocusWindow._();

  final _methodChannel = const MethodChannel('prev_focus_window');

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

  Future<void> _methodCallHandler(MethodCall call) async {
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
    return await _methodChannel.invokeMethod<bool>("activate_prev_window") ??
        false;
  }
}
