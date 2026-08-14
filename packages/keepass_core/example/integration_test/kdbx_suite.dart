import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:keepass_core/keepass_core.dart';

const _password = 'demo-password';

/// Rust 侧按值取走 `Credentials`，所以每次调用都得新建一个，复用会抛
/// `DroppableDisposedException`。
Credentials _credentials([String password = _password]) =>
    Credentials.from(password: password);

/// 条目和分组都用 UUID 当主键，新建时由调用方生成。
String _uuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int start, int end) => bytes
      .sublist(start, end)
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}

EntryData _newEntry({
  required String parent,
  required String title,
  String username = '',
  String password = '',
  String url = '',
  List<Attachment> attachments = const [],
  String? id,
}) {
  return EntryData.raw(
    id: id ?? _uuid(),
    parent: parent,
    fields: {
      KdbxKey.KEY_TITLE: FieldValue(value: title),
      KdbxKey.KEY_USER_NAME: FieldValue(value: username),
      KdbxKey.KEY_PASSWORD: FieldValue(value: password, protected: true),
      KdbxKey.KEY_URL: FieldValue(value: url),
    },
    tags: const [],
    times: Times(),
    customData: const {},
    qualityCheck: true,
    attachments: attachments,
  );
}

GroupData _newGroup({required String parent, required String name}) {
  return GroupData.raw(
    id: _uuid(),
    parent: parent,
    name: name,
    tags: const [],
    times: Times(),
    customData: const {},
    isExpanded: true,
    isRecycleBin: false,
  );
}

String _field(EntryData entry, String key) => entry.fields[key]?.get() ?? '';

String _title(EntryData entry) => _field(entry, KdbxKey.KEY_TITLE);

