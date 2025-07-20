import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:kdbx/kdbx.dart' hide KdbxException, KdbxKeyCommon;
import 'package:uuid/uuid.dart';

import '../native/platform/android.dart';
import '../rpass.dart';
import '../util/one_time_password.dart';
import 'auto_fill.dart';
import 'icons.dart';

export 'common.dart';
export 'adapter/adapter.dart';
export 'auto_type.dart';
export 'package:kdbx/kdbx.dart'
    show
        KdbxEntry,
        KdbxGroup,
        KdbxObject,
        KdbxKey,
        PlainValue,
        StringValue,
        KdbxBinary,
        KdbxIcon,
        KdbxCustomIcon,
        KdbxDao,
        KdbxUuid,
        KdbxInvalidKeyException,
        MergeContext;

const defaultAutoTypeSequence = "{UserName}{TAB}{Password}{ENTER}";

abstract class KdbxBase {
  KdbxFile get kdbxFile;
}

class KdbxCustomDataKey {
  static const GENERAL_GROUP_UUID = 'general_group_uuid';
  static const EMAIL_GROUP_UUID = 'email_group_uuid';

  static const SYNC_ACCPUNT_UUID = "sync_account_uuid";
}

class KdbxKeySpecial {
  static const KEY_TAGS = 'Tags';
  static const KEY_ATTACH = 'Attach';
  static const KEY_EXPIRES = "Expires";
  static const KEY_AUTO_TYPE = "AutoType";
  static const KEY_AUTO_FILL_PACKAGE_NAME = "AutoFillPackageName";

  static KdbxKey TAGS = KdbxKey(KEY_TAGS);
  static KdbxKey ATTACH = KdbxKey(KEY_ATTACH);
  static KdbxKey EXPIRES = KdbxKey(KEY_EXPIRES);
  static KdbxKey AUTO_TYPE = KdbxKey(KEY_AUTO_TYPE);
  static KdbxKey AUTO_FILL_PACKAGE_NAME = KdbxKey(KEY_AUTO_FILL_PACKAGE_NAME);

  static List<KdbxKey> all = [
    AUTO_TYPE,
    AUTO_FILL_PACKAGE_NAME,
    TAGS,
    ATTACH,
    EXPIRES
  ];
}

class KdbxKeyCommon {
  static const KEY_TITLE = 'Title';
  static const KEY_URL = 'URL';
  static const KEY_USER_NAME = 'UserName';
  static const KEY_EMAIL = 'Email';
  static const KEY_PASSWORD = 'Password';
  static const KEY_OTP = 'OTPAuth';
  static const KEY_NOTES = 'Notes';

  static KdbxKey TITLE = KdbxKey(KEY_TITLE);
  static KdbxKey URL = KdbxKey(KEY_URL);
  static KdbxKey USER_NAME = KdbxKey(KEY_USER_NAME);
  static KdbxKey EMAIL = KdbxKey(KEY_EMAIL);
  static KdbxKey PASSWORD = KdbxKey(KEY_PASSWORD);
  static KdbxKey OTP = KdbxKey(KEY_OTP);
  static KdbxKey NOTES = KdbxKey(KEY_NOTES);

  // 注意顺序
  static List<KdbxKey> all = [
    TITLE,
    URL,
    USER_NAME,
    EMAIL,
    PASSWORD,
    OTP,
    NOTES
  ];
}

final defaultKdbxKeys = [
  ...KdbxKeyCommon.all,
  ...KdbxKeySpecial.all,
];

class FieldStatistic {
  FieldStatistic({
    Set<String>? urls,
    Set<String>? userNames,
    Set<String>? emails,
    Set<String>? tags,
    Set<String>? customFields,
    Set<String>? customIcons,
  })  : urls = urls ?? {},
        userNames = userNames ?? {},
        emails = emails ?? {},
        tags = tags ?? {},
        customFields = customFields ?? {},
        customIcons = customIcons ?? {};
  final Set<String> urls;
  final Set<String> userNames;
  final Set<String> emails;
  final Set<String> tags;
  final Set<String> customFields;
  final Set<String> customIcons;

  Set<String>? getStatistic(KdbxKey kdbxKey) {
    switch (kdbxKey.key) {
      case KdbxKeyCommon.KEY_URL:
        return urls;
      case KdbxKeyCommon.KEY_USER_NAME:
        return userNames;
      case KdbxKeyCommon.KEY_EMAIL:
        return emails;
      case KdbxKeySpecial.KEY_TAGS:
        return tags;
      case "CustomFields":
        return customFields;
      case "CustomIcons":
        return customIcons;
    }
    return null;
  }
}

