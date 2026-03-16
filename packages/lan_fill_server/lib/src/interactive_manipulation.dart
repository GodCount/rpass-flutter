abstract mixin class InteractiveManipulation {
  Future<bool> validateFingerprint(String fingerprint, String? deviceName);

  void onCilentClose();

  void onServerClose();
}
