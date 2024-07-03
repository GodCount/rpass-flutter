import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:uuid/uuid.dart';
import 'package:encrypt/encrypt.dart';

const uuid = Uuid();
final IV iv = IV.fromUtf8("9" * 16);

String md5(String data) {
  return crypto.md5.convert(utf8.encode(data)).toString();
}

String aesEncrypt(String key, String data) {
  final encrypter = Encrypter(AES(Key.fromUtf8(key), mode: AESMode.cbc));

  final encrypted = encrypter.encrypt(data, iv: iv);

  return encrypted.base64;
}

String aesDenrypt(String key, String data) {
  final encrypter = Encrypter(AES(Key.fromUtf8(key), mode: AESMode.cbc));

  return encrypter.decrypt(Encrypted.fromBase64(data), iv: iv);
}

Iterable<String> aesEncryptList(String key, Iterable<String> list) {
  final encrypter = Encrypter(AES(Key.fromUtf8(key), mode: AESMode.cbc));
  return list.map((item) => encrypter.encrypt(item, iv: iv).base64);
}

Iterable<String> aesDenryptList(String key, Iterable<String> list) {
  final encrypter = Encrypter(AES(Key.fromUtf8(key), mode: AESMode.cbc));
  return list
      .map((item) => encrypter.decrypt(Encrypted.fromBase64(item), iv: iv));
}

String timeBasedUuid() {
  return uuid.v1();
}
