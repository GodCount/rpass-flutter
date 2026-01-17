import 'dart:io';
import 'platform/android.dart';

class NativeInstancePlatform {
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
