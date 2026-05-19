const defaultAutoTypeSequence = "{UserName}{TAB}{Password}{ENTER}";

class KdbxCustomDataKey {
  static const GENERAL_GROUP_UUID = 'general_group_uuid';
  static const EMAIL_GROUP_UUID = 'email_group_uuid';

  static const SYNC_ACCPUNT_UUID = "sync_account_uuid";
}

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
