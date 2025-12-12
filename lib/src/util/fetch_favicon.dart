import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../util/cache_network_image.dart';
import '../util/common.dart';

enum FavIconSource {
  Slef,
  Google,
  Duckduckgo,
  Cravatar,
}

abstract class FavIconSourceApi {
  FavIconSourceApi(this.domain);

  final String domain;

  List<String> getFavIconUrls();

  ///
  /// 如果站点返回默认图片,但状态码又是200就需要通过这个来判断
  ///
  bool isDefault(Uint8List data);

  @protected
  String _getSecondDomain() {
    final parts = domain.split(".").reversed.toList();
    if (parts.length < 2) return domain;
    return "${parts[1]}.${parts[0]}";
  }
}

class SlefFavIconSourceApi extends FavIconSourceApi {
  SlefFavIconSourceApi(super.domain);

  @override
  List<String> getFavIconUrls() {
    return ["http://$domain/faviocn.ico"];
  }

  @override
  bool isDefault(Uint8List data) {
    return false;
  }
}

class GoogleFavIconSourceApi extends FavIconSourceApi {
  GoogleFavIconSourceApi(super.domain);

  @override
  List<String> getFavIconUrls() {
    return [
      "https://www.google.com/s2/favicons?domain=$domain&sz=32",
      if (_getSecondDomain() != domain)
        "https://www.google.com/s2/favicons?domain=${_getSecondDomain()}&sz=32"
    ];
  }

  @override
  bool isDefault(Uint8List data) {
    return false;
  }
}

class DuckduckgoFavIconSourceApi extends FavIconSourceApi {
  DuckduckgoFavIconSourceApi(super.domain);

  @override
  List<String> getFavIconUrls() {
    return [
      "https://icons.duckduckgo.com/ip3/${_getSecondDomain()}.ico",
    ];
  }

  @override
  bool isDefault(Uint8List data) {
    return false;
  }
}

class CravatarFavIconSourceApi extends FavIconSourceApi {
  CravatarFavIconSourceApi(super.domain);

  @override
  List<String> getFavIconUrls() {
    return [
      "https://cn.cravatar.com/favicon/api/index.php?url=$domain",
      if (_getSecondDomain() != domain)
        "https://cn.cravatar.com/favicon/api/index.php?url=${_getSecondDomain()}"
    ];
  }

  @override
  bool isDefault(Uint8List data) {
    return data.length == 492;
  }
}

class FetchFavIcon extends FetchNetworkImage {
  FetchFavIcon({
    this.source = FavIconSource.Duckduckgo,
  });

  FavIconSource source;

  FavIconSourceApi _getFaviconSource(String url) {
    switch (source) {
      case FavIconSource.Slef:
        return SlefFavIconSourceApi(url.simpleToDomain());
      case FavIconSource.Cravatar:
        return CravatarFavIconSourceApi(url.simpleToDomain());
      case FavIconSource.Duckduckgo:
        return DuckduckgoFavIconSourceApi(url.simpleToDomain());
      case FavIconSource.Google:
        return GoogleFavIconSourceApi(url.simpleToDomain());
    }
  }

  @override
  Future<Uint8List> fetch(
    String url, {
    BytesReceivedCallback? onBytesReceived,
  }) async {
    Object lastError = ArgumentError("not favicon url");

    final source = _getFaviconSource(url);

    for (final item in source.getFavIconUrls()) {
      try {
        final data = await super.fetch(
          item,
          onBytesReceived: onBytesReceived,
        );

        if (source.isDefault(data)) throw Exception("is default favicon");
        return data;
      } catch (e) {
        debugPrint("fetch favicon ,$e");
        lastError = e;
      }
    }
    throw lastError;
  }
}

class FaviconCacheManager extends BaseCacheManager<Uint8List> {
  FaviconCacheManager({
    this.label = "favicon",
    @visibleForTesting String? cacheDir,
  }) : _cacheDir = cacheDir;

  final String label;

  String? _cacheDir;

  Future<String> _getCacheDir() async {
    if (_cacheDir != null) return _cacheDir!;

    Directory dir = switch (Platform.operatingSystem) {
      "android" => (await getExternalStorageDirectory()) ??
          (await getApplicationSupportDirectory()),
      _ => await getApplicationSupportDirectory(),
    };

    dir = Directory(path.join(dir.path, "cache", label));

    if (!(await dir.exists())) {
      await dir.create(recursive: true);
    }

    _cacheDir = dir.path;

    return _cacheDir!;
  }

  String _transformKey(String key) {
    // TODO! 使用 Base36-Lower 编码他, 后续需要解码会来用的
    return key.simpleToDomain().toLowerCase();
  }

  Future<File> _file(String key) async {
    return File(path.join(await _getCacheDir(), _transformKey(key)));
  }

  @override
  Future<void> clear() async {
    final dir = await _getCacheDir();
    await Directory(dir).delete(recursive: true);
  }

  @override
  Future<bool> exist(String key) async {
    return (await _file(key)).exists();
  }

  @override
  Future<Uint8List?> read(String key) async {
    final file = await _file(key);
    if (!(await file.exists())) return null;
    return await file.readAsBytes();
  }

  @override
  Future<void> write(String key, Uint8List? value) async {
    final file = await _file(key);
    if (value == null && (await file.exists())) {
      await file.delete();
    } else if (value != null) {
      await file.writeAsBytes(value);
    }
  }
}
