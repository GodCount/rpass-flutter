import 'model/autofill.dto.dart';

abstract mixin class InteractiveManipulation {
  Future<bool> validateFingerprint(String fingerprint, String? deviceName);

  Future<void> remoteAutofill(AutofillDto dto);

  void onCilentClose();

  void onServerClose();
}
