import 'dart:io';
import 'dart:typed_data';

import 'package:remote_fs/remote_fs.dart';
import 'package:test/test.dart';

void main() async {
  late RemoteFile webdav;

  setUpAll(() async {
    webdav = await WebDavConfig(
      url: "https://dav.jianguoyun.com/dav",
      path: "/test",
      username: "2394136873@qq.com",
      password: "a6mwga36ccg4xdus",
      type: AuthType.NoAuth,
    ).open();
  });

  group('WebDavFile', () {
    test('path and name', () {
      expect(webdav.path, '/test');
      expect(webdav.name, 'test');
    });

    test('exists', () async {
      final exists = await webdav.exists();
      expect(exists, isA<bool>());
    });

    test('stat', () async {
      final stat = await webdav.stat();
      expect(stat, isA<RemoteFileStat>());
      expect(stat.size, isA<int>());
      expect(stat.changed, isA<DateTime>());
      expect(stat.modified, isA<DateTime>());
      expect(stat.type, isA<FileSystemEntityType>());
    });

    test('list', () async {
      final list = await webdav.list();
      expect(list, isA<List<RemoteFile>>());
    });

    test('mkdir', () async {
      final testDir = await webdav.relative("test");
      await testDir.mkdir();
      final exists = await testDir.exists();
      expect(exists, true);
    });

    test('write and read', () async {
      final textFile = await webdav.relative("test/text.txt");
      final data = Uint8List.fromList('Hello World'.codeUnits);
      await textFile.write(data);
      final readData = await textFile.read();
      expect(readData, data);
    });

    test('copy', () async {
      final textFile = await webdav.relative("test/text.txt");
      final copyTextFile = await textFile.copy("/test/test/text_copy.txt");

      final readTextData = await textFile.read();
      final readCopyData = await copyTextFile.read();

      expect(readTextData, readCopyData);

      await copyTextFile.delete();
    });

    test('rename', () async {
      final textFile = await webdav.relative("test/text.txt");
      final moveTextFile = await textFile.rename("/test/test/text_move.txt");
      final exists = await textFile.exists();
      expect(exists, false);

      final movevExists = await moveTextFile.exists();
      expect(movevExists, true);
      await moveTextFile.delete();
    });

    test('delete', () async {
      final testDir = await webdav.relative("test");
      await testDir.delete();
      final exists = await testDir.exists();
      expect(exists, false);
    });
  });
}
