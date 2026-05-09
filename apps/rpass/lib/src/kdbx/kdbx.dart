import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:kpasslib/kpasslib.dart';

import '../i18n.dart';
import '../native/platform/android.dart';
import 'auto_fill.dart';
import 'extension.dart';
import 'field_statistic.dart';

export 'adapter/adapter.dart';
export 'package:kpasslib/kpasslib.dart'
    show
        KdbxEntry,
        KdbxGroup,
        KdbxItem,
        KdbxTextField,
        KdbxBinary,
        KdbxUuid,
        KdbxIcon,
        KdbxCustomIcon,
        KdbxCustomItem,
        KdbxDataBinary,
        PlainBinary,
        ProtectedBinary,
        KdbxTime,
        KdbxError,
        FileCorruptedError,
        UnsupportedValueError,
        InvalidStateError,
        InvalidCredentialsError,
        MergeError;

abstract class KdbxBase {
  KdbxDatabase get kdbxDatabase;
}

extension KdbxMetaCommon on KdbxBase {
  (int, int) get version => kdbxDatabase.header.version;
  String get generator => kdbxDatabase.meta.generator ?? '';
  String get databaseName => kdbxDatabase.meta.name;
  String get databaseDescription => kdbxDatabase.meta.description ?? '';
  int get historyMaxItems => kdbxDatabase.meta.historyMaxItems ?? 20;
  int get historyMaxSize =>
      kdbxDatabase.meta.historyMaxSize ?? 10 * 1024 * 1024;
  bool get recycleBinEnabled => kdbxDatabase.meta.recycleBinEnabled;
  KdbxUuid get recycleBinUuid =>
      kdbxDatabase.meta.recycleBinUuid ?? KdbxUuid.zero;

  KdbxBinaries get binaries => kdbxDatabase.binaries;
  Map<KdbxUuid, KdbxCustomIcon> get customIcons =>
      kdbxDatabase.meta.customIcons;

  KdbxCustomData get customData => kdbxDatabase.meta.customData;

  set databaseName(String value) {
    kdbxDatabase.meta.name = value;
  }

  set databaseDescription(String value) {
    kdbxDatabase.meta.description = value;
  }

  set historyMaxItems(int value) {
    kdbxDatabase.meta.historyMaxItems = value;
  }

  set historyMaxSize(int value) {
    kdbxDatabase.meta.historyMaxSize = value;
  }

  set recycleBinEnabled(bool enabled) {
    kdbxDatabase.meta.recycleBinEnabled = enabled;
  }

  Uint8List? getCustomIcon(KdbxUuid uuid) {
    final data = customIcons[uuid]?.data;
    return data != null ? Uint8List.fromList(data) : null;
  }
}

extension KdbxGroupExt on KdbxBase {
  // 是不带垃圾箱组的
  List<KdbxGroup> get rootGroups => kdbxDatabase.groups
      .where((group) => !kdbxDatabase.isInRecycleBin(group))
      .toList(growable: false);

  // 只考虑在根组下添加新组, 不打算嵌套组
  KdbxGroup createGroup(String name) {
    return kdbxDatabase.createGroup(parent: kdbxDatabase.root, name: name);
  }

  void deleteGroup(KdbxGroup group) {
    kdbxDatabase.remove(group);
  }

  KdbxGroup? findGroupByUuid(KdbxUuid uuid) {
    try {
      return kdbxDatabase.groups.firstWhere((group) => group.uuid == uuid);
    } catch (e) {
      return null;
    }
  }
}

mixin KdbxVirtualObject on KdbxBase {
  KdbxGroup? _kdbxVirtualGroup;

  KdbxGroup get virtualGroup => _getVirtualGroup();

  KdbxGroup _getVirtualGroup() {
    if (_kdbxVirtualGroup != null) return _kdbxVirtualGroup!;
    _kdbxVirtualGroup = KdbxGroup.create(
      name: "Virtual-Group",
      icon: .feather,
      id: KdbxUuid.zero,
    );
    return _kdbxVirtualGroup!;
  }

  KdbxEntry createVirtualEntry() {
    return createEntry(virtualGroup);
  }
}

