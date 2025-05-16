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

class ParseObject {
  ParseObject({this.field, required this.value});

  final String? field;
  final String value;

  @override
  bool operator ==(Object other) {
    return other is ParseObject && other.field == field && other.value == value;
  }

  @override
  int get hashCode => "$field$value".hashCode;

  @override
  String toString() {
    return 'ParseObject{field: $field, value: $value}';
  }
}

class InputParse {
  InputParse(this.objects);

  final List<ParseObject> objects;

  factory InputParse.parse(String input, Map<String, String> mapFieldTable) {
    return InputParse(_parse(input.trim(), mapFieldTable));
  }

  static List<ParseObject> _parse(
    String str,
    Map<String, String> mapFieldTable,
  ) {
    final table = mapFieldTable.map((key, value) => MapEntry("$key:", value));

    final spacePattern = RegExp(r"\s+");
    final quotePattern = RegExp(r'(?:(?<=\s+|^)")(?<value>.*?)(?:"(?=\s+|$))');
    final fieldPattern = RegExp("^(?<field>${table.keys.join("|")})");

    int i = 0;
    final Set<ParseObject> result = {};
    while (i < str.length) {
      String? field;
      String part = str.substring(i);
      final fieldMatch = fieldPattern.firstMatch(part);

      if (fieldMatch != null) {
        field = table[fieldMatch.namedGroup("field")];
        i += fieldMatch.end;
        part = str.substring(i);
      }

      final spaceMatch = spacePattern.firstMatch(part);
      final quoteMatch = quotePattern.firstMatch(part);

      if (spaceMatch == null) {
        result.add(ParseObject(
          field: field,
          value: quoteMatch?.namedGroup("value") ?? part,
        ));
        break;
      }

      if (quoteMatch == null || spaceMatch.start < quoteMatch.start) {
        if (spaceMatch.start > 0) {
          result.add(ParseObject(
            field: field,
            value: part.substring(0, spaceMatch.start),
          ));
        }
        i += spaceMatch.end;
        continue;
      }

      result.add(ParseObject(
        field: field,
        value: quoteMatch.namedGroup("value") ?? "",
      ));
      i += quoteMatch.end;
    }

    return result.toList();
  }
}

class KbdxSearchHandler {
  KbdxSearchHandler({
    this.useKdbxEntryConfig = false,
  });

  /// 对指定字段进行匹配
  /// 字段映射表, 可以缩写映射到完整字段
  static final Map<String, String> MAP_FIELD_TABLE = {
    // 值字段
    "t": "Title",
    "title": "Title",
    "url": "URL",
    "u": "UserName",
    "user": "UserName",
    "e": "Email",
    "email": "Email",
    "n": "Notes",
    "note": "Notes",
    "p": "Password",
    "password": "Password",
    "otp": "OTPAuth",
    "OTPAuth": "OTPAuth",
    // 特殊字段
    "tag": "Tags",
    "g": "Group",
    "group": "Group",
  };

  /// 使用 enableDisplay , enableSearching 过滤列表
  final bool useKdbxEntryConfig;

  final Map<String, String> _customFieldTable = {};

  bool _allContains(KdbxEntry kdbxEntry, String value) {
    var weight = 0;
    for (var key in KdbxKeyCommon.all) {
      weight +=
          kdbxEntry.getNonNullString(key).toLowerCase().contains(value) ? 1 : 0;
    }
    weight += kdbxEntry.tagList.contains(value) ? 1 : 0;
    return weight > 0;
  }

  bool _fieldContains(Iterable<ParseObject> objects, KdbxEntry kdbxEntry) {
    for (var item in objects) {
      switch (item.field) {
        case null:
          if (!_allContains(kdbxEntry, item.value.toLowerCase())) return false;
          break;
        case KdbxKeySpecial.KEY_TAGS:
          if (!kdbxEntry.tagList
              .map((item) => item.toLowerCase())
              .contains(item.value.toLowerCase())) {
            return false;
          }
          break;
        case "Group":
          if (item.value.isNotEmpty &&
              kdbxEntry.parent?.name.get() != item.value) {
            return false;
          }
          break;
        default:
          if (!kdbxEntry
              .getNonNullString(KdbxKey(item.field!))
              .toLowerCase()
              .contains(item.value.toLowerCase())) {
            return false;
          }
          break;
      }
    }
    return true;
  }

  void setFieldOther(Set<String> fields) {
    _customFieldTable.clear();
    for (var item in fields) {
      _customFieldTable[RegExp.escape(item)] = item;
    }
  }

  List<KdbxEntry> search(String input, Iterable<KdbxEntry> sourceList) {
    final isSearch = input.isNotEmpty;

    Iterable<KdbxEntry> result = sourceList;

    if (isSearch) {
      final inputParse = InputParse.parse(
        input,
        Map.from(MAP_FIELD_TABLE)..addAll(_customFieldTable),
      );

      sourceList.where((item) {
        if (useKdbxEntryConfig && !item.enableSearching()) {
          return false;
        }
        return _fieldContains(inputParse.objects, item);
      });
    } else if (useKdbxEntryConfig) {
      result = sourceList.where((item) => item.enableDisplay());
    }

    return result.toList()
      ..sort((a, b) => b.times.lastModificationTime
          .get()!
          .compareTo(a.times.lastModificationTime.get()!));
  }
}

abstract class FormatTransform {
  String get name;

  List<Map<KdbxKey, String>> import(List<Map<String, dynamic>> input);

  List<Map<String, dynamic>> export(List<Map<KdbxKey, String>> input);
}
