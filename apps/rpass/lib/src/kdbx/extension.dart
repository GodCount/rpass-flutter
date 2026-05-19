import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:kpasslib/kpasslib.dart';

import '../i18n.dart';
import '../native/platform/android.dart';
import '../util/common.dart';
import '../util/one_time_password.dart';
import 'auto_fill.dart';
import 'constants.dart';
import 'icons.dart';

enum _FindEnabledType { display, searching }

extension KdbxCredentialsCommon on KdbxCredentials {
  Uint8List getHashUint8() {
    return Uint8List.fromList(getHash());
  }
}

extension KdbxDatabaseCommon on KdbxDatabase {
  // 是不带垃圾箱组的
  List<KdbxGroup> get rootGroups =>
      groups.where((group) => !isInRecycleBin(group)).toList(growable: false);

  // 除垃圾桶的全部 KdbxEntry
  List<KdbxEntry> get totalEntry => [
    ...rootGroups.expand((group) => group.allEntries),
  ];

  List<KdbxItem> get recycleBinObjects => _getRecycleBinOrCreate().allItems;

  KdbxEntry? get syncAccountEntry =>
      meta.customData.get(KdbxCustomDataKey.SYNC_ACCPUNT_UUID) != null
      ? findEntryByUuid(
          meta.customData.get(KdbxCustomDataKey.SYNC_ACCPUNT_UUID)!.kdbxUuid,
        )
      : null;

  set syncAccountEntry(KdbxEntry? entry) {
    meta.customData.set(
      KdbxCustomDataKey.SYNC_ACCPUNT_UUID,
      entry != null ? entry.uuid.string : KdbxUuid.zero.string,
    );
  }

  KdbxGroup _getRecycleBinOrCreate() {
    meta.recycleBinEnabled = true;
    return recycleBin!;
  }

  KdbxEntry? findEntryByUuid(KdbxUuid uuid) {
    try {
      return totalEntry.firstWhere((group) => group.uuid == uuid);
    } catch (e) {
      return null;
    }
  }

  void deletePermanently(KdbxItem item) {
    // 不指定目标组, 则会永久删除
    move(item: item);
  }

  void restoreObject(KdbxItem item) {
    KdbxGroup? prveGroup;

    prveGroup = getGroup(uuid: item.previousParent) ?? root;
    if (isInRecycleBin(prveGroup)) {
      prveGroup = root;
    }

    move(item: item, target: prveGroup);
  }

  bool isInRecycleBin(KdbxItem item) {
    final rb = recycleBin;
    return rb != null && (rb.uuid == item.uuid || rb.allItems.contains(item));
  }
}

extension KdbxItemCommon on KdbxItem {
  IconData toMaterialIcon() {
    return KdbxIcon2Material.to(icon);
  }

  Uint8List? getCustomIcon(KdbxDatabase db) {
    final data = customIcon != null
        ? db.meta.customIcons[customIcon]?.data
        : null;
    return data != null ? Uint8List.fromList(data) : null;
  }

  void setCustomIcon(KdbxDatabase db, {KdbxUuid? uuid, KdbxCustomIcon? icon}) {
    if (uuid != null && db.meta.customIcons.containsKey(uuid)) {
      customIcon = uuid;
      return;
    } else if (icon != null) {
      customIcon = KdbxUuid.random(
        prohibited: db.meta.customIcons.keys.toSet(),
      );
      db.meta.customIcons[customIcon!] = icon;
    } else {
      customIcon = null;
    }
  }
}

extension KdbxGroupCommon on KdbxGroup {
  bool? get enableSearching => isSearchingEnabled;
  set enableSearching(bool? value) {
    isSearchingEnabled = value;
  }

  // TODO! 是否在密码列表显示, enableDisplay kdbx规范中是没有的. 需要做一下扩展
  // 暂时是用 isExpanded 这表示是否展开组, 在我这里表示是否显示到密码列表
  bool? get enableDisplay => isExpanded;
  set enableDisplay(bool? value) {
    isExpanded = value;
  }
}

extension KdbxEntryCommon on KdbxEntry {
  void setString(
    String key, {
    String? value,
    bool? protected,
    KdbxMemoryProtection? protection,
  }) {
    final exist = fields.containsKey(key);
    if (value == null) {
      if (exist) fields.remove(key);
      return;
    }
    if (protected != null) {
      fields[key] = KdbxTextField.fromText(text: value, protected: protected);
    } else if (exist) {
      fields[key] = KdbxTextField.fromText(
        text: value,
        protected: fields[key] is ProtectedTextField,
      );
    } else {
      fields[key] = KdbxTextField.fromText(
        text: value,
        protected: switch (key) {
          KdbxKeyCommon.TITLE => protection?.title,
          KdbxKeyCommon.USER_NAME => protection?.userName,
          KdbxKeyCommon.PASSWORD => protection?.password,
          KdbxKeyCommon.URL => protection?.url,
          KdbxKeyCommon.NOTES => protection?.notes,
          _ => null,
        },
      );
    }
  }

  void renameKey(String key, String oldKey) {}

  void removeBinary(String key) {
    if (binaries.containsKey(key)) {
      binaries.remove(key);
    }
  }

  void addBinary(
    KdbxDatabase db, {
    required String key,
    required KdbxDataBinary binary,
  }) {
    binaries[key] = db.binaries.add(binary);
  }

  KdbxEntry clone([KdbxGroup? target]) {
    final entry = KdbxEntry.copyFrom(this, KdbxUuid.random());
    entry.parent = target ?? entry.parent;
    if (entry.parent != null && !entry.parent!.entries.contains(entry)) {
      entry.parent!.entries.add(entry);
    }
    return entry;
  }

