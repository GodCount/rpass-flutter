import 'dart:io';

import 'package:flutter/services.dart';

import '../util/common.dart';
import 'platform/android.dart';

abstract class MethodChannelInterface {
  MethodChannelInterface(this.channel, this.emit);

  final MethodChannel channel;
  final ValueChanged<ValueChanged<NativeChannelListener>> emit;

  List<String> get methodCalls;

  Future<dynamic> onMethodCallHandler(MethodCall call);
}

mixin NativeChannelListener {
  void onRequestAutofill(AutofillMetadata metadata) {}
}

class NativeInstancePlatform
    with SimpleObserverListener<NativeChannelListener> {
  static NativeInstancePlatform get instance => _instance!;
  static NativeInstancePlatform? _instance;

  static void ensureInitialized() {
    NativeInstancePlatform._instance ??= Platform.isAndroid
        ? AndroidNativeInstancePlatform()
        : NativeInstancePlatform();
  }

  final AutofillService _autofillService = AutofillService();

  AutofillService get autofillService => _autofillService;
}