extension KdbxMetaCommon on KdbxBase {
  String get version => kdbxFile.header.version.toString();
  String get generator => kdbxFile.body.meta.generator.get() ?? '';
  String get databaseName => kdbxFile.body.meta.databaseName.get() ?? '';
  String get databaseDescription =>
      kdbxFile.body.meta.databaseDescription.get() ?? '';
  int get historyMaxItems => kdbxFile.body.meta.historyMaxItems.get() ?? 20;
  int get historyMaxSize =>
      kdbxFile.body.meta.historyMaxSize.get() ?? 10 * 1024 * 1024;
  bool get recycleBinEnabled =>
      kdbxFile.body.meta.recycleBinEnabled.get() ?? false;
  String get recycleBinUuid =>
      kdbxFile.body.meta.recycleBinUUID.get()?.uuid ?? KdbxUuid.NIL.uuid;

  Iterable<KdbxBinary> get binariesIterablea => kdbxFile.ctx.binariesIterable;
  Iterable<KdbxCustomIcon> get customIcons =>
      kdbxFile.body.meta.customIcons.values;

  KdbxCustomData get customData => kdbxFile.body.meta.customData;

  set databaseName(String value) {
    kdbxFile.body.meta.databaseName.set(value);
  }

  set databaseDescription(String value) {
    kdbxFile.body.meta.databaseDescription.set(value);
  }

  set historyMaxItems(int value) {
    kdbxFile.body.meta.historyMaxItems.set(value);
  }

  set historyMaxSize(int value) {
    kdbxFile.body.meta.historyMaxSize.set(value);
  }

  set recycleBinEnabled(bool enabled) {
    kdbxFile.body.meta.recycleBinEnabled.set(enabled);
  }
}

extension KdbxGroupExt on KdbxBase {
  // 是不带垃圾箱组的
  List<KdbxGroup> get rootGroups => kdbxFile.body.rootGroup.groups
      .where((group) => !group.isInRecycleBin() && group != kdbxFile.recycleBin)
      .toList(growable: false);

  // 只考虑在根组下添加新组, 不打算嵌套组
  KdbxGroup createGroup(String name) {
    return kdbxFile.createGroup(parent: kdbxFile.body.rootGroup, name: name);
  }

  void deleteGroup(KdbxGroup group) {
    kdbxFile.deleteGroup(group);
  }

  KdbxGroup? findGroupByUuid(KdbxUuid uuid) {
    try {
      return kdbxFile.body.rootGroup
          .getAllGroups()
          .firstWhere((group) => group.uuid == uuid);
    } catch (e) {
      return null;
    }
  }
}

mixin KdbxVirtualObject on KdbxBase {
  KdbxGroup? _kdbxVirtualGroup;

  KdbxGroup? get virtualGroup => _kdbxVirtualGroup;

  KdbxGroup _getVirtualGroup() {
    if (_kdbxVirtualGroup != null) return _kdbxVirtualGroup!;
    _kdbxVirtualGroup = KdbxGroup.create(
      ctx: kdbxFile.ctx,
      parent: null,
      name: "Virtual-Group",
    );
    return _kdbxVirtualGroup!;
  }

  KdbxEntry createVirtualEntry() {
    return createEntry(_getVirtualGroup());
  }
}

extension KdbxEntryExt on KdbxBase {
  // 除垃圾桶的全部 KdbxEntry
  List<KdbxEntry> get totalEntry => [
        ...kdbxFile.body.rootGroup.entries,
        ...rootGroups.expand((group) => group.getAllEntries())
      ];

  KdbxEntry createEntry(KdbxGroup parent) {
    final entry = KdbxEntry.create(kdbxFile, parent);
    for (var key in KdbxKeyCommon.all) {
      entry.setString(key, PlainValue(''));
    }
    parent.addEntry(entry);
    return entry;
  }

  KdbxEntry? findEntryByUuid(KdbxUuid uuid) {
    try {
      return totalEntry.firstWhere((group) => group.uuid == uuid);
    } catch (e) {
      return null;
    }
  }

  void deleteEntry(KdbxEntry entry) {
    kdbxFile.deleteEntry(entry);
  }
}

