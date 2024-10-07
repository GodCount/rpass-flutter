import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:kdbx/kdbx.dart' hide KdbxException, KdbxKeyCommon;

import '../rpass.dart';
import 'icons.dart';

export 'common.dart';
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
        KdbxUuid;

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

  Set<String>? getStatistic(KdbxKey kdbKey) {
    switch (kdbKey.key) {
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
  Iterable<KdbxCustomIcon> get customIcons =>
      kdbxFile.body.meta.customIcons.values;

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
          .where((kdbKey) => !KdbxKeyCommon.all.contains(kdbKey.key))
          .map((kdbKey) => kdbKey.key.key));
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

class Kdbx extends KdbxBase
    with KdbxEntryFieldStatistic, KdbxVirtualObject, ChangeNotifier {
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
      notifyListeners();
    } else {
      throw Exception("filepath is null");
    }
  }

  merge(Kdbx kdbx) {
    kdbxFile.merge(kdbx.kdbxFile);
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

  String getNonNullString(KdbxKey key) {
    return getString(key)?.getText() ?? '';
  }
}
