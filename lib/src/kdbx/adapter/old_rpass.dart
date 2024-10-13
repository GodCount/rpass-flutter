import '../kdbx.dart';

class OldRpassAdapter extends FormatTransform {
  @override
  String get name => "OldRpass";

  @override
  List<Map<KdbxKey, String>> import(List<Map<String, dynamic>> input) {
    return input
        .map((item) => {
              KdbxKeyCommon.URL: item["domain"] as String? ?? '',
              KdbxKeyCommon.TITLE: item["domainName"] as String? ?? '',
              KdbxKeyCommon.USER_NAME: item["account"] as String? ?? '',
              KdbxKeyCommon.EMAIL: item["email"] as String? ?? '',
              KdbxKeyCommon.PASSWORD: item["password"] as String? ?? '',
              KdbxKeyCommon.OTP: item["oneTimePassword"] as String? ?? '',
              KdbxKeyCommon.NOTES: item["description"] as String? ?? '',
              KdbxKeySpecial.TAGS: (item["labels"] as List<String>?)?.join(";") ?? '',
            })
        .toList();
  }

  @override
  List<Map<String, dynamic>> export(List<Map<KdbxKey, String>> input) {
    throw UnimplementedError();
  }
}