  List<String> get tagList => tags ?? [];

  set tagList(List<String> list) => tags = list;

  void addTag(String value) {
    if (!tagList.contains(value)) {
      tags = [...tagList, value];
    }
  }

  void removeTag(String value) {
    final tmpTagList = tagList;
    if (tmpTagList.remove(value)) {
      tags = tmpTagList;
    }
  }

  Map<String, String> toPlainMapEntry() {
    return Map.fromEntries(
      KdbxKeyCommon.all.map((item) => MapEntry(item, getNonNullString(item))),
    );
  }

  List<String> get customEntries =>
      fields.keys.where((item) => isCustomKey(item)).toList();

  List<String> get moreUrlsKeys {
    return KdbxKeyURLS.all.where((item) => fields.keys.contains(item)).toList();
  }

  bool isDefaultKey(String key) => defaultKdbxKeys.contains(key);

  bool isCustomKey(String key) => !isDefaultKey(key);

  bool isExpiry() {
    return times.expires && times.expiry.isBefore(KdbxTime.now());
  }

  String getNonNullString(String key) {
    return fields[key]?.text ?? '';
  }

  String? getActualString(String key) {
    return key == KdbxKeyCommon.OTP ? getOTPCode() : fields[key]?.text;
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
    final otp = fields[KdbxKeyCommon.OTP]?.text;
    return otp != null
        ? AuthOneTimePassword.tryParse(otp)?.code().toString()
        : null;
  }

  String copyBasicString() {
    return "title: ${getNonNullString(KdbxKeyCommon.TITLE)}\n"
        "url: ${getNonNullString(KdbxKeyCommon.URL)}\n"
        "username: ${getNonNullString(KdbxKeyCommon.USER_NAME)}\n"
        "email: ${getNonNullString(KdbxKeyCommon.EMAIL)}\n"
        "password: ${getNonNullString(KdbxKeyCommon.PASSWORD)}";
  }

  bool _findEnabled(_FindEnabledType type, [KdbxGroup? group]) {
    if (group == null) return true;

    switch (type) {
      case _FindEnabledType.display:
        if (group.enableDisplay != null) {
          return group.enableDisplay!;
        }
        break;
      case _FindEnabledType.searching:
        if (group.enableSearching != null) {
          return group.enableSearching!;
        }
        break;
    }

    return _findEnabled(type, group.parent);
  }

  /// 当前 Entry 是否包含在首页列表中
  /// 默认 包含
  bool enableDisplay() => _findEnabled(_FindEnabledType.display, parent);

  /// 当前 Entry 是否包含在搜索结果中
  /// 默认 包含
  bool enableSearching() => _findEnabled(_FindEnabledType.searching, parent);
}

extension KdbxEntryAndroidAutoFill on KdbxEntry {
  Map<String, String?> toAutofillDataset(Set<String> fieldTypes) {
    final title = getActualString(KdbxKeyCommon.TITLE);
    final password = getActualString(KdbxKeyCommon.PASSWORD);
    final email = getActualString(KdbxKeyCommon.EMAIL);
    final user = getActualString(KdbxKeyCommon.USER_NAME);
    final otp = getActualString(KdbxKeyCommon.OTP);

    return {
      AutofillDataset.DATASET_FIELD_LABEL: title != null && title.isNotEmpty
          ? title
          : user,
      AutofillDataset.DATASET_FIELD_PASSWORD:
          fieldTypes.contains(AutofillDataset.DATASET_FIELD_PASSWORD)
          ? password
          : null,
      AutofillDataset.DATASET_FIELD_USERNAME:
          fieldTypes.contains(AutofillDataset.DATASET_FIELD_EMAIL) &&
              email?.isNotEmpty ==
                  true // 存在邮箱,优先返回邮箱
          ? email
          : user ?? email,
      AutofillDataset.DATASET_FIELD_EMAIL:
          fieldTypes.contains(AutofillDataset.DATASET_FIELD_EMAIL)
          ? email
          : user,
      AutofillDataset.DATASET_FIELD_OTP:
          fieldTypes.contains(AutofillDataset.DATASET_FIELD_OTP) ? otp : null,
    };
  }
}

extension KdbxEntryAutoType on KdbxEntry {
  String _findAutoTypeSequence(KdbxGroup? group) {
    if (group == null) return defaultAutoTypeSequence;

    final sequence = group.defaultAutoTypeSeq;
    if (sequence != null && sequence.isNotEmpty) {
      return sequence;
    }

    return _findAutoTypeSequence(group.parent);
  }

  String getAutoTypeSequence() {
    String sequence = autoType.defaultSequence ?? "";
    return sequence.isNotEmpty ? sequence : _findAutoTypeSequence(parent);
  }

  void setAutoTyprSequence(String sequence) {
    autoType.defaultSequence = sequence;
  }

  Future<void> autoFill([String? key]) {
    return autoFillSequence(
      getAutoTypeSequence(),
      key: key,
      getValue: getActualString,
    );
  }
}

extension KdbxCustomDataCommon on KdbxCustomData {
  String? get(String key) {
    return map[key]?.value;
  }

  void set(String key, String? value) {
    if (value == null) {
      map.remove(key);
    } else {
      map[key] = KdbxCustomItem(value: value);
    }
  }
}

extension KdbxUuidString on String {
  KdbxUuid get kdbxUuid => KdbxUuid.fromString(this);

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

abstract class FormatTransform {
  String get name;

  List<Map<String, String>> import(List<Map<String, dynamic>> input);

  List<Map<String, dynamic>> export(List<Map<String, String>> input);
}
