import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpass/src/widget/kdbx_icon.dart';

void main() {
  group("Kdbx Favicon Cache Manager", () {
    final cacheDir = Directory("test/cache").absolute;
    final cacheManager = KdbxFaviconCacheManager(cacheDir: cacheDir.path);

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
      expect(await cacheDir.exists(), isFalse);
    });
  });

  group("Fetch Kdbx Favicon", () {
    test("Splice Url", () {
      KdbxFetchFavIcon fetchFavicon = KdbxFetchFavIcon(source: FavIconSource.All);

      expect(
          fetchFavicon
              .getFaviconUrls("https://github.com/GodCount/rpass-flutter"),
          equals([
            "http://github.com/faviocn.ico",
            "https://icons.duckduckgo.com/ip3/github.com.ico",
            "https://www.google.com/s2/favicons?domain=github.com&sz=32"
          ]));

      expect(
          fetchFavicon.getFaviconUrls("github.com/GodCount/rpass-flutter"),
          equals([
            "http://github.com/faviocn.ico",
            "https://icons.duckduckgo.com/ip3/github.com.ico",
            "https://www.google.com/s2/favicons?domain=github.com&sz=32"
          ]));

      expect(
          fetchFavicon.getFaviconUrls(
            "https://docs.flutter.dev/",
          ),
          equals([
            "http://docs.flutter.dev/faviocn.ico",
            "https://icons.duckduckgo.com/ip3/flutter.dev.ico",
            "https://www.google.com/s2/favicons?domain=docs.flutter.dev&sz=32"
          ]));

      fetchFavicon = KdbxFetchFavIcon(source: FavIconSource.Slef);

      expect(
        fetchFavicon
            .getFaviconUrls("https://github.com/GodCount/rpass-flutter"),
        equals(["http://github.com/faviocn.ico"]),
      );

      fetchFavicon = KdbxFetchFavIcon(source: FavIconSource.Duckduckgo);

      expect(
        fetchFavicon
            .getFaviconUrls("https://github.com/GodCount/rpass-flutter"),
        equals(["https://icons.duckduckgo.com/ip3/github.com.ico"]),
      );

      fetchFavicon = KdbxFetchFavIcon(source: FavIconSource.Google);

      expect(
        fetchFavicon
            .getFaviconUrls("https://github.com/GodCount/rpass-flutter"),
        equals(["https://www.google.com/s2/favicons?domain=github.com&sz=32"]),
      );
    });

    test("Fetch Favicon", () async {
      KdbxFetchFavIcon fetchFavicon = KdbxFetchFavIcon(source: FavIconSource.Slef);

      await fetchFavicon.fetch("https://github.com/GodCount/rpass-flutter");
    });

    test("Duckduckgo Fetch Favicon", () async {
      KdbxFetchFavIcon fetchFavicon =
          KdbxFetchFavIcon(source: FavIconSource.Duckduckgo);

      await fetchFavicon.fetch("https://github.com/GodCount/rpass-flutter");
    });

    test("Google Fetch Favicon", () async {
      KdbxFetchFavIcon fetchFavicon =
          KdbxFetchFavIcon(source: FavIconSource.Google);

      await fetchFavicon.fetch("https://github.com/GodCount/rpass-flutter");
    });
  });
}
