import 'dart:convert';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';

class StoredSecurityContext {
  StoredSecurityContext({
    required this.privateKey,
    required this.publicKey,
    required this.certificate,
    required this.certificateHash,
  });

  final String privateKey;
  final String publicKey;
  final String certificate;
  final String certificateHash;

  Uint8List get certificateBytes => utf8.encode(certificate);
  Uint8List get privateKeyBytes => utf8.encode(privateKey);

  factory StoredSecurityContext.formJson(Map<String, dynamic> map) {
    return StoredSecurityContext(
      privateKey: map["privateKey"] as String,
      publicKey: map["publicKey"] as String,
      certificate: map["certificate"] as String,
      certificateHash: map["certificateHash"] as String,
    );
  }

  Map<String, String> toJson() {
    return {
      privateKey: privateKey,
      publicKey: publicKey,
      certificate: certificate,
      certificateHash: certificateHash,
    };
  }
}

StoredSecurityContext generateSecurityContext() {
  final keyPair = CryptoUtils.generateRSAKeyPair();
  final privateKey = keyPair.privateKey as RSAPrivateKey;
  final publicKey = keyPair.publicKey as RSAPublicKey;
  final dn = {'CN': 'Rpass User', 'O': '', 'OU': '', 'L': '', 'S': '', 'C': ''};
  final csr = X509Utils.generateRsaCsrPem(dn, privateKey, publicKey);
  final certificate = X509Utils.generateSelfSignedCertificate(
    keyPair.privateKey,
    csr,
    365 * 10,
  );
  final hash = calculateHashOfCertificate(certificate);

  return StoredSecurityContext(
    privateKey: CryptoUtils.encodeRSAPrivateKeyToPemPkcs1(privateKey),
    publicKey: CryptoUtils.encodeRSAPublicKeyToPemPkcs1(publicKey),
    certificate: certificate,
    certificateHash: hash,
  );
}

/// Calculates the hash of a certificate.
String calculateHashOfCertificate(String certificate) {
  // Convert PEM to DER
  final pemContent = certificate
      .replaceAll('\r\n', '\n')
      .split('\n')
      .where((line) => line.isNotEmpty && !line.startsWith('---'))
      .join();
  final der = base64Decode(pemContent);

  return der2sha256(Uint8List.fromList(der));
}

String der2sha256(Uint8List der) {
  return CryptoUtils.getHash(der, algorithmName: 'SHA-256');
}