extension KdbxRecycleBinExt on KdbxBase {
  List<KdbxObject> get recycleBinObjects => [
        ...kdbxFile.getRecycleBinOrCreate().groups,
        ...kdbxFile.getRecycleBinOrCreate().entries,
      ];

  void deletePermanently(KdbxObject object) {
    kdbxFile.deletePermanently(object);
  }

  void restoreObject(KdbxObject object) {
    KdbxGroup? prveGroup;

    try {
      prveGroup = kdbxFile.findGroupByUuid(object.previousParentGroup.get());
      if (prveGroup.isInRecycleBin() || prveGroup == kdbxFile.recycleBin) {
        prveGroup = kdbxFile.body.rootGroup;
      }
    } catch (e) {
      prveGroup = kdbxFile.body.rootGroup;
    }

    kdbxFile.move(object, prveGroup);
  }
}

extension Base64Credentials on Credentials {
  String toBase64() {
    return base64.encode(getHash());
  }
}

extension KdbxCredentialsExt on KdbxBase {
  Credentials get credentials => kdbxFile.credentials;

  Credentials createCredentials(String password) {
    return Credentials(ProtectedValue.fromString(password));
  }

  void modifyPassword(String password) {
    kdbxFile.credentials = createCredentials(password);
  }

  void modifyCredentials(Credentials credentials) {
    kdbxFile.credentials = credentials;
  }
}

mixin KdbxEntryFieldStatistic on KdbxBase {
  FieldStatistic? _fieldStatistic;

  FieldStatistic get fieldStatistic => _getFieldStatistic();

  FieldStatistic _getFieldStatistic() {
    if (_fieldStatistic != null) {
      return _fieldStatistic!;
    }

    _fieldStatistic = FieldStatistic();

    _fieldStatistic!.customIcons.addAll(customIcons.map(
      (item) => item.uuid.uuid,
    ));

    void setFieldStatistic(KdbxEntry entry) {
      final url = entry.getString(KdbxKeyCommon.URL)?.getText();
      final userName = entry.getString(KdbxKeyCommon.USER_NAME)?.getText();
      final email = entry.getString(KdbxKeyCommon.EMAIL)?.getText();

      url != null && url.isNotEmpty && _fieldStatistic!.urls.add(url);
      userName != null &&
          userName.isNotEmpty &&
          _fieldStatistic!.userNames.add(userName);

      email != null && email.isNotEmpty && _fieldStatistic!.emails.add(email);

      _fieldStatistic!.tags.addAll(entry.tagList);

      _fieldStatistic!.customFields.addAll(entry.stringEntries
          .where((kdbxKey) => !KdbxKeyCommon.all.contains(kdbxKey.key))
          .map((kdbxKey) => kdbxKey.key.key));
    }

    totalEntry.forEach(setFieldStatistic);

    kdbxFile.dirtyObjectsChanged.listen((event) {
      _fieldStatistic!.customIcons.addAll(customIcons.map(
        (item) => item.uuid.uuid,
      ));
      for (var item in event) {
        if (item is KdbxEntry) {
          setFieldStatistic(item);
        }
      }
    });

    return _fieldStatistic!;
  }
}

extension KdbxIconExt on KdbxObject {
  IconData toMaterialIcon() {
    return KdbxIcon2Material.to(icon.get() ?? KdbxIcon.Key);
  }
}

extension KdbxExternalImport on KdbxBase {
  void import(List<Map<KdbxKey, String>> list, {KdbxGroup? kdbxGroup}) {
    if (kdbxGroup == null) {
      final uuid = customData[KdbxCustomDataKey.GENERAL_GROUP_UUID];
      kdbxGroup = uuid != null
          ? findGroupByUuid(KdbxUuid(uuid)) ?? kdbxFile.body.rootGroup
          : kdbxFile.body.rootGroup;
    }
    for (var item in list) {
      final kdbxEntry = createEntry(kdbxGroup);
      for (var entry in item.entries) {
        if (entry.key == KdbxKeySpecial.TAGS) {
          kdbxEntry.tags.set(entry.value);
        } else {
          kdbxEntry.setString(entry.key, PlainValue(entry.value));
        }
      }
    }
  }
}

extension KdbxSync on KdbxBase {
  KdbxEntry? get syncAccountEntry =>
      customData[KdbxCustomDataKey.SYNC_ACCPUNT_UUID] != null
          ? findEntryByUuid(
              KdbxUuid(customData[KdbxCustomDataKey.SYNC_ACCPUNT_UUID]!),
            )
          : null;

