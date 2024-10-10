import 'kdbx.dart';

class KdbxError extends Error {
  KdbxError([this.message]);

  final Object? message;

  @override
  String toString() {
    if (message != null) {
      return "KdbxError failed: ${Error.safeToString(message)}";
    }
    return "KdbxError failed";
  }
}

enum KdbxExceptionCode { NeverLeave_RecycleBin }

class KdbxException implements Exception {
  final dynamic message;
  final KdbxExceptionCode? code;

  KdbxException([this.message, this.code]);

  @override
  String toString() {
    return "KdbxException {code: $code, message: $message}";
  }
}

class _ParseObject {
  _ParseObject({this.field, required this.value});

  final String? field;
  final String value;

  Map<String, String?> toJson() {
    return {"field": field, "value": value};
  }
}

extension _SplitReserveSeparators on String {
  List<String> splitRS(Pattern pattern) {
    final List<String> result = [];
    int lastIndex = 0;

    for (var match in pattern.allMatches(this)) {
      final value = substring(lastIndex, match.start);
      if (value.isNotEmpty) result.add(value);
      result.add(match.group(0)!);
      lastIndex = match.end;
    }
    if (substring(lastIndex).isNotEmpty) {
      result.add(substring(lastIndex));
    }

    return result;
  }
}

class InputParse {
  InputParse(this.objects);

  final List<_ParseObject> objects;

  factory InputParse.parse(String input, Map<String, String> mapFieldTable) {
    return InputParse(_parse(input.trim(), mapFieldTable));
  }

  static List<_ParseObject> _parse(
    String input,
    Map<String, String> mapFieldTable,
  ) {
    final table = mapFieldTable.map((key, value) => MapEntry("$key:", value));

    if (!input.contains(RegExp("(?<field>${table.keys.join("|")})"))) {
      return [_ParseObject(value: input)];
    }

    final List<_ParseObject> objects = [];

    final fieldPattern = RegExp("^(?<field>${table.keys.join("|")})");
    final patterns = input.splitRS(RegExp(r'\s+(?=(?:[^"]*"[^"]*")*[^"]*$)'));
    String? nonFieldValue;
    bool lastField = false;
    for (var text in patterns) {
      final match = fieldPattern.firstMatch(text);
      if (match != null) {
        if (nonFieldValue != null) {
          if (!lastField) {
            objects.add(_ParseObject(value: nonFieldValue));
          }
          nonFieldValue = null;
        }

        final field = match.namedGroup("field")!;
        String value = text.substring(match.end);

        if (value.startsWith('"') && value.endsWith('"')) {
          value = value.substring(1, value.length - 1);
        }

        objects.add(_ParseObject(field: table[field], value: value));

        lastField = true;
      } else {
        if (nonFieldValue == null) {
          nonFieldValue = text;
        } else {
          nonFieldValue = lastField ? text : nonFieldValue + text;
          lastField = false;
        }
      }
    }

    if (nonFieldValue != null) {
      objects.add(_ParseObject(value: nonFieldValue));
    }

    return objects;
  }
}

class KbdxSearchHandler {
  KbdxSearchHandler();

  /// 对指定字段进行匹配
  /// 字段映射表, 可以缩写映射到完整字段
  final Map<String, String> _mapFieldTable = {
    // 值字段
    "t": "Title",
    "title": "Title",
    "url": "URL",
    "u": "UserName",
    "user": "UserName",
    "e": "Email",
    "email": "Email",
    "n": "Notes",
    "notes": "Notes",
    "p": "Password",
    "password": "Password",
    "otp": "OTPAuth",
    "OTPAuth": "OTPAuth",
    // 特殊字段
    "tag": "Tags",
    "g": "Group",
    "group": "Group",
  };

  final Map<String, String> _customFieldTable = {};

  bool _whereAll(KdbxEntry kdbxEntry, String value) {
    var weight = 0;
    for (var key in KdbxKeyCommon.all) {
      weight +=
          kdbxEntry.getNonNullString(key).toLowerCase().contains(value) ? 1 : 0;
    }
    weight += kdbxEntry.tagList.contains(value) ? 1 : 0;
    return weight > 0;
  }

  bool _fieldContains(List<_ParseObject> objects, KdbxEntry kdbxEntry) {
    for (var item in objects) {
      switch (item.field) {
        case null:
          if (!_whereAll(kdbxEntry, item.value.toLowerCase())) return false;
          break;
        case KdbxKeySpecial.KEY_TAGS:
          if (!kdbxEntry.tagList
              .map((item) => item.toLowerCase())
              .contains(item.value.toLowerCase())) return false;
          break;
        case "Group":
          if (item.value.isNotEmpty &&
              kdbxEntry.parent?.name.get() != item.value) return false;
          break;
        default:
          if (kdbxEntry
              .getNonNullString(KdbxKey(item.field!))
              .toLowerCase()
              .contains(item.value.toLowerCase())) return false;
          break;
      }
    }
    return true;
  }

  void setFieldOther(Set<String> fields) {
    _customFieldTable.clear();
    for (var item in fields) {
      _customFieldTable[item] = item;
    }
  }

  List<KdbxEntry> search(String input, List<KdbxEntry> sourceList) {
    final inputParse = InputParse.parse(
        input, Map.from(_mapFieldTable)..addAll(_customFieldTable));
    return sourceList
        .where((item) => _fieldContains(inputParse.objects, item))
        .toList()
      ..sort((a, b) => a.times.lastModificationTime
          .get()!
          .compareTo(b.times.lastModificationTime.get()!));
  }
}
