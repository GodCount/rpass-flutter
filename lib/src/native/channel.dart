import 'dart:io';

import 'package:flutter/foundation.dart';

import 'platform/desktop.dart';

abstract mixin class NativeChannelListener {
  void onTargetAppChange(String? name) {}
}

class NativeInstancePlatform {
  static NativeInstancePlatform get instance => _instance!;
  static NativeInstancePlatform? _instance;

  static void ensureInitialized() {
    NativeInstancePlatform._instance ??= Platform.isMacOS || Platform.isWindows
        ? DesktopNativeInstancePlatform()
        : NativeInstancePlatform();
  }

  final ObserverList<NativeChannelListener> _listeners =
      ObserverList<NativeChannelListener>();

  List<NativeChannelListener> get listeners => List.unmodifiable(_listeners);

  bool get hasListeners {
    return _listeners.isNotEmpty;
  }

  void addListener(NativeChannelListener listener) {
    _listeners.add(listener);
  }

  void removeListener(NativeChannelListener listener) {
    _listeners.remove(listener);
  }

  String? get targetAppName => null;

  bool get isTargetAppExist => targetAppName != null && targetAppName!.isNotEmpty;

  /// 激活上一个窗口的焦点
  Future<bool> activatePrevWindow() async {
    return false;
  }
}
