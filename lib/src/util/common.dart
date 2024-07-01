import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart';

String md5(String data) {
  return crypto.md5.convert(utf8.encode(data)).toString();
}

String aesEncrypt(String key, String data) {
  final encrypter = Encrypter(AES(Key.fromUtf8(key), mode: AESMode.cbc));

  final encrypted = encrypter.encrypt(data, iv: IV.fromUtf8("999"));

  return encrypted.base64;
}

String aesDenrypt(String key, String data) {
  final encrypter = Encrypter(AES(Key.fromUtf8(key), mode: AESMode.cbc));

  return encrypter.decrypt(Encrypted.fromBase64(data), iv: IV.fromUtf8("999"));
}
