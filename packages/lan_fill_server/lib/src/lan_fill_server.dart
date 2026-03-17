import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:relic/relic.dart';

import 'package:otp/otp.dart';
import 'interactive_manipulation.dart';
import 'model/autofill.dto.dart';
import 'model/device_info.dto.dart';
import 'model/register.dto.dart';
import 'util/address.dart';
import 'util/common.dart';
import 'util/constant.dart';
import 'util/encrypt_utils.dart';
import 'util/security_helper.dart';

class _MyIOAdapter extends IOAdapter {
  _MyIOAdapter(super.server);

  static Future<_MyIOAdapter> bind(SecurityContext context) async {
    return _MyIOAdapter(
      await HttpServer.bindSecure(
        InternetAddress.anyIPv4,
        0,
        context,
        requestClientCertificate: true,
      ),
    );
  }
}

class LanFillServerOption {
  LanFillServerOption({
    required this.deviceInfo,
    required this.securityContext,
    this.idleCloseTimeout = const Duration(minutes: 5),
    this.secretKeyInterval = const Duration(seconds: 60),
  });

  ///
  /// 展示给客户端的一些基础信息
  ///
  final DeviceInfoDto deviceInfo;

  /// 服务器的证书
  final StoredSecurityContext securityContext;

  /// 空闲关闭服务器
  /// 如果超过这个时间还没有请求进入则关闭服务器
  final Duration idleCloseTimeout;

  ///
  /// 开启服务会随机生成一个 TOTP
  /// 客户端请求证书时, 会用这个TOTP 生成的 code 加密
  /// secretKeyInterval code 间隔
  ///
  final Duration secretKeyInterval;
}

class EncryptCertificateTotp {
  EncryptCertificateTotp({
    this.codeLength = 16,
    this.interval = const Duration(seconds: 60),
  });

  final int codeLength;
  final Duration interval;

  final String secret = OTP.randomSecret();

  int code() {
    return OTP.generateTOTPCode(
      secret,
      DateTime.now().millisecondsSinceEpoch,
      length: codeLength,
      interval: interval.inSeconds,
    );
  }

  String codeString() {
    return OTP.generateTOTPCodeString(
      secret,
      DateTime.now().millisecondsSinceEpoch,
      length: codeLength,
      interval: interval.inSeconds,
    );
  }

  Uint8List codeBytes() {
    return utf8.encode(codeString());
  }
}

class _IdleCloseServerMiddleware {
  _IdleCloseServerMiddleware({
    required this.duration,
    required this.onIdleCallback,
  });

  final Duration duration;
  final Function onIdleCallback;

  ///
  /// 请求进入加一
  /// 完成请求减一
  /// 当为零时才判断是否超时
  ///
  int _count = 0;
  int _start = 0;

  Timer? _timer;