extension KdbxEntryExt on KdbxBase {
  // 除垃圾桶的全部 KdbxEntry
  List<KdbxEntry> get totalEntry => [
    ...rootGroups.expand((group) => group.allEntries),
  ];

  KdbxEntry createEntry(KdbxGroup parent) {
    final entry = KdbxEntry.create(
      parent: parent,
      meta: kdbxDatabase.meta,
      id: KdbxUuid.random(),
    );
    for (var key in KdbxKeyCommon.all) {
      if (!entry.fields.containsKey(key)) {
        entry.setString(
          key,
          value: "",
          protection: kdbxDatabase.meta.memoryProtection,
        );
      }
    }
    parent.entries.add(entry);
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
    kdbxDatabase.remove(entry);
  }
}

extension KdbxRecycleBinExt on KdbxBase {
  List<KdbxItem> get recycleBinObjects => _getRecycleBinOrCreate().allItems;

  KdbxGroup _getRecycleBinOrCreate() {
    kdbxDatabase.meta.recycleBinEnabled = true;
    return kdbxDatabase.recycleBin!;
  }

  void deletePermanently(KdbxItem item) {
    // 不指定目标组, 则会永久删除
    kdbxDatabase.move(item: item);
  }

  void restoreObject(KdbxItem item) {
    KdbxGroup? prveGroup;

    prveGroup =
        kdbxDatabase.getGroup(uuid: item.previousParent) ?? kdbxDatabase.root;
    if (kdbxDatabase.isInRecycleBin(prveGroup)) {
      prveGroup = kdbxDatabase.root;
    }

    kdbxDatabase.move(item: item, target: prveGroup);
  }
}

extension Base64Credentials on KdbxCredentials {
  String toBase64() {
    return base64.encode(getHash());
  }
}

extension KdbxCredentialsExt on KdbxBase {
  KdbxCredentials get credentials => kdbxDatabase.header.credentials;

  KdbxCredentials createCredentials(String password) {
    return KdbxCredentials(password: ProtectedData.fromString(password));
  }

  void modifyPassword(String password) {
    modifyCredentials(createCredentials(password));
  }

  void modifyCredentials(KdbxCredentials credentials) {
    kdbxDatabase.header.credentials = credentials;
  }
}

mixin KdbxEntryFieldStatistic on KdbxBase {
  FieldStatistic get fieldStatistic => FieldStatistic.statistic(this);
}

extension KdbxExternalImport on KdbxBase {
  void import(List<Map<String, String>> list, {KdbxGroup? kdbxGroup}) {
    if (kdbxGroup == null) {
      final uuid = customData.get(KdbxCustomDataKey.GENERAL_GROUP_UUID);
      kdbxGroup = uuid != null
          ? findGroupByUuid(KdbxUuid.fromString(uuid)) ?? kdbxDatabase.root
          : kdbxDatabase.root;
    }
    for (var item in list) {
      final kdbxEntry = createEntry(kdbxGroup);
      for (var entry in item.entries) {
        if (entry.key == KdbxKeySpecial.TAGS) {
          kdbxEntry.tags = entry.value.split(";");
        } else {
          kdbxEntry.setString(
            entry.key,
            value: entry.value,
            protection: kdbxDatabase.meta.memoryProtection,
          );
        }
      }
    }
  }
}

extension KdbxSync on KdbxBase {
  KdbxEntry? get syncAccountEntry =>
      customData.get(KdbxCustomDataKey.SYNC_ACCPUNT_UUID) != null
      ? findEntryByUuid(
          customData.get(KdbxCustomDataKey.SYNC_ACCPUNT_UUID)!.kdbxUuid,
        )
      : null;

  set syncAccountEntry(KdbxEntry? entry) {
    customData.set(
      KdbxCustomDataKey.SYNC_ACCPUNT_UUID,
      entry != null ? entry.uuid.string : KdbxUuid.zero.string,
    );
  }
}

// class SyncMergeContext {
//   SyncMergeContext({
//     required this.mergeContext,
//     this.isUpdateMasterKey = false,
//     this.masterKeyChanged = false,
//   });

//   final MergeContext mergeContext;

