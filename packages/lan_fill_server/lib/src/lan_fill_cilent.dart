import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import 'interactive_manipulation.dart';
import 'model/device_info.dto.dart';
import 'model/register.dto.dart';
import 'util/address.dart';
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

  Dio _getDio() {
    assert(_dio != null, "You need to run registration before doing this");
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

    /// 创建一个普通客户端
    /// 从服务器请求加密证书
    final dio =
        Dio(
            BaseOptions(
              sendTimeout: const Duration(seconds: 1),
              contentType: "application/octet-stream",
              responseType: ResponseType.bytes,
              headers: {
                HttpHeaders.userAgentHeader:
                    "Rpass/${option.deviceInfo.appVersion} LanFillCilent/1.0.0",
                HeadersConstant.deviceName: option.deviceInfo.deviceName,
                HeadersConstant.deviceFingerprint:
                    option.deviceInfo.fingerprint,
              },
              validateStatus: (status) => status != null,
            ),
          )
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

      final certificateHash = calculateHashOfCertificate(
        decryptData["certificate"],
      );

      /// 用户交互,验证陌生设备
      if (!(await interactiveManipulation.validateFingerprint(
        deviceFingerprint ?? certificateHash,
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
        BaseOptions(
          baseUrl: "https://$ip:${registerDto.port}",
          sendTimeout: const Duration(seconds: 3),
          contentType: "application/json",
          responseType: ResponseType.json,
          headers: {
            HttpHeaders.userAgentHeader:
                "Rpass/${option.deviceInfo.appVersion} LanFillCilent/1.0.0",
            HeadersConstant.deviceName: option.deviceInfo.deviceName,
            HeadersConstant.deviceFingerprint: option.deviceInfo.fingerprint,
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

      if (!(await heartbeat())) {
        throw Exception("Heartbeat request response fail");
      }

      return;
    }

    throw Exception(
      "Not in the same network environment as the server Or the server is down",
    );
  }

  Future<bool> heartbeat() async {
    _heartbeatTimer?.cancel();
    final dio = _getDio();
    try {
      final res = await dio.get("/api/heartbeat");
      _connecting = res.statusCode == HttpStatus.ok;
    } catch (e) {
      _connecting = false;
    }

    if (!_connecting) {
      return false;
    }

    _heartbeatTimer = Timer(option.heartbeatDuration, heartbeat);
    return _connecting;
  }
}
