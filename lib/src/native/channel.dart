import 'package:flutter/services.dart';

class NativeChannel {
  NativeChannel._() {
    _channel.setMethodCallHandler(_methodCallHandler);
  }

  static final NativeChannel instance = NativeChannel._();

  final MethodChannel _channel = const MethodChannel('native_channel_rpass');

  Future<void> _methodCallHandler(MethodCall call) async {
    switch(call.method) {
      
    }
  }
}