//   /// 当远程 kdbx 密钥是新的，则需要更新本地 指纹密钥
//   final bool isUpdateMasterKey;

//   /// 本地和远程密钥不一致
//   final bool masterKeyChanged;

//   /// 字段有变化
//   bool get fieldChanged => mergeContext.changes.isNotEmpty;

//   /// kdbx 文件
//   Uint8List? data;
// }

extension KdbxAndroidAutoFill on KdbxBase {
  Future<AutofillDataset> autofillSearch(AutofillMetadata metadata) {
    return androidAutofillSearch(metadata, totalEntry);
  }
}

class Kdbx extends KdbxBase
    with KdbxEntryFieldStatistic, KdbxVirtualObject, ChangeNotifier {
  Kdbx({required KdbxDatabase kdbxDatabase, this.filepath})
    : _kdbxDatabase = kdbxDatabase;

  final KdbxDatabase _kdbxDatabase;

  String? filepath;

  @override
  KdbxDatabase get kdbxDatabase => _kdbxDatabase;

  static Kdbx create({
    required KdbxCredentials credentials,
    required String name,
    String? generator,
  }) {
    return Kdbx(
      kdbxDatabase: KdbxDatabase.create(credentials: credentials, name: name)
        ..meta.generator = generator,
    );
  }

  static KdbxCredentials createCredentials(
    String? password,
    Uint8List? keyData,
  ) {
    if (password == null && keyData == null) {
      throw Exception("Must include a password / key file.");
    }

    return KdbxCredentials(
      password: password != null ? ProtectedData.fromString(password) : null,
      keyData: keyData,
    );
  }

  static Uint8List randomKeyFile() {
    return Uint8List.fromList(KdbxCredentials.createRandomKeyFile(version: 2));
  }

  static Future<Kdbx> loadBytesFromCredentials({
    required Uint8List data,
    required KdbxCredentials credentials,
    String? filepath,
  }) async {
    return Kdbx(
      filepath: filepath,
      kdbxDatabase: await KdbxDatabase.fromBytes(
        data: data,
        credentials: credentials,
      ),
    );
  }

  static Future<Kdbx> loadBytesFromHash({
    required Uint8List data,
    required Uint8List token,
    String? filepath,
  }) async {
    return loadBytesFromCredentials(
      data: data,
      filepath: filepath,
      credentials: KdbxCredentials(keyData: token),
    );
  }

  Future<Uint8List> save([String? filepath]) async {
    this.filepath ??= filepath;
    if (this.filepath != null) {
      final data = Uint8List.fromList(await kdbxDatabase.save());

      await File(this.filepath!).writeAsBytes(data);

      notifyListeners();
      return data;
    } else {
      throw Exception("filepath is null");
    }
  }

  Future<void> sync(Kdbx remoteKdbx) async {
    throw UnsupportedError("需要处理并验证");
    // TODO! 需要处理并验证
    kdbxDatabase.merge(remoteKdbx.kdbxDatabase);
    // final isUpdateMasterKey = remoteKdbx.kdbxFile.body.meta.masterKeyChanged
    //     .isAfter(kdbxFile.body.meta.masterKeyChanged);

    // final masterKeyChanged =
    //     isUpdateMasterKey ||
    //     remoteKdbx.kdbxFile.body.meta.masterKeyChanged.get() !=
    //         kdbxFile.body.meta.masterKeyChanged.get();

    // // 以远程的为基准
    // // 从远程的 合并 本地的
    // // 始终保持本地和远程数据一致
    // final syncMergeContext = SyncMergeContext(
    //   // TODO! changes 只记录了本地的更改，远程更改没有记录
    //   // 影响日志展示
    //   mergeContext: remoteKdbx.kdbxFile.merge(kdbxFile),
    //   isUpdateMasterKey: isUpdateMasterKey,
    //   masterKeyChanged: masterKeyChanged,
    // );

    // final tmpKdbxFile = kdbxFile;

    // try {
    //   _kdbxFile = remoteKdbx.kdbxFile;
    //   syncMergeContext.data = await save();
    // } catch (e) {
    //   _kdbxFile = tmpKdbxFile;
    //   rethrow;
    // }

    // return syncMergeContext;
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
