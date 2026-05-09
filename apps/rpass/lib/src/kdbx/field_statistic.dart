import 'extension.dart';
import 'kdbx.dart';

class FieldStatistic {
  FieldStatistic._({
    Set<String>? urls,
    Set<String>? userNames,
    Set<String>? emails,
    Set<String>? tags,
    Set<String>? customFields,
    Set<String>? customIcons,
  }) : urls = urls ?? {},
       userNames = userNames ?? {},
       emails = emails ?? {},
       tags = tags ?? {},
       customFields = customFields ?? {},
       customIcons = customIcons ?? {};

  static FieldStatistic? _fieldStatistic;

  final Set<String> urls;
  final Set<String> userNames;
  final Set<String> emails;
  final Set<String> tags;
  final Set<String> customFields;
  final Set<String> customIcons;

  Set<String> getStatistic(String kdbxKey) {
    switch (kdbxKey) {
      case KdbxKeyCommon.URL:
      case KdbxKeyURLS.URL1:
      case KdbxKeyURLS.URL2:
      case KdbxKeyURLS.URL3:
      case KdbxKeyURLS.URL4:
      case KdbxKeyURLS.URL5:
        return urls;
      case KdbxKeyCommon.USER_NAME:
        return userNames;
      case KdbxKeyCommon.EMAIL:
        return emails;
      case KdbxKeySpecial.TAGS:
        return tags;
      case "CustomFields":
        return customFields;
      case "CustomIcons":
        return customIcons;
    }
    return {};
  }

  static FieldStatistic statistic(KdbxBase kdbx, [bool? force]) {
    if (force != true || _fieldStatistic != null) {
      return _fieldStatistic!;
    }

    _fieldStatistic = FieldStatistic._();

    _fieldStatistic!.customIcons.addAll(
      kdbx.customIcons.entries.map((item) => item.key.string),
    );

    void setFieldStatistic(KdbxEntry entry) {
      final url = entry.getActualString(KdbxKeyCommon.URL);
      final userName = entry.getActualString(KdbxKeyCommon.USER_NAME);
      final email = entry.getActualString(KdbxKeyCommon.EMAIL);

      url != null && url.isNotEmpty && _fieldStatistic!.urls.add(url);

      userName != null &&
          userName.isNotEmpty &&
          _fieldStatistic!.userNames.add(userName);

      email != null && email.isNotEmpty && _fieldStatistic!.emails.add(email);

      _fieldStatistic!.tags.addAll(entry.tagList);

      for (final key in entry.fields.keys) {
        if (entry.isCustomKey(key)) {
          _fieldStatistic!.customFields.add(key);
        } else if (KdbxKeyURLS.all.contains(key)) {
          final url = entry.getActualString(key);
          if (url != null && url.isNotEmpty) {
            _fieldStatistic!.urls.add(url);
          }
        }
      }
    }

    kdbx.totalEntry.forEach(setFieldStatistic);
    return _fieldStatistic!;
  }
}
