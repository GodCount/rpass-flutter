import 'dart:io';
import 'dart:typed_data';

import 'package:kdbx/kdbx.dart' hide KdbxException;

import 'common.dart';

export 'common.dart';

class RpassKdbxKeyCommon extends KdbxKeyCommon {
  static const KEY_EMAIL = 'Email';
  static const KEY_NOTES = 'Notes';

  static KdbxKey EMAIL = KdbxKey(KEY_EMAIL);
  static KdbxKey NOTES = KdbxKey(KEY_NOTES);

  // 注意顺序
  static List<KdbxKey> all = [
    KdbxKeyCommon.TITLE,
    KdbxKeyCommon.URL,
    KdbxKeyCommon.USER_NAME,
    EMAIL,
    KdbxKeyCommon.PASSWORD,
    KdbxKeyCommon.OTP,
    NOTES
  ];
}

extension KdbxMetaExt on Kdbx {
  String get version => _kdbxFile.header.version.toString();
  String get generator => _kdbxFile.body.meta.generator.get() ?? '';
  String get databaseName => _kdbxFile.body.meta.databaseName.get() ?? '';
  String get databaseDescription =>
      _kdbxFile.body.meta.databaseDescription.get() ?? '';
  int get historyMaxItems => _kdbxFile.body.meta.historyMaxItems.get() ?? 20;
  int get historyMaxSize =>
      _kdbxFile.body.meta.historyMaxSize.get() ?? 10 * 1024 * 1024;
  bool get recycleBinEnabled =>
      _kdbxFile.body.meta.recycleBinEnabled.get() ?? false;
  String get recycleBinUuid =>
      _kdbxFile.body.meta.recycleBinUUID.get()?.uuid ?? KdbxUuid.NIL.uuid;

  Iterable<KdbxBinary> get binariesIterablea => _kdbxFile.ctx.binariesIterable;

  set databaseName(String value) {
    _kdbxFile.body.meta.databaseName.set(value);
  }

  set databaseDescription(String value) {
    _kdbxFile.body.meta.databaseDescription.set(value);
  }

  set historyMaxItems(int value) {
    _kdbxFile.body.meta.historyMaxItems.set(value);
  }

  set historyMaxSize(int value) {
    _kdbxFile.body.meta.historyMaxSize.set(value);
  }

  set recycleBinEnabled(bool enabled) {
    _kdbxFile.body.meta.recycleBinEnabled.set(enabled);
  }
}

extension KdbxGroupExt on Kdbx {
  // 是不带垃圾箱组的
  List<KdbxGroup> get rootGroups => _kdbxFile.body.rootGroup.groups
      .where(
          (group) => !group.isInRecycleBin() && group != _kdbxFile.recycleBin)
      .toList(growable: false);

  // 只考虑在根组下添加新组, 不打算嵌套组
  void createGroup(String name) {
    _kdbxFile.createGroup(parent: _kdbxFile.body.rootGroup, name: name);
  }

  void deleteGroup(KdbxGroup group) {
    _kdbxFile.deleteGroup(group);
  }
}

extension KdbxEntryExt on Kdbx {
  // 除垃圾桶的全部 KdbxEntry
  List<KdbxEntry> get totalEntrys => rootGroups
      .expand((group) => group.getAllEntries())
      .toList(growable: false);

  void createEntry(KdbxGroup parent) {
    final entry = KdbxEntry.create(_kdbxFile, parent);
    for (var key in RpassKdbxKeyCommon.all) {
      entry.setString(key, PlainValue(''));
    }
    parent.addEntry(entry);
  }

  void deleteEntry(KdbxEntry entry) {
    _kdbxFile.deleteEntry(entry);
  }
}

extension KdbxRecycleBinExt on Kdbx {
  List<KdbxObject> get totalRecycleBinObjects => _kdbxFile
      .getRecycleBinOrCreate()
      .getAllGroupsAndEntries()
      .toList(growable: false);

  void deletePermanently(KdbxObject object) {
    _kdbxFile.deletePermanently(object);
  }

  void restoreObject(KdbxObject object, [KdbxGroup? toGroup]) {
    KdbxGroup? prveGroup = toGroup;

    if (prveGroup == null) {
      if (object is KdbxGroup || object is KdbxEntry) {
        prveGroup = _kdbxFile.findGroupByUuid(object.previousParentGroup.get());
      } else {
        throw KdbxError("not support kdbx object ${object.node.name}");
      }
    }

    if (prveGroup.isInRecycleBin() || prveGroup == _kdbxFile.recycleBin) {
      throw KdbxException("It's still in the recycling bin",
          KdbxExceptionCode.NeverLeave_RecycleBin);
    }

    _kdbxFile.move(object, prveGroup);
  }
}

class Kdbx {
  Kdbx({required KdbxFile kdbxFile}) : _kdbxFile = kdbxFile;

  KdbxFile _kdbxFile;

  factory Kdbx.create({
    required String password,
    required String name,
    String? generator,
  }) {
    return Kdbx(
      kdbxFile: KdbxFormat().create(
        Credentials(ProtectedValue.fromString(password)),
        name,
        generator: generator,
      ),
    );
  }

  static Future<Kdbx> loadFile({
    required String filepath,
    required String password,
  }) async {
    return Kdbx.loadBytes(
      input: await File(filepath).readAsBytes(),
      password: password,
    );
  }

  static Future<Kdbx> loadBytes({
    required Uint8List input,
    required String password,
  }) async {
    return Kdbx(
      kdbxFile: await KdbxFormat().read(
        input,
        Credentials(ProtectedValue.fromString(password)),
      ),
    );
  }

  Future<void> save(String filepath) async {
    await File(filepath).writeAsBytes(await _kdbxFile.save());
  }

  modifyPassword(String password) {
    _kdbxFile.credentials = Credentials(ProtectedValue.fromString(password));
  }

  merge(Kdbx kdbx) {
    _kdbxFile.merge(kdbx._kdbxFile);
  }
}

extension KdbxEntryTagExt on KdbxEntry {
  List<String> get tagList => (tags.get() ?? "").split(";");
  addTag(String value) {
    if (!tagList.contains(value)) {
      tags.set("$tags;$value");
    }
  }

  removeTag(String value) {
    final tmpTagList = tagList;
    if (tmpTagList.remove(value)) {
      tags.set(tmpTagList.join(";"));
    }
  }
}
