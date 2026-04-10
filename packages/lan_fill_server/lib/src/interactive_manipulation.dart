import 'dart:typed_data';

import 'model/autofill.dto.dart';

abstract mixin class InteractiveManipulation {
  Future<bool> validateFingerprint(
    String fingerprint,
    String devicePlatform,
    String? deviceName,
  );

  Future<void> onRemoteAutofill(AutofillDto dto);
  Future<void> onSaveUploadFile(String filename, Uint8List bytes);

  void onServerCilentFirstHeartbeat(String devicePlatform, String? deviceName);

  void onCilentClose();

  void onServerClose();
}
