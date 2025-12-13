import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../util/cache_network_image.dart';
import '../util/common.dart';

enum FaviconSource {
  Slef,
  Google,
  Duckduckgo,
  Cravatar,
}

abstract class FaviconSourceApi {
  FaviconSourceApi(this.domain);

  final String domain;

  List<String> getFaviconUrls();

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

class SlefFaviconSourceApi extends FaviconSourceApi {
  SlefFaviconSourceApi(super.domain);

  @override
  List<String> getFaviconUrls() {
    return ["http://$domain/faviocn.ico"];
  }

  @override
  bool isDefault(Uint8List data) {
    return false;
  }
}

class GoogleFaviconSourceApi extends FaviconSourceApi {
  GoogleFaviconSourceApi(super.domain);

  @override
  List<String> getFaviconUrls() {
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

class DuckduckgoFaviconSourceApi extends FaviconSourceApi {
  DuckduckgoFaviconSourceApi(super.domain);

  @override
  List<String> getFaviconUrls() {
    return [
      "https://icons.duckduckgo.com/ip3/${_getSecondDomain()}.ico",
    ];
  }

  @override
  bool isDefault(Uint8List data) {
    return false;
  }
}

class CravatarFaviconSourceApi extends FaviconSourceApi {
  CravatarFaviconSourceApi(super.domain);

  @override
  List<String> getFaviconUrls() {
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

class FetchFavicon extends FetchNetworkImage {
  FetchFavicon([this._source = FaviconSource.Duckduckgo]);

  final FaviconSource _source;

  FaviconSourceApi _getFaviconSource(String url) {
    switch (_source) {
      case FaviconSource.Slef:
        return SlefFaviconSourceApi(url.simpleToDomain());
      case FaviconSource.Cravatar:
        return CravatarFaviconSourceApi(url.simpleToDomain());
      case FaviconSource.Duckduckgo:
        return DuckduckgoFaviconSourceApi(url.simpleToDomain());
      case FaviconSource.Google:
        return GoogleFaviconSourceApi(url.simpleToDomain());
    }
  }

  @override
  Future<Uint8List> fetch(
    String url, {
    BytesReceivedCallback? onBytesReceived,
  }) async {
    Object lastError = ArgumentError("not favicon url");

    final source = _getFaviconSource(url);

    for (final item in source.getFaviconUrls()) {
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

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is FetchFavicon &&
        other._source == _source ;
  }

  @override
  int get hashCode => Object.hash(_source, null);
}

class FaviconCacheManager extends BaseCacheManager<Uint8List> {
  FaviconCacheManager({
    this.label = "favicon",
    @visibleForTesting Directory? cacheDir,
  }) : _cacheDir = cacheDir;

  final String label;

  Directory? _cacheDir;

  Future<Directory> _getCacheDir() async {
    if (_cacheDir != null) {
      if (!(await _cacheDir!.exists())) {
        await _cacheDir!.create(recursive: true);
      }

      return _cacheDir!;
    }

    Directory dir = switch (Platform.operatingSystem) {
      "android" => (await getExternalStorageDirectory()) ??
          (await getApplicationSupportDirectory()),
      _ => await getApplicationSupportDirectory(),
    };

    _cacheDir = Directory(path.join(dir.path, "cache", label));

    if (!(await _cacheDir!.exists())) {
      await _cacheDir!.create(recursive: true);
    }

    return _cacheDir!;
  }

  Future<File> _file(String key) async {
    return File(path.join((await _getCacheDir()).path, md5(key)));
  }

  @override
  Future<void> clear() async {
    final dir = await _getCacheDir();
    await for (final file in dir.list()) {
      await file.delete(recursive: true);
    }
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

  @override
  Future<int> size() async {
    final dir = await _getCacheDir();
    return await dir.list().length;
  }
}
