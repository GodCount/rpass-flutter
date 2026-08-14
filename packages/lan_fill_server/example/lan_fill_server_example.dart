import 'dart:typed_data';

import 'package:lan_fill_server/lan_fill_server.dart';

class TIM extends InteractiveManipulation {
  @override
  void onCilentClose() {
  }

  @override
  void onServerClose() {
  }

  @override
  Future<void> onRemoteAutofill(AutofillDto dto) {
    throw UnimplementedError();
  }

  @override
  Future<bool> validateFingerprint(
    String fingerprint,
    String devicePlatform,
    String? deviceName,
  ) {
    throw UnimplementedError();
  }

  @override
  void onServerCilentFirstHeartbeat(String devicePlatform, String? deviceName) {
  }

  @override
  Future<void> onSaveUploadFile(String filename, Uint8List bytes) {
    throw UnimplementedError();
  }
  

}

Future<void> main() async {
  final server = LanFillServer(
    TIM(),
    LanFillServerOption(
      deviceInfo: DeviceInfoDto(
        deviceName: "test_server",
        appVersion: "1.0.0",
        fingerprint: "test_server_fingerprint",
      ),
      securityContext: generateSecurityContext(),
    ),
  );

  final registerDto = await server.start();

  final cilent = LanFillCilent(
    TIM(),
    LanFillCilentOption(
      deviceInfo: DeviceInfoDto(
        deviceName: "test_cilent",
        appVersion: "1.0.0",
        fingerprint: "test_cilent_fingerprint",
      ),
    ),
  );

  await cilent.register(registerDto);

  await Future.delayed(Duration(seconds: 5));

  await server.close();
}