  void start() {
    _timer?.cancel();
    _count = 0;
    _start = DateTime.now().millisecond;
    _timer = Timer.periodic(duration, (timer) {
      if (_count > 0) return;

      final milliseconds = DateTime.now().millisecond - _start;

      if (milliseconds >= duration.inMilliseconds) {
        onIdleCallback();
        _timer?.cancel();
        _timer = null;
      }
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void _stop() {
    _count++;
  }

  void _reset() {
    _count--;
    _start = DateTime.now().millisecond;
  }

  Middleware middleware() {
    return (final next) {
      return (final req) async {
        try {
          _stop();
          return await next(req);
        } finally {
          _reset();
        }
      };
    };
  }
}

class LanFillServer {
  LanFillServer(this.interactiveManipulation, this.option);

  final LanFillServerOption option;
  final InteractiveManipulation interactiveManipulation;

  late final EncryptCertificateTotp certificateTotp = EncryptCertificateTotp(
    codeLength: 32,
    interval: option.secretKeyInterval,
  );

  RelicServer? _server;
  late final RelicApp _app = _initRelicApp();
  late final SecurityContext _securityContext = SecurityContext()
    ..useCertificateChainBytes(option.securityContext.certificateBytes)
    ..usePrivateKeyBytes(option.securityContext.privateKeyBytes)
    ..setTrustedCertificatesBytes(option.securityContext.certificateBytes);

  late final _IdleCloseServerMiddleware _idleCloseServer =
      _IdleCloseServerMiddleware(
        duration: option.idleCloseTimeout,
        onIdleCallback: close,
      );

  Future<RegisterDto> start() async {
    if (_server != null) {
      return RegisterDto(
        addres: (await getLocalInternetAddress())
            .map((item) => item.address)
            .toList(),
        port: _server!.port,
        code: certificateTotp.codeString(),
      );
    }

    _server = await _app.run(() => _MyIOAdapter.bind(_securityContext));

    _idleCloseServer.start();

    return RegisterDto(
      addres: (await getLocalInternetAddress())
          .map((item) => item.address)
          .toList(),
      port: _server!.port,
      code: certificateTotp.codeString(),
    );
  }

  Future<void> close() async {
    await _app.close();
    _server = null;
    _idleCloseServer.cancel();
    interactiveManipulation.onServerClose();
  }

  RelicApp _initRelicApp() {
    final app = RelicApp();
    app.use("/", logRequests());
    app.use("/", _additionalResponseHeader(option.deviceInfo));
    app.use("/", _idleCloseServer.middleware());
    app.get("/register", _register);
    app.use(
      "/api",
      _validateCertificate(option.securityContext.certificateHash),
    );
    app.get("/api/heartbeat", _apiHeartbeat);
    app.post('/api/autofill', _apiAutofill);
    return app;
  }

  Middleware _additionalResponseHeader(final DeviceInfoDto deviceInfo) {
    return (final next) {
      return (final req) async {
        final result = await next(req);

        if (result is Response) {
          final response = result.copyWith(
            headers: result.headers.transform((headers) {
              headers[HeadersConstant.deviceName] = [deviceInfo.deviceName];
              headers[HeadersConstant.deviceAppVersion] = [
                deviceInfo.appVersion,
              ];
              headers[HeadersConstant.deviceFingerprint] = [
                deviceInfo.fingerprint,
              ];

              headers[HeadersConstant.devicePlatform] = [
                Platform.operatingSystem,
              ];
            }),
          );
          return response;
        }

        return result;
      };
    };
  }

  Middleware _validateCertificate(final String certificateHash) {
    return (final next) {
      return (final req) async {
        final httpRequest = req.token as HttpRequest;
        final certificate = httpRequest.certificate;

        if (certificate == null) {
          return Response.forbidden(
            body: Body.fromString("Certificate must be included"),
          );
        }

        if (der2sha256(certificate.der) != certificateHash) {
          return Response.forbidden(
            body: Body.fromString("Certificate mismatch"),
          );
        }

        return next(req);
      };
    };
  }

  Future<Response> _register(final Request req) async {
    final deviceName = req.headers[HeadersConstant.deviceName]?.first;
    final deviceFingerprint =
        req.headers[HeadersConstant.deviceFingerprint]?.first;
    final devicePlatform = req.headers[HeadersConstant.devicePlatform]?.first;

    if (deviceFingerprint == null) {
      return Response.unauthorized();
    }

    if (!(await interactiveManipulation.validateFingerprint(
      deviceFingerprint,
      devicePlatform ?? "unknown",
      deviceName,
    ))) {
      return Response.forbidden();
    }

    final key = certificateTotp.codeBytes();

    final encrypt = EncryptUtils.encryptCBC(
      key: key,
      bytes: utf8.encode(
        json.encode({
          "certificate": option.securityContext.certificate,
          "privateKey": option.securityContext.privateKey,
        }),
      ),
    );

    return Response.ok(
      body: .fromData(encrypt.bytes, mimeType: MimeType.octetStream),
      headers: Headers.fromMap({
        HeadersConstant.aesIv: [base64Encode(encrypt.iv.toList())],
      }),
    );
  }

  Future<Response> _apiHeartbeat(final Request req) async {
    return Response.ok();
  }

  Future<Response> _apiAutofill(final Request req) async {
    if (!isDesktopPlatform(Platform.operatingSystem)) {
      return Response.notImplemented();
    }

    final data = AutofillDto.formJson(jsonDecode(await req.readAsString()));

    if (data.fields.isEmpty) return Response.noContent();

    try {
      await interactiveManipulation.remoteAutofill(data);
      return Response.ok();
    } catch (e) {
      return Response.internalServerError(body: Body.fromString(e.toString()));
    }
  }
}
