import 'package:lan_fill_server/lan_fill_server.dart';
import 'package:lan_fill_server/src/interactive_manipulation.dart';
import 'package:lan_fill_server/src/model/device_info.dto.dart';
import 'package:lan_fill_server/src/util/security_helper.dart';

class TIM extends InteractiveManipulation {
  @override
  Future<bool> validateFingerprint(
    String fingerprint,
    String? deviceName,
  ) async {
    print("${deviceName} ==> ${fingerprint}");
    return false;
  }
  
  @override
  void onCilentClose() {
    // TODO: implement onCilentClose
  }
  
  @override
  void onServerClose() {
    // TODO: implement onServerClose
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
