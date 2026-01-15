import 'dart:io';

import 'package:flutter/foundation.dart';

import 'platform/android.dart';
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
        : Platform.isAndroid
            ? AndroidNativeInstancePlatform()
            : NativeInstancePlatform();
  }

  final ObserverList<NativeChannelListener> _listeners =
      ObserverList<NativeChannelListener>();

  final AutofillService _autofillService = AutofillService();

  AutofillService get autofillService => _autofillService;

  List<NativeChannelListener> get listeners => List.unmodifiable(_listeners);

  bool get hasListeners => _listeners.isNotEmpty;

  String? get targetAppName => null;

  bool get isTargetAppExist =>
      targetAppName != null && targetAppName!.isNotEmpty;

  void addListener(NativeChannelListener listener) {
    _listeners.add(listener);
  }

  void removeListener(NativeChannelListener listener) {
    _listeners.remove(listener);
  }

  /// 激活上一个窗口的焦点
  Future<bool> activatePrevWindow() async {
    return false;
  }
}
