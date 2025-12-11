import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../kdbx/icons.dart';
import '../kdbx/kdbx.dart';
import '../store/index.dart';
import '../util/cache_network_image.dart';
import '../util/common.dart';

class KdbxFaviconCacheManager extends BaseCacheManager<Uint8List> {
  KdbxFaviconCacheManager({
    this.label = "kdbx_favicon",
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

  Future<File> _file(String key) async {
    return File(path.join(await _getCacheDir(), md5(key)));
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

enum FavIconSource {
  All,
  Slef,
  Google,
  Duckduckgo,
}

class KdbxFetchFavIcon extends FetchNetworkImage {
  KdbxFetchFavIcon({
    this.source = FavIconSource.Duckduckgo,
  });

  FavIconSource source;

  String _getDomain(String url) {
    if (url.startsWith(RegExp(r"https?://"))) {
      return url.split("/")[2].trim();
    } else {
      return url.split("/")[0].trim();
    }
  }

  String _getSecondDomain(String domain) {
    final parts = domain.split(".").reversed.toList();
    if (parts.length < 2) return domain;

    return "${parts[1]}.${parts[0]}";
  }

  List<String> _getFaviconUrls(String url) {
    final domain = _getDomain(url);

    final List<String> urls = [
      if (source == FavIconSource.All || source == FavIconSource.Slef)
        "http://$domain/faviocn.ico",
      if (source == FavIconSource.All || source == FavIconSource.Duckduckgo)
        "https://icons.duckduckgo.com/ip3/${_getSecondDomain(domain)}.ico",
      if (source == FavIconSource.All || source == FavIconSource.Google)
        "https://www.google.com/s2/favicons?domain=$domain&sz=32"
    ];

    return urls;
  }

  @visibleForTesting
  List<String> getFaviconUrls(String url) {
    return _getFaviconUrls(url);
  }

  @override
  Future<Uint8List> fetch(
    String url, {
    BytesReceivedCallback? onBytesReceived,
  }) async {
    Object lastError = ArgumentError("not favicon url");

    for (final item in _getFaviconUrls(url)) {
      try {
        return await super.fetch(item, onBytesReceived: onBytesReceived);
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError;
  }
}

class KdbxIconWidgetData {
  KdbxIconWidgetData({
    required this.icon,
    this.customIcon,
    this.domain,
  });

  final KdbxIcon icon;
  final KdbxCustomIcon? customIcon;
  final String? domain;
}

class KdbxIconWidget extends StatelessWidget {
  const KdbxIconWidget({super.key, required this.kdbxIcon, this.size = 32});

  static final KdbxFaviconCacheManager _cacheManager =
      KdbxFaviconCacheManager();
  static final KdbxFetchFavIcon _fetchFavIcon = KdbxFetchFavIcon();

  final KdbxIconWidgetData kdbxIcon;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (kdbxIcon.customIcon != null) {
      return Image.memory(
        kdbxIcon.customIcon!.data,
        width: size,
        height: size,
      );
    }

    final icon = Icon(
      KdbxIcon2Material.to(kdbxIcon.icon),
      size: size,
    );

    if (kdbxIcon.domain == null ||
        Store.instance.settings.favIconSource == null) {
      return icon;
    }

    if (_fetchFavIcon.source != Store.instance.settings.favIconSource) {
      _fetchFavIcon.source = Store.instance.settings.favIconSource!;
    }

    return Image(
      image: CacheNetworkImage(
        kdbxIcon.domain!,
        cacheManager: _cacheManager,
        fetchNetworkImage: _fetchFavIcon,
      ),
      width: size,
      height: size,
      loadingBuilder: (context, child, loadingProgress) {
        if (child is Semantics &&
            child.child is RawImage &&
            (child.child! as RawImage).image != null) {
          return child;
        }
        return icon;
      },
      errorBuilder: (context, error, stackTrace) {
        return icon;
      },
    );
  }
}
