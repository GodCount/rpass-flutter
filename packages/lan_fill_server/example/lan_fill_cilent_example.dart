import 'dart:convert';
import 'dart:io';

import 'package:lan_fill_server/src/util/security_helper.dart';

void log(Object? object) {
  print(object);
}

final context = generateSecurityContext();

class LanFillServer {
  Future<void> start([StoredSecurityContext? storedSecurity]) async {
    storedSecurity ??= generateSecurityContext();

    log("server certificateHash==> ${storedSecurity.certificateHash}");

    final context = SecurityContext()
      ..useCertificateChainBytes(storedSecurity.certificateBytes)
      ..usePrivateKeyBytes(storedSecurity.privateKeyBytes)
      ..setTrustedCertificatesBytes(storedSecurity.certificateBytes);

    final server = await HttpServer.bindSecure(
      InternetAddress.anyIPv4,
      3234,
      context,
      requestClientCertificate: true,
    );

    log('https://localhost:${server.port}');

    await for (final request in server) {
      final body = await utf8.decoder.bind(request).join();

      log(
        "request method ${request.method} url ${request.uri} query ${request.uri.query} $body",
      );

      if (request.certificate == null) {
        request.response
          ..statusCode = 401
          ..write("No client certificate")
          ..close();
        continue;
      }

      log("server request ${request.certificate!.pem}");

      request.response
        ..statusCode = 200
        ..write("done")
        ..close();
    }
  }
}

class LanFillCilent {
  late HttpClient _client;

  Future<HttpClient> _createHttpClient([
    StoredSecurityContext? storedSecurity,
  ]) async {
    storedSecurity ??= generateSecurityContext();

    log("cilent certificateHash==> ${storedSecurity.certificateHash}");

    final context = SecurityContext()
      ..useCertificateChainBytes(storedSecurity.certificateBytes)
      ..usePrivateKeyBytes(storedSecurity.privateKeyBytes)
      ..setTrustedCertificatesBytes(storedSecurity.certificateBytes);

    return HttpClient(context: context);
      // ..badCertificateCallback =
      //     (X509Certificate certificate, String host, int port) {
      //       log(
      //         "badCertificateCallback pem hash==> ${calculateHashOfCertificate(certificate.pem)}",
      //       );
      //       log(
      //         "badCertificateCallback der hash==> ${der2sha256(certificate.der)}",
      //       );
      //       return false;
      //     };
  }

  Future<void> start([StoredSecurityContext? storedSecurity]) async {
    _client = await _createHttpClient(storedSecurity);
  }

  Future<void> fetch(Uri uri) async {
    final request = await _client.getUrl(uri);
    request.contentLength = 5;
    request.add(utf8.encode("aaaaa"));
    final response = await request.close();

    log("response certificate ${response.certificate?.pem}");
    final body = await utf8.decoder.bind(response).join();
    log("response body $body");
  }
}

Future<void> main() async {
  LanFillServer().start(context);
  final cilent = LanFillCilent();

  await cilent.start(context);

  await cilent.fetch(Uri.parse("https://localhost:3234"));

  await Future.delayed(Duration(seconds: 5));
}
