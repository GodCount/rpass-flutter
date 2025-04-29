import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart' as crypto;
import 'package:csv/csv.dart';
import 'package:csv/csv_settings_autodetection.dart';
import 'package:encrypt/encrypt.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

final bool isMobile = Platform.isAndroid || Platform.isIOS;
final bool isDesktop = !isMobile;

const uuid = Uuid();

@Deprecated("old data encrypt")
final IV iv = IV.fromUtf8("9" * 16);

const letters = r"qwertyuiopasdfghjklzxcvbnm";
const numbers = r"0123456789";
const symbols = r"!@#$%^&*_-=+'(),./\:;<>?[]`{}|~"
    r'"';

const storageUnitSuffixes = [
  "B",
  "KB",
  "MB",
  "GB",
  "TB",
  "PB",
  "EB",
  "ZB",
  "YB",
];

String md5(String data) {
  return crypto.md5.convert(utf8.encode(data)).toString();
}

@Deprecated(
  "old data encrypt"
  "move kdbx",
)
String aesEncrypt(String key, String data) {
  final encrypter = Encrypter(AES(Key.fromUtf8(key), mode: AESMode.cbc));

  final encrypted = encrypter.encrypt(data, iv: iv);

  return encrypted.base64;
}

@Deprecated(
  "old data encrypt"
  "move kdbx",
)
String aesDenrypt(String key, String data) {
  final encrypter = Encrypter(AES(Key.fromUtf8(key), mode: AESMode.cbc));

  return encrypter.decrypt(Encrypted.fromBase64(data), iv: iv);
}

@Deprecated(
  "old data encrypt"
  "move kdbx",
)
Iterable<String> aesEncryptList(String key, Iterable<String> list) {
  final encrypter = Encrypter(AES(Key.fromUtf8(key), mode: AESMode.cbc));
  return list.map((item) => encrypter.encrypt(item, iv: iv).base64);
}

@Deprecated(
  "old data encrypt"
  "move kdbx",
)
Iterable<String> aesDenryptList(String key, Iterable<String> list) {
  final encrypter = Encrypter(AES(Key.fromUtf8(key), mode: AESMode.cbc));
  return list
      .map((item) => encrypter.decrypt(Encrypted.fromBase64(item), iv: iv));
}

@Deprecated(
  "old data encrypt"
  "move kdbx",
)
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

  final List<String> cahrs = [];

  if (enableLetterUppercase) {
    final list = letters.toUpperCase().split("");
    cahrs.addAll(list);
    values.add(list[randomInt(0, list.length)]);
  }

  if (enableLetterLowercase) {
    final list = letters.split("");
    cahrs.addAll(list);
    values.add(list[randomInt(0, list.length)]);
  }

  if (enableNumber) {
    final list = numbers.split("");
    cahrs.addAll(list);
    values.add(list[randomInt(0, list.length)]);
  }

  if (enableSymbol) {
    final list = symbols.split("");
    cahrs.addAll(list);
    values.add(list[randomInt(0, list.length)]);
  }

  if (cahrs.isEmpty) {
    throw Exception("enable at least one type");
  }

  cahrs.sort((a, b) => math.Random().nextInt(2));

  if (values.length >= length) {
    values.sort((a, b) => math.Random().nextInt(2));
    return values.sublist(0, length).join("");
  }

  length -= values.length;
  for (var i = 0; i < length; i++) {
    values.add(cahrs[randomInt(0, cahrs.length)]);
  }
  values.sort((a, b) => math.Random().nextInt(2));

  return values.join("");
}

List<Map<String, dynamic>> csvToJson(
  String csv, {
  String? fieldDelimiter,
  String? textDelimiter,
  String? textEndDelimiter,
  String? eol,
  CsvSettingsDetector? csvSettingsDetector,
  bool? shouldParseNumbers,
  bool? allowInvalid,
  var convertEmptyTo,
}) {
  final list2 = const CsvToListConverter().convert(
    csv,
    fieldDelimiter: fieldDelimiter,
    textDelimiter: textDelimiter,
    textEndDelimiter: textEndDelimiter,
    eol: eol,
    csvSettingsDetector: csvSettingsDetector,
    shouldParseNumbers: shouldParseNumbers,
    allowInvalid: allowInvalid,
    convertEmptyTo: convertEmptyTo,
  );

  final fields = list2.first;

  final List<Map<String, dynamic>> results = [];

  for (var i = 1; i < list2.length; i++) {
    final item = list2[i];
    final Map<String, dynamic> result = {};
    for (var j = 0; j < fields.length; j++) {
      result[fields[j]] = item[j];
    }
    results.add(result);
  }

  return results;
}

String jsonToCsv(
  List<Map<String, dynamic>> list, {
  String? fieldDelimiter,
  String? textDelimiter,
  String? textEndDelimiter,
  String? eol,
  bool? delimitAllFields,
  var convertNullTo,
}) {
  final fields = list.first.keys.toList();
  final List<List> results = [fields];
  for (var item in list) {
    results.add(item.values.toList());
  }
  return const ListToCsvConverter().convert(
    results,
    fieldDelimiter: fieldDelimiter,
    textDelimiter: textDelimiter,
    textEndDelimiter: textEndDelimiter,
    eol: eol,
    delimitAllFields: delimitAllFields,
    convertNullTo: convertNullTo,
  );
}

class CommonRegExp {
  static final RegExp domain = RegExp(r"^(https?:\/\/)?(\w+)\..+");
  static final RegExp email = RegExp(
    r"(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'"
    r'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-'
    r'\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*'
    r'[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4]'
    r'[0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9]'
    r'[0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\'
    r'x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])',
  );

  static final RegExp oneTimePassword = RegExp(r"^otpauth://totp/.+");
}

/// Simple string to enum
extension StringToEnum<T extends Enum> on Iterable<T> {
  T toEnum(String name, [T? defaultValue]) {
    for (var value in this) {
      if (value.name == name) return value;
    }
    if (defaultValue != null) return defaultValue;
    throw ArgumentError('No enum value found for "$name" in $T');
  }

  T? optEnum(String name, [T? defaultValue]) {
    for (var value in this) {
      if (value.name == name) return value;
    }
    if (defaultValue != null) return defaultValue;
    return null;
  }
}

/// format

String bytesFormat(num bytes, [int decimals = 1]) {
  if (bytes <= 0) return "0 B";
  final i = (math.log(bytes) / math.log(1024)).floor();
  return "${(bytes / math.pow(1024, i)).toStringAsFixed(decimals)} ${storageUnitSuffixes[i]}";
}

extension BytesFormatByInt on num {
  String get bytesToBestUnit => bytesFormat(this);
}

String dateFormat(DateTime date, [bool time = true]) {
  if (time) return DateFormat("yyyy.MM.dd HH:mm:ss").format(date);
  return DateFormat("yyyy.MM.dd").format(date);
}

extension DateFormatByTime on DateTime {
  String get formatDate => dateFormat(this);
}

extension RepeatObject<T> on T {
  List<T> repeat(int len) {
    if (len <= 0) return [];
    return List.filled(len, this);
  }
}
