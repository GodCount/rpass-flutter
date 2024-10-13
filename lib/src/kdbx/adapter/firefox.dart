import '../kdbx.dart';

class FirefoxCsvAdapter extends FormatTransform {
  @override
  String get name => "Firefox";

  @override
  List<Map<KdbxKey, String>> import(List<Map<String, dynamic>> input) {
    return input
        .map((item) => {
              KdbxKeyCommon.URL: item["url"] as String? ?? '',
              KdbxKeyCommon.USER_NAME: item["username"] as String? ?? '',
              KdbxKeyCommon.PASSWORD: item["password"] as String? ?? '',
            })
        .toList();
  }

  @override
  List<Map<String, dynamic>> export(List<Map<KdbxKey, String>> input) {
    return input
        .map((item) => {
              "url": item[KdbxKeyCommon.URL],
              "username": item[KdbxKeyCommon.USER_NAME],
              "password": item[KdbxKeyCommon.PASSWORD],
            })
        .toList();
  }
}
