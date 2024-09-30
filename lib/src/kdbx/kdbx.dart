import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:kdbx/kdbx.dart' hide KdbxException, KdbxKeyCommon;

import '../rpass.dart';
import 'common.dart';
import 'icons.dart';

export 'common.dart';
export 'package:kdbx/kdbx.dart'
    show KdbxEntry, KdbxGroup, KdbxKey, PlainValue, StringValue;

abstract class KdbxBase {
  abstract final KdbxFile kdbxFile;
}

class KdbxKeySpecial {
  static const KEY_TAGS = 'Tags';
  static const KEY_ATTACH = 'Attach';

  static KdbxKey TAGS = KdbxKey(KEY_TAGS);
  static KdbxKey ATTACH = KdbxKey(KEY_ATTACH);

  static List<KdbxKey> all = [
    TAGS,
    ATTACH,
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

class FieldStatistic {
  FieldStatistic({
    Set<String>? urls,
    Set<String>? userNames,
    Set<String>? emails,
    Set<String>? passwords,
    Set<String>? tags,
    Set<String>? customFields,
  })  : urls = urls ?? {},
        userNames = userNames ?? {},
        emails = emails ?? {},
        passwords = passwords ?? {},
        tags = tags ?? {},
        customFields = customFields ?? {};
  final Set<String> urls;
  final Set<String> userNames;
  final Set<String> emails;
  final Set<String> passwords;
  final Set<String> tags;
  final Set<String> customFields;

  Set<String>? getStatistic(KdbxKey kdbKey) {
    switch (kdbKey.key) {
      case KdbxKeyCommon.KEY_URL:
        return urls;
      case KdbxKeyCommon.KEY_USER_NAME:
        return userNames;
      case KdbxKeyCommon.KEY_EMAIL:
        return emails;
      case KdbxKeyCommon.KEY_PASSWORD:
        return passwords;
      case KdbxKeySpecial.KEY_TAGS:
        return tags;
      case "CustomFields":
        return customFields;
    }
    return null;
  }
}

extension KdbxMetaExt on KdbxBase {
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
  void createGroup(String name) {
    kdbxFile.createGroup(parent: kdbxFile.body.rootGroup, name: name);
  }

  void deleteGroup(KdbxGroup group) {
    kdbxFile.deleteGroup(group);
  }
}

extension KdbxEntryExt on KdbxBase {
  // 除垃圾桶的全部 KdbxEntry
  List<KdbxEntry> get totalEntrys => rootGroups
      .expand((group) => group.getAllEntries())
      .toList(growable: false);

  void createEntry(KdbxGroup parent) {
    final entry = KdbxEntry.create(kdbxFile, parent);
    for (var key in KdbxKeyCommon.all) {
      entry.setString(key, PlainValue(''));
    }
    parent.addEntry(entry);
  }

  void deleteEntry(KdbxEntry entry) {
    kdbxFile.deleteEntry(entry);
  }
}

extension KdbxRecycleBinExt on KdbxBase {
  List<KdbxObject> get totalRecycleBinObjects => kdbxFile
      .getRecycleBinOrCreate()
      .getAllGroupsAndEntries()
      .toList(growable: false);

  void deletePermanently(KdbxObject object) {
    kdbxFile.deletePermanently(object);
  }

  void restoreObject(KdbxObject object, [KdbxGroup? toGroup]) {
    KdbxGroup? prveGroup = toGroup;

    if (prveGroup == null) {
      if (object is KdbxGroup || object is KdbxEntry) {
        prveGroup = kdbxFile.findGroupByUuid(object.previousParentGroup.get());
      } else {
        throw KdbxError("not support kdbx object ${object.node.name}");
      }
    }

    if (prveGroup.isInRecycleBin() || prveGroup == kdbxFile.recycleBin) {
      throw KdbxException("It's still in the recycling bin",
          KdbxExceptionCode.NeverLeave_RecycleBin);
    }

    kdbxFile.move(object, prveGroup);
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

  FieldStatistic get fieldStatistic => _fieldStatistic == null
      ? _fieldStatistic = getFieldStatistic()
      : _fieldStatistic!;

  FieldStatistic getFieldStatistic() {
    final fieldStatistic = FieldStatistic();
    for (var item in totalEntrys) {
      final url = item.getString(KdbxKeyCommon.URL)?.getText();
      final userName = item.getString(KdbxKeyCommon.USER_NAME)?.getText();
      final email = item.getString(KdbxKeyCommon.EMAIL)?.getText();
      final password = item.getString(KdbxKeyCommon.PASSWORD)?.getText();
      url != null && fieldStatistic.urls.add(url);
      userName != null && fieldStatistic.userNames.add(userName);
      email != null && fieldStatistic.emails.add(email);
      password != null && fieldStatistic.passwords.add(password);
      fieldStatistic.tags.addAll(item.tagList);
      fieldStatistic.customFields.addAll(item.stringEntries
          .where((kdbKey) => !KdbxKeyCommon.all.contains(kdbKey.key))
          .map((kdbKey) => kdbKey.key.key));
    }
    return fieldStatistic;
  }

  void _refreshFieldStatistic() {
    if (_fieldStatistic != null) {
      _fieldStatistic = getFieldStatistic();
    }
  }
}

extension KdbxIconExt on KdbxObject {
  IconData toMaterialIcon() {
    return KdbxIcon2Material.to(icon.get() ?? KdbxIcon.Key);
  }
}

class Kdbx extends KdbxBase with KdbxEntryFieldStatistic {
  Kdbx({required this.kdbxFile, this.filepath});

  @override
  final KdbxFile kdbxFile;

  String? filepath;

  static Kdbx create({
    required String password,
    required String name,
    String? generator,
  }) {
    return Kdbx(
      kdbxFile: KdbxFormat().create(
        Credentials(ProtectedValue.fromString(password)),
        name,
        generator: generator ?? RpassInfo.appName,
      ),
    );
  }

  static Future<Kdbx> loadFile({
    required String filepath,
    required String password,
  }) async {
    return Kdbx.loadBytes(
      data: await File(filepath).readAsBytes(),
      password: password,
      filepath: filepath,
    );
  }

  static Future<Kdbx> loadBytes({
    required Uint8List data,
    required String password,
    String? filepath,
  }) async {
    return Kdbx(
      filepath: filepath,
      kdbxFile: await KdbxFormat().read(
        data,
        Credentials(ProtectedValue.fromString(password)),
      ),
    );
  }

  static Future<Kdbx> loadBytesFromHash({
    required Uint8List data,
    required Uint8List password,
    String? filepath,
  }) async {
    return Kdbx(
      filepath: filepath,
      kdbxFile: await KdbxFormat().read(
        data,
        Credentials.fromHash(password),
      ),
    );
  }

  Future<void> save([String? filepath]) async {
    this.filepath ??= filepath;
    if (this.filepath != null) {
      await File(this.filepath!).writeAsBytes(await kdbxFile.save());
      _refreshFieldStatistic();
    } else {
      throw Exception("filepath is null");
    }
  }

  merge(Kdbx kdbx) {
    kdbxFile.merge(kdbx.kdbxFile);
  }
}

extension KdbxEntryTagExt on KdbxEntry {
  List<String> get tagList => (tags.get() ?? "").split(";");
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
}
