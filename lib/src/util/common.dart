import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart' as crypto;
import 'package:uuid/uuid.dart';
import 'package:encrypt/encrypt.dart';

const uuid = Uuid();
final IV iv = IV.fromUtf8("9" * 16);

const letters = r"qwertyuiopasdfghjklzxcvbnm";
const numbers = r"0123456789";
const symbols = r"!@#$%^&*_-=+'(),./\:;<>?[]`{}|~"
    r'"';

class EmptyError extends Error {
  final String message;
  EmptyError(this.message);
}

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

int randomInt(int min, int max) => min + math.Random().nextInt(max - min);

String randomPassword({
  required int length,
  bool enableNumber = true,
  bool enableSymbol = true,
  bool enableLetterUppercase = true,
  bool enableLetterLowercase = true,
}) {
  final List<String> values = [];

  if (enableLetterUppercase) {
    values.addAll(letters.toUpperCase().split(""));
  }

  if (enableLetterLowercase) {
    values.addAll(letters.split(""));
  }

  if (enableNumber) {
    values.addAll(numbers.split(""));
  }

  if (enableSymbol) {
    values.addAll(symbols.split(""));
  }

  values
      .sort((a, b) => math.Random().nextInt(100) - math.Random().nextInt(100));

  if (values.isEmpty) {
    throw EmptyError("enable at least one type");
  }

  String password = "";

  for (var i = 0; i < length; i++) {
    password += values[randomInt(0, values.length)];
  }

  return password;
}

class Debouncer {
  Debouncer({this.duration = const Duration(seconds: 1)});

  final Duration duration;

  Timer? _timer;
  Function? func;

  void debounce(Function func) {
    if (_timer == null) {
      func.call();
      _debounceClear();
    } else {
      this.func = func;
      _timer?.cancel();
      _timer = Timer(duration, () {
        if (this.func != null) {
          this.func!.call();
        }
        _debounceClear();
      });
    }
  }

  void _debounceClear() {
    _timer?.cancel();
    _timer = Timer(duration, () {
      _timer?.cancel();
      _timer = null;
    });
  }

  void dispose() {
    _timer?.cancel();
  }
}
