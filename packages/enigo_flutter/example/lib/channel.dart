import 'package:flutter/services.dart';

class WUtil {
  static const _kChannel = MethodChannel("com.example");

  static Future<String> recordTopWindow() async {
    return await _kChannel.invokeMethod<String?>("recordTopWindow") ?? "none";
  }

  static Future<bool> setTopWindow() async {
    return await _kChannel.invokeMethod<bool>("setTopWindow") ?? false;
  }
}