  set syncAccountEntry(KdbxEntry? entry) {
    customData[KdbxCustomDataKey.SYNC_ACCPUNT_UUID] =
        entry != null ? entry.uuid.uuid : KdbxUuid.NIL.uuid;
  }
}

class SyncMergeContext {
  SyncMergeContext({
    required this.mergeContext,
    this.isUpdateMasterKey = false,
    this.masterKeyChanged = false,
  });

  final MergeContext mergeContext;

  /// 当远程 kdbx 密钥是新的，则需要更新本地 指纹密钥
  final bool isUpdateMasterKey;

  /// 本地和远程密钥不一致
  final bool masterKeyChanged;

  /// 字段有变化
  bool get fieldChanged => mergeContext.changes.isNotEmpty;

  /// kdbx 文件
  Uint8List? data;
}

extension KdbxAndroidAutoFill on KdbxBase {
  Future<List<AutofillDataset>> autofillSearch(AutofillMetadata metadata) {
    return androidAutofillSearch(metadata, totalEntry);
  }
}

extension KdbxEntryAndroidAutoFill on KdbxEntry {
  AutofillDataset toAutofillDataset(Set<String> fieldTypes) {
    return AutofillDataset(
      label: getActualString(KdbxKeyCommon.TITLE) ??
          getActualString(KdbxKeyCommon.USER_NAME),
      password: fieldTypes.contains(AutofillField.PASSWORD)
          ? getActualString(KdbxKeyCommon.PASSWORD)
          : null,
      username: fieldTypes.contains(AutofillField.USERNAME) ||
              fieldTypes.contains(AutofillField.EMAIL)
          ? fieldTypes.contains(AutofillField.EMAIL) // 存在邮箱,优先返回邮箱
              ? getActualString(KdbxKeyCommon.EMAIL) ??
                  getActualString(KdbxKeyCommon.USER_NAME)
              : getActualString(KdbxKeyCommon.USER_NAME) ??
                  getActualString(KdbxKeyCommon.EMAIL)
          : null,
      otp: fieldTypes.contains(AutofillField.OTP)
          ? getActualString(KdbxKeyCommon.OTP)
          : null,
    );
  }
}

class Kdbx extends KdbxBase
    with KdbxEntryFieldStatistic, KdbxVirtualObject, ChangeNotifier {
  Kdbx({required KdbxFile kdbxFile, this.filepath}) : _kdbxFile = kdbxFile;

  KdbxFile _kdbxFile;

  String? filepath;

  @override
  KdbxFile get kdbxFile => _kdbxFile;

  static Kdbx create({
    required Credentials credentials,
    required String name,
    String? generator,
  }) {
    return Kdbx(
      kdbxFile: KdbxFormat().create(
        credentials,
        name,
        generator: generator ?? RpassInfo.appName,
      ),
    );
  }

  static Credentials createCredentials(String? password, Uint8List? keyFile) {
    assert(
      !(password == null && keyFile == null),
      "Must include a password / key file.",
    );

    return Credentials.composite(
      password != null ? ProtectedValue.fromString(password) : null,
      keyFile,
    );
  }

  static Uint8List randomKeyFile() {
    return KeyFileCredentials.random().getBinary();
  }

  static Future<Kdbx> loadBytesFromCredentials({
    required Uint8List data,
    required Credentials credentials,
    String? filepath,
  }) async {
    return Kdbx(
      filepath: filepath,
      kdbxFile: await KdbxFormat().read(
        data,
        credentials,
      ),
    );
  }

  static Future<Kdbx> loadBytesFromHash({
    required Uint8List data,
    required Uint8List token,
    String? filepath,
  }) async {
    return Kdbx(
      filepath: filepath,
      kdbxFile: await KdbxFormat().read(
        data,
        Credentials.fromHash(token),
      ),
    );
  }

  Future<Uint8List> save([String? filepath]) async {
    this.filepath ??= filepath;
    if (this.filepath != null) {
      final data = await kdbxFile.save();

      await File(this.filepath!).writeAsBytes(data);

      notifyListeners();
      return data;
    } else {
      throw Exception("filepath is null");
    }
  }

  Future<SyncMergeContext> sync(Kdbx remoteKdbx) async {
    final isUpdateMasterKey = remoteKdbx.kdbxFile.body.meta.masterKeyChanged
        .isAfter(kdbxFile.body.meta.masterKeyChanged);

    final masterKeyChanged = isUpdateMasterKey ||
        remoteKdbx.kdbxFile.body.meta.masterKeyChanged.get() !=
            kdbxFile.body.meta.masterKeyChanged.get();

    // 以远程的为基准
    // 从远程的 合并 本地的
    // 始终保持本地和远程数据一致
    final syncMergeContext = SyncMergeContext(
      // TODO! changes 只记录了本地的更改，远程更改没有记录
      // 影响日志展示
      mergeContext: remoteKdbx.kdbxFile.merge(kdbxFile),
      isUpdateMasterKey: isUpdateMasterKey,
      masterKeyChanged: masterKeyChanged,
    );

    final tmpKdbxFile = kdbxFile;

    try {
      _kdbxFile = remoteKdbx.kdbxFile;
      syncMergeContext.data = await save();
    } catch (e) {
      _kdbxFile = tmpKdbxFile;
      rethrow;
    }

    return syncMergeContext;
  }
}

