import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;

String md5(String data) {
  return crypto.md5.convert(utf8.encode(data)).toString();
}
