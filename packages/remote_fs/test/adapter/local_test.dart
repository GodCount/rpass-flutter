import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' show posix;
import 'package:remote_fs/remote_fs.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late RemoteFile local;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('remote_fs_local_test');
    local = await LocalConfig(path: tempDir.path).open();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Uint8List bytes(String text) => Uint8List.fromList(text.codeUnits);

  group('LocalFile', () {
    test('path and name', () {
      expect(local.path, tempDir.path);
      expect(local.name, posix.basename(tempDir.path));
    });

    test('toConfig', () async {
      final file = await local.relative('a.txt');
      final config = await file.toConfig();
      expect(config, LocalConfig(path: posix.join(tempDir.path, 'a.txt')));
    });

    test('exists', () async {
      expect(await local.exists(), true);

      final file = await local.relative('a.txt');
      expect(await file.exists(), false);
      await file.write(bytes('a'));
      expect(await file.exists(), true);
    });

    test('mkdir', () async {
      final dir = await local.relative('a/b');
      await expectLater(dir.mkdir(), throwsA(isA<FileSystemException>()));

      await dir.mkdir(true);
      expect(await dir.exists(), true);
      expect((await dir.stat()).type, FileSystemEntityType.directory);
    });

    test('write and read', () async {
      final file = await local.relative('text.txt');
      await file.write(bytes('Hello World'));
      expect(await file.read(), bytes('Hello World'));

      final stat = await file.stat();
      expect(stat.name, 'text.txt');
      expect(stat.type, FileSystemEntityType.file);
      expect(stat.size, 11);
    });

    test('list', () async {
      await (await local.relative('a.txt')).write(bytes('a'));
      await (await local.relative('dir')).mkdir();

      final list = await local.list();
      final names = list.map((e) => e.name).toSet();
      expect(names, {'a.txt', 'dir'});
      expect(
        list.firstWhere((e) => e.name == 'dir').type,
        FileSystemEntityType.directory,
      );
    });

    test('copy file', () async {
      final file = await local.relative('text.txt');
      await file.write(bytes('Hello World'));

      final to = posix.join(tempDir.path, 'text_copy.txt');
      final copied = await file.copy(to);

      expect(copied.path, to);
      expect(copied.name, 'text_copy.txt');
      expect(await file.exists(), true);
      expect(await copied.read(), bytes('Hello World'));
    });

    test('copy file overwrites target', () async {
      final file = await local.relative('a.txt');
      await file.write(bytes('new'));
      final target = await local.relative('b.txt');
      await target.write(bytes('old content'));

      await file.copy(target.path);
      expect(await target.read(), bytes('new'));
    });

    test('copy directory recursively', () async {
      await (await local.relative('src/sub')).mkdir(true);
      await (await local.relative('src/a.txt')).write(bytes('a'));
      await (await local.relative('src/sub/b.txt')).write(bytes('b'));

      final src = await local.relative('src');
      final to = posix.join(tempDir.path, 'dst');
      final dst = await src.copy(to);

      expect((await dst.stat()).type, FileSystemEntityType.directory);
      expect(await (await dst.relative('a.txt')).read(), bytes('a'));
      expect(await (await dst.relative('sub/b.txt')).read(), bytes('b'));
      expect(await (await src.relative('sub/b.txt')).exists(), true);
    });

    test('copy not found', () async {
      final file = await local.relative('missing.txt');
      await expectLater(
        file.copy(posix.join(tempDir.path, 'x.txt')),
        throwsA(isA<PathNotFoundException>()),
      );
    });

    test('rename', () async {
      final file = await local.relative('text.txt');
      await file.write(bytes('Hello'));

      final moved = await file.rename(posix.join(tempDir.path, 'moved.txt'));
      expect(await file.exists(), false);
      expect(await moved.exists(), true);
      expect(await moved.read(), bytes('Hello'));
    });

    test('delete file', () async {
      final file = await local.relative('text.txt');
      await file.write(bytes('Hello'));

      await file.delete();
      expect(await file.exists(), false);
    });

    test('delete directory with content', () async {
      await (await local.relative('dir/sub')).mkdir(true);
      await (await local.relative('dir/sub/a.txt')).write(bytes('a'));

      final dir = await local.relative('dir');
      await dir.delete();
      expect(await dir.exists(), false);
    });

    test('delete not found', () async {
      final file = await local.relative('missing.txt');
      await expectLater(file.delete(), throwsA(isA<FileSystemException>()));
    });
  });
}
