import 'package:json_annotation/json_annotation.dart';


class JsonDateTimeConverterNonNullable implements JsonConverter<DateTime, int> {
  const JsonDateTimeConverterNonNullable();

  @override
  DateTime fromJson(int timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: false);
  }

  @override
  int toJson(DateTime object) {
    return object.millisecondsSinceEpoch;
  }
}