import 'package:json_annotation/json_annotation.dart';

class JsonDateTimeConverterNonNullable
    implements JsonConverter<DateTime, dynamic> {
  const JsonDateTimeConverterNonNullable();

  @override
  DateTime fromJson(dynamic timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(
      timestamp is int ? timestamp : int.parse(timestamp.toString()),
      isUtc: false,
    );
  }

  @override
  int toJson(DateTime object) {
    return object.millisecondsSinceEpoch;
  }
}

class JsonUrlConverter implements JsonConverter<String, String> {
  const JsonUrlConverter();

  @override
  String fromJson(String url) {
    return url;
  }

  @override
  String toJson(String url) {
    if (url.startsWith("http")) return url;
    return "https://$url";
  }
}

enum BackupType {
  rpass,
  chrome,
  firefox,
}
