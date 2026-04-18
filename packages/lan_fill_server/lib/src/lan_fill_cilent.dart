import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import 'interactive_manipulation.dart';
import 'model/autofill.dto.dart';
import 'model/device_info.dto.dart';
import 'model/register.dto.dart';
import 'util/address.dart';
import 'util/common.dart';
import 'util/constant.dart';
import 'util/encrypt_utils.dart';
import 'util/security_helper.dart';

class LanFillCilentOption {
  LanFillCilentOption({
    required this.deviceInfo,
    this.heartbeatDuration = const Duration(minutes: 2),
  });

  ///
  /// 展示给客户端的一些基础信息
  ///
  final DeviceInfoDto deviceInfo;

  ///
  /// 心跳周期
  /// 告诉服务器,客户端还未断链
  ///
  final Duration heartbeatDuration;
}

class LanFillCilent {
  LanFillCilent(this.interactiveManipulation, this.option);

  final LanFillCilentOption option;
  final InteractiveManipulation interactiveManipulation;

  Dio? _dio;

  bool _connecting = false;
  bool get connecting => _dio != null && _connecting;

  Timer? _heartbeatTimer;

  String _serverPlatform = "unknown";
  String get serverPlatform => _serverPlatform;

  Dio _getDio() {
    if (_dio == null) {
      throw Exception("You need to run registration before doing this");
    }
    if (!isDesktopPlatform(_serverPlatform)) {
      throw Exception(
        "server platform $_serverPlatform, not supported autofill",
      );
    }
    return _dio!;
  }

  void close() {
    _dio?.close();
    _dio = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _connecting = false;
    interactiveManipulation.onCilentClose();
  }

  Future<void> register(RegisterDto registerDto) async {
    if (connecting) close();

    final address = await matchSameDomainAddress(registerDto.addres);
    final key = utf8.encode(registerDto.code);

    final baseOptions = BaseOptions(
      connectTimeout: const Duration(milliseconds: 100),
      contentType: "application/octet-stream",
      responseType: ResponseType.bytes,
      headers: {
        HttpHeaders.userAgentHeader:
            "Rpass/${option.deviceInfo.appVersion} LanFillCilent/1.0.0",
        HeadersConstant.deviceName: option.deviceInfo.deviceName,
        HeadersConstant.deviceFingerprint: option.deviceInfo.fingerprint,
        HeadersConstant.devicePlatform: Platform.operatingSystem,
      },
      validateStatus: (status) => status != null,
    );

    /// 创建一个普通客户端
    /// 从服务器请求加密证书
    final dio = Dio(baseOptions)
      ..httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () => HttpClient()
          ..badCertificateCallback =
              (X509Certificate certificate, String host, int port) => true,
      );

    ///
    /// 判断哪些ip地址能和服务器通讯
    ///
    for (final ip in address) {
      Response<dynamic>? res;

      try {
        final uri = Uri.parse("https://$ip:${registerDto.port}/register");
        res = await dio.getUri(uri);
      } catch (e) {
        print(e);
        continue;
      }

      if (res.statusCode != HttpStatus.ok) {
        throw Exception(
          "server response ${res.statusCode}, ${res.statusMessage}",
        );
      }

      final aesIv = res.headers.value(HeadersConstant.aesIv);

      if (aesIv == null) {
        throw Exception("response headers missing ${HeadersConstant.aesIv}");
      }

      if (res.data is! Uint8List) {
        throw Exception("response body not is binary");
      }

      final decryptData = json.decode(
        utf8.decode(
          EncryptUtils.decryptCBC(
            key,
            Encrypted(res.data, base64Decode(aesIv)),
          ),
        ),
      );

      if (decryptData is! Map) {
        throw Exception("decrypt data not is object");
      }

      if (decryptData["certificate"] is! String) {
        throw Exception("certificate not exists");
      }

      if (decryptData["privateKey"] is! String) {
        throw Exception("privateKey not exists");
      }

      final deviceName = res.headers.value(HeadersConstant.deviceName);
      final deviceFingerprint = res.headers.value(
        HeadersConstant.deviceFingerprint,
      );

      _serverPlatform =
          res.headers.value(HeadersConstant.devicePlatform) ?? _serverPlatform;

      final certificateHash = calculateHashOfCertificate(
        decryptData["certificate"],
      );

      /// 用户交互,验证陌生设备
      if (!(await interactiveManipulation.validateFingerprint(
        deviceFingerprint ?? certificateHash,
        _serverPlatform,
        deviceName,
      ))) {
        return;
      }

      ///
      /// 创建安全上下文
      final context = SecurityContext()
        ..useCertificateChainBytes(utf8.encode(decryptData["certificate"]))
        ..usePrivateKeyBytes(utf8.encode(decryptData["privateKey"]))
        ..setTrustedCertificatesBytes(utf8.encode(decryptData["certificate"]));

      ///
      /// 创建安全客户端
      _dio = Dio(
        baseOptions.copyWith(
          baseUrl: "https://$ip:${registerDto.port}",
          contentType: "application/json",
          responseType: ResponseType.json,
          headers: {
            ...baseOptions.headers,
            Headers.contentTypeHeader: "application/json",
          },
        ),
      );

      _dio!.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () => HttpClient(context: context)
          ..badCertificateCallback =
              (X509Certificate certificate, String host, int port) {
                return der2sha256(certificate.der) == certificateHash;
              },
      );

      _dio!.interceptors.add(
        InterceptorsWrapper(
          onError: (error, handler) {
            // 请求错误下,不是这两种类型的,则代表连接断开了
            _connecting =
                !(error.type != .badResponse && error.type != .cancel);
            handler.next(error);
          },
          onResponse: (response, handler) {
            _connecting = true;
            handler.next(response);
          },
        ),
      );

      if (!(await _heartbeat(true))) {
        throw Exception("Heartbeat request response fail");
      }

      return;
    }

    throw Exception(
      "Not in the same network environment as the server Or the server is down",
    );
  }

  Future<bool> _heartbeat([bool? first]) async {
    _heartbeatTimer?.cancel();
    try {
      await _getDio().get(
        "/api/heartbeat",
        queryParameters: {"first": (first ?? false).toString()},
        options: Options(
          sendTimeout: const Duration(milliseconds: 300),
          receiveTimeout: const Duration(milliseconds: 300),
        ),
      );
      _connecting = true;
    } catch (e) {
      _connecting = false;
    }

    if (!_connecting) {
      return false;
    }

    _heartbeatTimer = Timer(option.heartbeatDuration, _heartbeat);
    return _connecting;
  }

  Future<bool> heartbeat() {
    return _heartbeat();
  }

  Future<void> autofill(AutofillDto dto) async {
    await _getDio().post("/api/autofill", data: dto.toJson());
  }

  Future<void> uploadFile(String filename, Uint8List bytes) async {
    final dio = _getDio();
    await dio.post(
      "/api/upload_file",
      data: bytes,
      options: Options(
        contentType: "application/octet-stream",
        headers: {
          Headers.contentTypeHeader: "application/octet-stream",
          HeadersConstant.filename: filename,
        },
      ),
    );
  }
}