/// 由 `app_test.dart` 调用，绑定的初始化在那里统一做。
void kdbxTests() {
  late Directory workspace;

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('kdbxdb_it');
  });

  tearDown(() {
    if (workspace.existsSync()) workspace.deleteSync(recursive: true);
  });

  String pathFor(String name) => '${workspace.path}/$name.kdbx';

  /// 新建一个已落盘的数据库，返回它和根分组的 id。
  Future<(Kdbx, String)> createDatabase(String name) async {
    final db = Kdbx.create(
      credentials: _credentials(),
      filepath: pathFor(name),
    );
    await db.saveFile();
    final groups = await db.getGroups();
    return (db, groups.values.firstWhere((group) => group.parent == null).id);
  }

  test('bridge is reachable', () {
    expect(greet(name: 'Tom'), 'Hello, Tom!');
  });

  test('a new database has a root group and a recycle bin', () async {
    final (db, rootId) = await createDatabase('fresh');

    final meta = await db.getMeta();
    final groups = await db.getGroups();

    expect(meta.generator, 'frb_keepass');
    expect(meta.recyclebinEnabled, isTrue);
    expect(meta.recyclebinUuid, isNotNull);
    expect(groups, hasLength(2));
    expect(groups.values.where((group) => group.parent == rootId), hasLength(1));
    expect(File(pathFor('fresh')).existsSync(), isTrue);
  });

  test('entries survive a save and reopen', () async {
    final (db, rootId) = await createDatabase('roundtrip');

    await db.action(
      action: KdbxAction.updateEntry(
        _newEntry(
          parent: rootId,
          title: 'GitHub',
          username: 'octocat',
          password: 's3cret',
          url: 'https://github.com',
        ),
      ),
    );
    await db.saveFile();

    final reopened = await Kdbx.open(
      credentials: _credentials(),
      filepath: pathFor('roundtrip'),
    );
    final entries = await reopened.getEntrys();

    expect(entries, hasLength(1));
    expect(_title(entries.single), 'GitHub');
    expect(_field(entries.single, KdbxKey.KEY_USER_NAME), 'octocat');
    expect(_field(entries.single, KdbxKey.KEY_PASSWORD), 's3cret');
    expect(_field(entries.single, KdbxKey.KEY_URL), 'https://github.com');
  });

  test('opening with the wrong password fails', () async {
    await createDatabase('wrong-password');

    await expectLater(
      Kdbx.open(
        credentials: _credentials('not-the-password'),
        filepath: pathFor('wrong-password'),
      ),
      throwsA(anything),
    );
  });

  test('updating an entry replaces its fields in place', () async {
    final (db, rootId) = await createDatabase('update');
    final id = _uuid();

    await db.action(
      action: KdbxAction.updateEntry(
        _newEntry(id: id, parent: rootId, title: 'Before', username: 'old'),
      ),
    );
    await db.action(
      action: KdbxAction.updateEntry(
        _newEntry(id: id, parent: rootId, title: 'After'),
      ),
    );

    final entry = await db.getEntry(id: id);

    expect(_title(entry), 'After');
    expect(_field(entry, KdbxKey.KEY_USER_NAME), isEmpty);
    expect(entry.times.lastModification, isNotNull);
  });

  test('an entry can be moved into another group', () async {
    final (db, rootId) = await createDatabase('groups');
    final group = _newGroup(parent: rootId, name: 'Work');
    final entryId = _uuid();

    await db.action(action: KdbxAction.updateGroup(group));
    await db.action(
      action: KdbxAction.updateEntry(
        _newEntry(id: entryId, parent: rootId, title: 'Jira'),
      ),
    );

    final moved = await db.getEntry(id: entryId);
    moved.parent = group.id;
    await db.action(action: KdbxAction.updateEntry(moved));

    final inGroup = await db.getEntrys(groupId: group.id);
    final inRoot = await db.getEntrys(groupId: rootId, includeRecycle: true);

    expect(inGroup.map(_title), ['Jira']);
    // 从根分组查询是递归的，所以移动后的条目依然会出现。
    expect(inRoot.map(_title), ['Jira']);
    expect((await db.getEntry(id: entryId)).parent, group.id);
  });

  test('entries can be searched', () async {
    final (db, rootId) = await createDatabase('search');

    for (final title in ['GitHub', 'GitLab', 'Bitbucket']) {
      await db.action(
        action: KdbxAction.updateEntry(
          _newEntry(parent: rootId, title: title, username: '$title-user'),
        ),
      );
    }

    final hits = await db.getEntrys(sreach: 'git');
    final caseSensitiveHits = await db.getEntrys(
      sreach: 'git',
      caseSensitive: true,
    );

    expect(hits.map(_title), containsAll(['GitHub', 'GitLab']));
    expect(hits.map(_title), isNot(contains('Bitbucket')));
    expect(caseSensitiveHits, isEmpty);
  });

  test('entries move to the recycle bin and back', () async {
    final (db, rootId) = await createDatabase('recycle');
    final entryId = _uuid();
    await db.action(
      action: KdbxAction.updateEntry(
        _newEntry(id: entryId, parent: rootId, title: 'Temporary'),
      ),
    );

    final recycleBinId = (await db.getMeta()).recyclebinUuid!;

    await db.action(action: KdbxAction.move2Trash([entryId]));
    // `includeRecycle` 的实际语义是「跳过回收站」。
    expect(await db.getEntrys(includeRecycle: true), isEmpty);

    final trashed = await db.getEntrys(
      groupId: recycleBinId,
      ignoreGroupConfig: true,
    );
    expect(trashed.map(_title), ['Temporary']);

    await db.action(action: KdbxAction.restore([entryId]));
    expect((await db.getEntrys(includeRecycle: true)).map(_title), [
      'Temporary',
    ]);

    await db.action(action: KdbxAction.delete([entryId]));
    expect(await db.getEntrys(includeRecycle: true), isEmpty);
  });

  test('meta can be updated', () async {
    final (db, _) = await createDatabase('meta');

    await db.action(
      action: const KdbxAction.updateMeta(
        databaseName: 'Demo',
        databaseDescription: 'created by the integration test',
      ),
    );
    await db.saveFile();

    final reopened = await Kdbx.open(
      credentials: _credentials(),
      filepath: pathFor('meta'),
    );
    final meta = await reopened.getMeta();

    expect(meta.databaseName, 'Demo');
    expect(meta.databaseDescription, 'created by the integration test');
    expect(meta.databaseNameChanged, isNotNull);
  });

  test('summary collects the values used across entries', () async {
    final (db, rootId) = await createDatabase('summary');

    await db.action(
      action: KdbxAction.updateEntry(
        _newEntry(
          parent: rootId,
          title: 'GitHub',
          username: 'octocat',
          url: 'https://github.com',
        ),
      ),
    );

    final (summary, _, _) = await db.summary();

    expect(summary.userNames, contains('octocat'));
    expect(summary.urls, contains('https://github.com'));
  });

  test('attachments survive a save and reopen', () async {
    final (db, rootId) = await createDatabase('attachment');
    final payload = Uint8List.fromList([1, 2, 3, 4, 5]);
    final entryId = _uuid();

    await db.action(
      action: KdbxAction.updateEntry(
        _newEntry(
          id: entryId,
          parent: rootId,
          title: 'With attachment',
          attachments: [
            Attachment(
              id: 0,
              name: 'notes.bin',
              size: payload.length,
              data: payload,
            ),
          ],
        ),
      ),
    );
    await db.saveFile();

    final reopened = await Kdbx.open(
      credentials: _credentials(),
      filepath: pathFor('attachment'),
    );
    final entry = await reopened.getEntry(id: entryId);

    expect(entry.attachments, hasLength(1));
    expect(entry.attachments.single.name, 'notes.bin');
    expect(
      await reopened.getAttachment(id: entry.attachments.single.id),
      payload,
    );
  });

  test('the master password can be changed', () async {
    final (db, rootId) = await createDatabase('rekey');
    await db.action(
      action: KdbxAction.updateEntry(_newEntry(parent: rootId, title: 'Keep')),
    );

    await db.modifyPassword(credentials: _credentials('new-password'));

    await expectLater(
      Kdbx.open(credentials: _credentials(), filepath: pathFor('rekey')),
      throwsA(anything),
    );

    final reopened = await Kdbx.open(
      credentials: _credentials('new-password'),
      filepath: pathFor('rekey'),
    );
    expect((await reopened.getEntrys()).map(_title), ['Keep']);
  });

  test('merging pulls in entries from a replica', () async {
    // merge 的前提是两边是同一个数据库的副本，根分组 uuid 必须一致。
    final (_, rootId) = await createDatabase('origin');
    File(pathFor('origin')).copySync(pathFor('replica'));

    final target = await Kdbx.open(
      credentials: _credentials(),
      filepath: pathFor('origin'),
    );
    final source = await Kdbx.open(
      credentials: _credentials(),
      filepath: pathFor('replica'),
    );

    await target.action(
      action: KdbxAction.updateEntry(_newEntry(parent: rootId, title: 'A')),
    );
    await source.action(
      action: KdbxAction.updateEntry(_newEntry(parent: rootId, title: 'B')),
    );

    // merge 会取走 source，调用之后就不能再用它了。
    final log = await target.merge(kdbx: source);
    final titles = (await target.getEntrys()).map(_title);

    expect(titles, containsAll(['A', 'B']));
    expect(log.events, isNotEmpty);
  });

  test('the kdf config can be changed', () async {
    final (db, _) = await createDatabase('kdf');

    await db.action(
      action: const KdbxAction.updateConfig(
        kdfConfig: KdfConfig.aes(rounds: 1000),
        compressionConfig: CompressionConfig.none,
      ),
    );
    await db.saveFile();

    final reopened = await Kdbx.open(
      credentials: _credentials(),
      filepath: pathFor('kdf'),
    );
    final config = await reopened.getConfig();

    expect(config.kdfConfig, const KdfConfig.aes(rounds: 1000));
    expect(config.compressionConfig, CompressionConfig.none);
  });
}
