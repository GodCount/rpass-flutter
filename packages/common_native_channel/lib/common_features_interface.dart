import 'package:flutter/services.dart';

abstract class CommonFeaturesInterface {
  CommonFeaturesInterface(this.methodChannel);

  final MethodChannel methodChannel;

  List<String> get methodCalls;

  Future<dynamic> onMethodCallHandler(MethodCall call);
}
