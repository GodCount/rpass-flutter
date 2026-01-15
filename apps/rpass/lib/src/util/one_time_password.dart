import 'package:otp/otp.dart';

class AuthOTPError extends Error {
  final String message;
  AuthOTPError(this.message);
}

class AuthOneTimePassword {
  AuthOneTimePassword({
    required this.secret,
    this.account,
    this.issuer,
    int? period,
  }) : period = period ?? 30 {
    code();
  }

  final String secret;
  final int period;
  final String? account;
  final String? issuer;

  static AuthOneTimePassword parse(String url) {
    final uri = Uri.parse(url);
    if (uri.scheme != "otpauth") {
      throw AuthOTPError("url scheme not optauth");
    }
    if (!uri.queryParameters.containsKey("secret")) {
      throw AuthOTPError("secret is not exist");
    }

    String secret = uri.queryParameters["secret"]!;
    int? period;
    String? account;
    String? issuer;

    String pathSegment = uri.pathSegments[0];
    if (pathSegment.contains(":")) {
      account = pathSegment.split(":")[0];
      issuer = pathSegment.split(":")[1];
    }

    if (uri.queryParameters.containsKey("issuer")) {
      issuer = uri.queryParameters["issuer"];
    }

    if (uri.queryParameters.containsKey("period")) {
      period = int.tryParse(uri.queryParameters["period"]!);
    }

    return AuthOneTimePassword(
      secret: secret,
      period: period,
      account: account,
      issuer: issuer,
    );
  }

  int code() {
    return OTP.generateTOTPCode(
      secret,
      DateTime.now().millisecondsSinceEpoch,
      interval: period,
      isGoogle: true,
      algorithm: Algorithm.SHA1
    );
  }

  double percent() {
    return ((DateTime.now().millisecondsSinceEpoch / 1000) % period) / period;
  }

}
