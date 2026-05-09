import '../extension.dart';

class ChromeCsvAdapter extends FormatTransform {
  @override
  String get name => "Chrome";

  @override
  List<Map<String, String>> import(List<Map<String, dynamic>> input) {
    return input
        .map(
          (item) => {
            KdbxKeyCommon.URL: item["url"] as String? ?? '',
            KdbxKeyCommon.TITLE: item["name"] as String? ?? '',
            KdbxKeyCommon.USER_NAME: item["username"] as String? ?? '',
            KdbxKeyCommon.PASSWORD: item["password"] as String? ?? '',
            KdbxKeyCommon.NOTES: item["note"] as String? ?? '',
          },
        )
        .toList();
  }

  @override
  List<Map<String, dynamic>> export(List<Map<String, String>> input) {
    return input
        .map(
          (item) => {
            "url": item[KdbxKeyCommon.URL],
            "name": item[KdbxKeyCommon.TITLE],
            "username": item[KdbxKeyCommon.USER_NAME],
            "password": item[KdbxKeyCommon.PASSWORD],
            "note": item[KdbxKeyCommon.NOTES],
          },
        )
        .toList();
  }
}
