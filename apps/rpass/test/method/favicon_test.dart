import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpass/src/util/fetch_favicon.dart';

void main() {
  group("Favicon Cache Manager", () {
    final cacheDir = Directory("test/cache").absolute;
    final cacheManager = FaviconCacheManager(cacheDir: cacheDir);

    final testData = Uint8List.fromList([1, 2, 3, 4, 5]);

    if (!cacheDir.existsSync()) {
      cacheDir.createSync(recursive: true);
    }

    test("Write Cache", () async {
      await cacheManager.write("test", testData);
      expect(await cacheManager.exist("test"), isTrue);
    });

    test("Read Cache", () async {
      await cacheManager.write("test1", testData);

      expect(await cacheManager.read("test1"), equals(testData));
    });

    test("Delete Cache", () async {
      await cacheManager.write("test2", testData);
      expect(await cacheManager.exist("test2"), isTrue);

      await cacheManager.write("test2", null);
      expect(await cacheManager.exist("test2"), isFalse);
    });

    test("Clear Cache", () async {
      await cacheManager.clear();
      expect(await cacheDir.list().length, equals(0));
    });
  });

  group("Fetch Kdbx Favicon", () {
    test("Splice Url", () {
      FaviconSourceApi fetchFavicon = SlefFaviconSourceApi("github.com");

      expect(
        fetchFavicon.getFaviconUrls(),
        equals(["http://github.com/faviocn.ico"]),
      );

      fetchFavicon = CravatarFaviconSourceApi("docs.flutter.dev");

      expect(
        fetchFavicon.getFaviconUrls(),
        equals([
          "https://cn.cravatar.com/favicon/api/index.php?url=docs.flutter.dev",
          "https://cn.cravatar.com/favicon/api/index.php?url=flutter.dev"
        ]),
      );

      fetchFavicon = DuckduckgoFaviconSourceApi("docs.flutter.dev");

      expect(
        fetchFavicon.getFaviconUrls(),
        equals(["https://icons.duckduckgo.com/ip3/flutter.dev.ico"]),
      );

      fetchFavicon = GoogleFaviconSourceApi("docs.flutter.dev");

      expect(
        fetchFavicon.getFaviconUrls(),
        equals([
          "https://www.google.com/s2/favicons?domain=docs.flutter.dev&sz=32",
          "https://www.google.com/s2/favicons?domain=flutter.dev&sz=32"
        ]),
      );
    });

    test("Duckduckgo Fetch Favicon", () async {
      FetchFavicon fetchFavicon = FetchFavicon(FaviconSource.Duckduckgo);

      await fetchFavicon.fetch("https://github.com/GodCount/rpass-flutter");
    });

    test("Google Fetch Favicon", () async {
      FetchFavicon fetchFavicon = FetchFavicon(FaviconSource.Google);

      await fetchFavicon.fetch("https://github.com/GodCount/rpass-flutter");
    });

    test("Cravatar Fetch Favicon", () async {
      FetchFavicon fetchFavicon = FetchFavicon(FaviconSource.Cravatar);

      await fetchFavicon.fetch("https://github.com/GodCount/rpass-flutter");

      await expectLater(
        fetchFavicon.fetch("https://github.comaa/GodCount/rpass-flutter"),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('is default favicon'),
          ),
        ),
      );
    });
  });
}
