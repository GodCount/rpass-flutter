import 'package:flutter/material.dart';
import 'package:keepass_core/keepass_core.dart';

import '../i18n.dart';
import '../util/common.dart';
import '../util/one_time_password.dart';

export 'icons.dart';
export 'common.dart';
export 'adapter/adapter.dart';
export 'auto_type.dart';

const defaultAutoTypeSequence = "{UserName}{TAB}{Password}{ENTER}";

class KdbxKeySpecial {
  static const TAGS = 'Tags';
  static const ATTACH = 'Attach';
  static const EXPIRES = "Expires";
  static const AUTO_TYPE = "AutoType";
  static const AUTO_FILL_PACKAGE_NAME = "AutoFillPackageName";

  static List<String> all = [
    AUTO_TYPE,
    AUTO_FILL_PACKAGE_NAME,
    TAGS,
    ATTACH,
    EXPIRES,
  ];
}

class KdbxKeyCommon {
  static const TITLE = 'Title';
  static const URL = 'URL';
  static const USER_NAME = 'UserName';
  static const EMAIL = 'Email';
  static const PASSWORD = 'Password';
  static const OTP = 'OTPAuth';
  static const NOTES = 'Notes';

  // 注意顺序
  static List<String> all = [
    TITLE,
    URL,
    USER_NAME,
    EMAIL,
    PASSWORD,
    OTP,
    NOTES,
  ];

  static List<String> excludeURL = [
    TITLE,
    USER_NAME,
    EMAIL,
    PASSWORD,
    OTP,
    NOTES,
  ];
}

class KdbxKeyURLS {
  static const URL1 = 'URL1';

  static const URL2 = 'URL2';

  static const URL3 = 'URL3';

  static const URL4 = 'URL4';

  static const URL5 = 'URL5';

  static List<String> all = [URL1, URL2, URL3, URL4, URL5];
}

final defaultKdbxKeys = [
  ...KdbxKeyCommon.all,
  ...KdbxKeyURLS.all,
  ...KdbxKeySpecial.all,
];

extension KdbxEntryCommon on EntryData {
  Iterable<MapEntry<String, FieldValue>> get customEntries =>
      fields.entries.where((item) => isCustomKey(item.key));

  List<String> get moreUrlsKeys {
    final keys = fields.keys.toList();
    return KdbxKeyURLS.all.where((item) => keys.contains(item)).toList();
  }

  bool isDefaultKey(String key) => defaultKdbxKeys.contains(key);

  bool isCustomKey(String key) => !isDefaultKey(key);

  bool isExpiry() {
    return times.expires == true &&
        times.expiry != null &&
        times.expiry!.isBefore(DateTime.now());
  }

  String getNonNullString(String key) {
    return fields[key]?.get() ?? '';
  }

  String? getActualString(String key) {
    return key == KdbxKeyCommon.OTP ? getOTPCode() : fields[key]?.get();
  }

  String getLabel() {
    return getActualString(KdbxKeyCommon.TITLE)?.emptyToNull ??
        getActualString(KdbxKeyCommon.USER_NAME)?.emptyToNull ??
        getActualString(KdbxKeyCommon.EMAIL)?.emptyToNull ??
        getActualString(KdbxKeyCommon.URL) ??
        "";
  }

  List<String> getUrls() {
    return [KdbxKeyCommon.URL, ...KdbxKeyURLS.all]
        .map((item) => getActualString(item))
        .where((item) => item != null && item.isNotEmpty)
        .cast<String>()
        .toList();
  }

  String? getOTPCode() {
    final url = fields[KdbxKeyCommon.OTP]?.get();
    return url != null
        ? AuthOneTimePassword.tryParse(url)?.code().toString()
        : null;
  }

  String copyBasicString() {
    return "title: ${getNonNullString(KdbxKeyCommon.TITLE)}\n"
        "url: ${getNonNullString(KdbxKeyCommon.URL)}\n"
        "username: ${getNonNullString(KdbxKeyCommon.USER_NAME)}\n"
        "email: ${getNonNullString(KdbxKeyCommon.EMAIL)}\n"
        "password: ${getNonNullString(KdbxKeyCommon.PASSWORD)}";
  }

  Map<String, String> toPlainMapEntry() {
    return Map.fromEntries(
      KdbxKeyCommon.all.map((item) => MapEntry(item, getNonNullString(item))),
    );
  }
}

extension FieldSummaryCommon on FieldSummary {
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
        return customIcons.keys.toSet();
    }
    return {};
  }
}

extension KdbxFiledI18n on String {

  String fromKdbxKeyToI18n(BuildContext context) {
    final t = I18n.of(context)!;
    switch (this) {
      case KdbxKeyCommon.TITLE:
        return t.title;
      case KdbxKeyCommon.URL:
        return t.domain;
      case KdbxKeyURLS.URL1:
        return t.domain_num(1);
      case KdbxKeyURLS.URL2:
        return t.domain_num(2);
      case KdbxKeyURLS.URL3:
        return t.domain_num(3);
      case KdbxKeyURLS.URL4:
        return t.domain_num(4);
      case KdbxKeyURLS.URL5:
        return t.domain_num(5);
      case KdbxKeyCommon.USER_NAME:
        return t.account;
      case KdbxKeyCommon.EMAIL:
        return t.email;
      case KdbxKeyCommon.PASSWORD:
        return t.password;
      case KdbxKeyCommon.OTP:
        return t.otp;
      case KdbxKeyCommon.NOTES:
        return t.description;
      case KdbxKeySpecial.AUTO_TYPE:
        return t.fill_sequence;
      case KdbxKeySpecial.AUTO_FILL_PACKAGE_NAME:
        return t.auto_fill_match_app;
      case KdbxKeySpecial.TAGS:
        return t.label;
      case KdbxKeySpecial.ATTACH:
        return t.attachment;
      case KdbxKeySpecial.EXPIRES:
        return t.expires_time;
      default:
        return this;
    }
  }
}
