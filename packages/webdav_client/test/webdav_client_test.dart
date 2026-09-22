import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:webdav_client/src/utils.dart';
import 'package:webdav_client/src/xml.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

void main() {
  group('Auth', () {
    test('NoAuth returns null authorization', () {
      const auth = webdav.Auth(user: 'u', pwd: 'p');
      expect(auth.type, webdav.AuthType.NoAuth);
      expect(auth.authorize('GET', '/'), isNull);
    });

    test('BasicAuth encodes credentials', () {
      const auth = webdav.BasicAuth(user: 'user', pwd: 'pwd');
      expect(auth.type, webdav.AuthType.BasicAuth);
      expect(
        auth.authorize('GET', '/dav/'),
        'Basic ${base64Encode(utf8.encode('user:pwd'))}',
      );
    });

    test('DigestParts parses www-authenticate header', () {
      final parts = webdav.DigestParts(
        'Digest realm="testrealm", nonce="abc123", qop="auth", '
        'opaque="xyz", algorithm="MD5"',
      );

      expect(parts.parts['realm'], 'testrealm');
      expect(parts.parts['nonce'], 'abc123');
      expect(parts.parts['qop'], 'auth');
      expect(parts.parts['opaque'], 'xyz');
      expect(parts.parts['algorithm'], 'MD5');
    });

    test('DigestAuth authorize includes expected fields', () {
      final parts = webdav.DigestParts(
        'Digest realm="r", nonce="n", qop="auth", opaque="o", algorithm="MD5"',
      );
      final auth = webdav.DigestAuth(user: 'u', pwd: 'p', dParts: parts);

      expect(auth.type, webdav.AuthType.DigestAuth);
      expect(auth.realm, 'r');
      expect(auth.nonce, 'n');
      expect(auth.qop, 'auth');

      final header = auth.authorize('GET', '/path/file.txt');
      expect(header, startsWith('Digest '));
      expect(header, contains('username="u"'));
      expect(header, contains('realm="r"'));
      expect(header, contains('nonce="n"'));
      expect(header, contains('uri="/path/file.txt"'));
      expect(header, contains('qop=auth'));
      expect(header, contains('opaque=o'));
      expect(header, contains('response="'));
    });
  });

  group('utils', () {
    test('join and path helpers', () {
      expect(join('/a/', '/b'), '/a/b');
      expect(join('/a', 'b/c'), '/a/b/c');
      expect(path2Name('/folder/file.txt'), 'file.txt');
      expect(path2Name('/folder/'), 'folder');
      expect(path2Name('/'), '/');
      expect(getUriPath('https://example.com/dav/test/'), '/dav/test/');
    });

    test('trim variants', () {
      expect(trim('  hi  '), 'hi');
      expect(trim('"quoted"', '"'), 'quoted');
      expect(ltrim('//a/b', '/'), 'a/b');
      expect(rtrim('/a/b/', '/'), '/a/b');
    });

    test('md5Hash is deterministic', () {
      expect(md5Hash(''), 'd41d8cd98f00b204e9800998ecf8427e');
      expect(md5Hash('abc'), '900150983cd24fb0d6963f7d28e17f72');
    });

    test('str2LocalTime parses GMT date', () {
      final time = str2LocalTime('Mon, 15 Jan 2024 12:00:00 GMT');
      expect(time, isNotNull);
      expect(time!.toUtc().year, 2024);
      expect(time.toUtc().month, 1);
      expect(time.toUtc().day, 15);
      expect(str2LocalTime(null), isNull);
      expect(str2LocalTime('not-a-date'), isNull);
    });
  });

  group('WebdavXml', () {
    test('toFiles parses propfind response', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/dav/test/</d:href>
    <d:propstat>
      <d:prop>
        <d:displayname>test</d:displayname>
        <d:resourcetype><d:collection/></d:resourcetype>
        <d:getlastmodified>Mon, 15 Jan 2024 12:00:00 GMT</d:getlastmodified>
      </d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
  <d:response>
    <d:href>/dav/test/hello.txt</d:href>
    <d:propstat>
      <d:prop>
        <d:displayname>hello.txt</d:displayname>
        <d:resourcetype/>
        <d:getcontentlength>11</d:getcontentlength>
        <d:getcontenttype>text/plain</d:getcontenttype>
        <d:getetag>"etag-1"</d:getetag>
        <d:getlastmodified>Mon, 15 Jan 2024 12:00:00 GMT</d:getlastmodified>
      </d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
  <d:response>
    <d:href>/dav/test/subdir/</d:href>
    <d:propstat>
      <d:prop>
        <d:displayname>subdir</d:displayname>
        <d:resourcetype><d:collection/></d:resourcetype>
      </d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>''';

      final files = WebdavXml.toFiles('/dav/test/', xml);
      expect(files, hasLength(2));

      final file = files.firstWhere((f) => f.name == 'hello.txt');
      expect(file.isDir, false);
      expect(file.path, 'hello.txt');
      expect(file.size, 11);
      expect(file.mimeType, 'text/plain');
      expect(file.eTag, '"etag-1"');
      expect(file.mTime, isNotNull);

      final dir = files.firstWhere((f) => f.name == 'subdir');
      expect(dir.isDir, true);
      expect(dir.path, 'subdir/');
    });

    test('toFiles can keep self when skipSelf is false', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/dav/test/</d:href>
    <d:propstat>
      <d:prop>
        <d:displayname>test</d:displayname>
        <d:resourcetype><d:collection/></d:resourcetype>
      </d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>''';

      final files = WebdavXml.toFiles('/dav/test/', xml, skipSelf: false);
      expect(files, hasLength(1));
      expect(files.first.isDir, true);
      expect(files.first.name, 'test');
    });
  });

  group('Client config', () {
    test('newClient sets uri and auth', () {
      final client = webdav.newClient(
        'https://example.com/dav/',
        user: 'alice',
        password: 'secret',
      );

      expect(client.uri, 'https://example.com/dav/');
      expect(client.uriPath, '/dav/');
      expect(client.auth.user, 'alice');
      expect(client.auth.pwd, 'secret');
      expect(client.auth.type, webdav.AuthType.NoAuth);
      expect(client.debug, false);
    });

    test('timeout and header setters update dio options', () {
      final client = webdav.newClient('https://example.com/dav/');
      client.setHeaders({'accept-charset': 'utf-8'});
      client.setConnectTimeout(8000);
      client.setSendTimeout(9000);
      client.setReceiveTimeout(10000);

      expect(client.c.options.headers['accept-charset'], 'utf-8');
      expect(
        client.c.options.connectTimeout,
        const Duration(milliseconds: 8000),
      );
      expect(client.c.options.sendTimeout, const Duration(milliseconds: 9000));
      expect(
        client.c.options.receiveTimeout,
        const Duration(milliseconds: 10000),
      );
    });
  });

  group('Client integration', () {
    late webdav.Client client;
    const root = 'webdav_client_ut/';

    setUpAll(() {
      client = webdav.newClient(
        'https://dav.jianguoyun.com/dav/test/',
        user: '2394136873@qq.com',
        password: 'a6mwga36ccg4xdus',
      );
      client.setHeaders({'accept-charset': 'utf-8'});
      client.setConnectTimeout(8000);
      client.setSendTimeout(8000);
      client.setReceiveTimeout(8000);
    });

    test('ping', () async {
      await client.ping();
    });

    test('mkdir / write / read / readDir / rename / copy / remove', () async {
      await client.mkdirAll(root);

      final filePath = '${root}hello.txt';
      final data = Uint8List.fromList(utf8.encode('Hello WebDAV'));
      await client.write(filePath, data);

      final read = await client.read(filePath);
      expect(read, data);

      final props = await client.readProps(filePath);
      expect(props.name, 'hello.txt');
      expect(props.isDir, false);
      expect(props.size, data.length);

      final list = await client.readDir(root);
      expect(list.any((f) => f.name == 'hello.txt'), isTrue);

      final renamed = '${root}hello_renamed.txt';
      await client.rename(filePath, renamed, true);
      expect(await client.read(renamed), data);

      final copied = '${root}hello_copy.txt';
      await client.copy(renamed, copied, true);
      expect(await client.read(copied), data);

      await client.remove(renamed);
      await client.remove(copied);
      await client.remove(root);
    });
  });
}
