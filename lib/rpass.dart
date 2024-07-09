import 'package:package_info_plus/package_info_plus.dart';

class RpassInfo {
  static late PackageInfo? _packageInfo;

  static Future<void> init() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  static String get appName => _packageInfo?.appName ?? "Rpass";
  static String get packageName => _packageInfo?.packageName ?? "Rpass";
  static String get version => _packageInfo?.version ?? "1.0.0";
  static String get buildNumber => _packageInfo?.buildNumber ?? "1";
  static String get buildSignature => _packageInfo?.buildSignature ?? "??";
  static String get installerStore => _packageInfo?.installerStore ?? "??";
}
