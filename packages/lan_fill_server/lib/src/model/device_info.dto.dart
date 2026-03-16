class DeviceInfoDto {
  DeviceInfoDto({
    required this.deviceName,
    required this.appVersion,
    required this.fingerprint,
  });

  final String deviceName;
  final String appVersion;
  final String fingerprint;
}