extension KdbxEntryTagExt on KdbxEntry {
  List<String> get tagList =>
      (tags.get() ?? "").split(";").where((item) => item.isNotEmpty).toList();

  set tagList(List<String> list) => tags.set(list.join(";"));

  void addTag(String value) {
    if (!tagList.contains(value)) {
      tags.set("$tags;$value");
    }
  }

  void removeTag(String value) {
    final tmpTagList = tagList;
    if (tmpTagList.remove(value)) {
      tags.set(tmpTagList.join(";"));
    }
  }

  Map<KdbxKey, String> toPlainMapEntry() {
    return Map.fromEntries(KdbxKeyCommon.all.map(
      (item) => MapEntry(item, getNonNullString(item)),
    ));
  }
}

enum _FindEnabledType { display, Searching }

extension KdbxEntryCommon on KdbxEntry {
  Iterable<MapEntry<KdbxKey, StringValue?>> get customEntries =>
      stringEntries.where((item) => isCustomKey(item.key));

  bool isDefaultKey(KdbxKey key) => defaultKdbxKeys.contains(key);

  bool isCustomKey(KdbxKey key) => !isDefaultKey(key);

  bool isExpiry() {
    return times.expires.get() == true &&
        times.expiryTime.get() != null &&
        times.expiryTime.get()!.isBefore(DateTime.now());
  }

  String getNonNullString(KdbxKey key) {
    return getString(key)?.getText() ?? '';
  }

  String? getActualString(KdbxKey key) {
    return key == KdbxKeyCommon.OTP ? getOTPCode() : getString(key)?.getText();
  }

  String? getOTPCode() {
    try {
      final url = getString(KdbxKeyCommon.OTP)?.getText();
      return url != null
          ? AuthOneTimePassword.parse(url).code().toString()
          : null;
    } catch (e) {
      return null;
    }
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
        if (group.enableDisplay.get() != null) {
          return group.enableDisplay.get()!;
        }
        break;
      case _FindEnabledType.Searching:
        if (group.enableSearching.get() != null) {
          return group.enableSearching.get()!;
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
  bool enableSearching() => _findEnabled(_FindEnabledType.Searching, parent);
}

extension KdbxEntryAutoType on KdbxEntry {
  String _findAutoTypeSequence(KdbxGroup? group) {
    if (group == null) return defaultAutoTypeSequence;

    final sequence = group.defaultAutoTypeSequence.get();
    if (sequence != null && sequence.isNotEmpty) {
      return sequence;
    }

    return _findAutoTypeSequence(group.parent);
  }

  String getAutoTypeSequence() {
    String sequence = defaultSequence.get() ?? "";
    return sequence.isNotEmpty ? sequence : _findAutoTypeSequence(parent);
  }

  void setAutoTyprSequence(String sequence) {
    defaultSequence.set(sequence);
  }

  Future<void> autoFill([KdbxKey? key]) {
    return autoFillSequence(this, key);
  }
}

extension KdbxUuidCommon on KdbxUuid {
  static final _uuids = <String, String>{};
  String get deBase64Uuid {
    if (_uuids[uuid] != null) {
      return _uuids[uuid]!;
    }
    _uuids[uuid] = Uuid.unparse(toBytes());
    return _uuids[uuid]!;
  }
}

extension KdbxUuidString on String {
  KdbxUuid get kdbxUuid => KdbxUuid.fromBytes(
        Uint8List.fromList(Uuid.parse(this)),
      );
}
