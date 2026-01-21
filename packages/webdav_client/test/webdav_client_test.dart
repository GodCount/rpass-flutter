import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

void main() {
  var client = webdav.newClient(
    'https://dav.jianguoyun.com/dav/test/',
    user: 'do_yzr@163.com',
    password: 'ak4sw6bysemugw5s',
    debug: true,
  );

  // test ping
  test('common settings', () async {
    client.setHeaders({'accept-charset': 'utf-8'});
    client.setConnectTimeout(8000);
    client.setSendTimeout(8000);
    client.setReceiveTimeout(8000);

    try {
      await client.ping();
    } catch (e) {
      print('$e');
    }
  });

  // make folder
  test('make folder', () async {
    await client.mkdir('/新建文件夹');
  });

  // make all folder
  test('make all folder', () async {
    await client.mkdirAll('/new folder/new folder2');
  });

  // test readDir
  group('readDir', () {
    test('read root path', () async {
      var list = await client.readDir('/');
      for (var f in list) {
        print('${f.name} ${f.path}');
      }
    });

    test('read sub path', () async {
      // need change real folder name
      var list = await client.readDir('/new folder');
      for (var f in list) {
        print(f.path);
        print(f.name);
        print(f.mTime.toString());
      }
    });
  });

  group('write', () {
    // It is best not to open debug mode, otherwise the byte data is too large and the output results in IDE cards, 😄
    test('write data to server', () async {
      await client.write(
        '/new folder/新建文本文档.txt',
        Uint8List.fromList([0]),
        onProgress: (c, t) {
          print(c / t);
        },
      );
    }, timeout: Timeout.none);

    test('write a file to server', () async {
      CancelToken c = CancelToken();
      await client.writeFromFile(
        './README.md',
        '/新建文件夹/README.md',
        onProgress: (c, t) {
          print(c / t);
        },
        cancelToken: c,
      );
    }, timeout: Timeout.none);
  });

  // rename
  group('rename', () {
    test('rename a folder', () async {
      await client.rename('/新建文件夹/', '/新建文件夹2/', true);
    });

    test('rename a file', () async {
      await client.rename('/新建文件夹2/README.md', '/新建文件夹2/README222.md', true);
    });
  });

  group('copy', () {
    // 如果是文件夹，有些webdav服务，会把文件夹A内的所有复制到B文件夹内且删除B文件夹内的所有数据
    test('copy a folder', () async {
      await client.copy('/新建文件夹2/', '/new folder/folder/', true);
    });

    test('copy a file', () async {
      await client.copy('/新建文件夹2/README222.md', '/new folder/README.md', true);
    });
  });

  group('read', () {
    test('read remote file', () async {
      await client.read(
        '/new folder/README.md',
        onProgress: (c, t) {
          print(c / t);
        },
      );
    }, timeout: Timeout.none);

    test('read remote file 2 local file', () async {
      await client.read2File(
        '/new folder/README.md',
        './test/README.md',
        onProgress: (c, t) {
          print(c / t);
        },
      );
    }, timeout: Timeout.none);
  });

  // remove
  group('remove', () {
    test('remove a file', () async {
      await client.remove('/new folder/新建文本文档.txt');
      await File('./test/README.md').delete();
    });

    test('remove folder', () async {
      await client.remove('/new folder/');
      await client.remove('/新建文件夹2/');
    });
  });
}
