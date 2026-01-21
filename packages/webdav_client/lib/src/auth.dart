import 'dart:convert';
import 'utils.dart';

/// Auth type
enum AuthType { NoAuth, BasicAuth, DigestAuth }

/// Auth -----------------------------------
class Auth {
  /// username
  final String user;

  /// password
  final String pwd;

  const Auth({required this.user, required this.pwd});

  /// Get auth type
  AuthType get type => AuthType.NoAuth;

  /// Get authorization data
  String? authorize(String method, String path) => null;
}

/// BasicAuth ------------------------------------
class BasicAuth extends Auth {
  const BasicAuth({required super.user, required super.pwd});

  @override
  AuthType get type => AuthType.BasicAuth;

  @override
  String authorize(String method, String path) {
    List<int> bytes = utf8.encode('$user:$pwd');
    return 'Basic ${base64Encode(bytes)}';
  }
}

// DigestAuth ----------------------------------
class DigestAuth extends Auth {
  DigestParts dParts;

  DigestAuth({required super.user, required super.pwd, required this.dParts});

  String? get nonce => dParts.parts['nonce'];

  String? get realm => dParts.parts['realm'];

  String? get qop => dParts.parts['qop'];

  String? get opaque => dParts.parts['opaque'];

  String? get algorithm => dParts.parts['algorithm'];

  String? get entityBody => dParts.parts['entityBody'];

  @override
  AuthType get type => AuthType.DigestAuth;

  @override
  String authorize(String method, String path) {
    dParts.uri = Uri.encodeFull(path);
    dParts.method = method;
    // Uri.encodeComponent fix not ascii
    return _getDigestAuthorization();
  }

  String _getDigestAuthorization() {
    int nonceCount = 1;
    String cnonce = computeNonce();
    String ha1 = _computeHA1(nonceCount, cnonce);
    String ha2 = _computeHA2();
    String response = _computeResponse(ha1, ha2, nonceCount, cnonce);
    String authorization =
        'Digest username="$user", realm="$realm", nonce="$nonce", uri="${dParts.uri}", nc=$nonceCount, cnonce="$cnonce", response="$response"';

    if (qop?.isNotEmpty == true) {
      authorization += ', qop=$qop';
    }

    if (opaque?.isNotEmpty == true) {
      authorization += ', opaque=$opaque';
    }

    return authorization;
  }

  //
  String _computeHA1(int nonceCount, String cnonce) {
    String? algorithm = this.algorithm;

    if (algorithm == 'MD5' || algorithm?.isEmpty != false) {
      return md5Hash('$user:$realm:$pwd');
    } else if (algorithm == 'MD5-sess') {
      String md5Str = md5Hash('$user:$realm:$pwd');
      return md5Hash('$md5Str:$nonceCount:$cnonce');
    }

    return '';
  }

  //
  String _computeHA2() {
    String? qop = this.qop;

    if (qop == 'auth' || qop?.isEmpty != false) {
      return md5Hash('${dParts.method}:${dParts.uri}');
    } else if (qop == 'auth-int' && entityBody?.isEmpty == false) {
      return md5Hash(
        '${dParts.method}:${dParts.uri}:${md5Hash(entityBody!)}',
      );
    }

    return '';
  }

  //
  String _computeResponse(
    String ha1,
    String ha2,
    int nonceCount,
    String cnonce,
  ) {
    String? qop = this.qop;

    if (qop?.isEmpty != false) {
      return md5Hash('$ha1:$nonce:$ha2');
    } else if (qop == 'auth' || qop == 'auth-int') {
      return md5Hash('$ha1:$nonce:$nonceCount:$cnonce:$qop:$ha2');
    }

    return '';
  }
}

/// DigestParts
class DigestParts {
  String uri = '';
  String method = '';

  Map<String, String> parts = {
    'nonce': '',
    'realm': '',
    'qop': '',
    'opaque': '',
    'algorithm': '',
    'entityBody': '',
  };

  DigestParts(String? authHeader) {
    if (authHeader != null) {
      var keys = parts.keys;
      var list = authHeader.split(',');
      for (var kv in list) {
        for (var k in keys) {
          if (kv.contains(k)) {
            var index = kv.indexOf('=');
            if (kv.length - 1 > index) {
              parts[k] = trim(kv.substring(index + 1), '"');
            }
          }
        }
      }
    }
  }
}
