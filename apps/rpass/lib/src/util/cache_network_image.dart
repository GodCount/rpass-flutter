import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'package:dio/dio.dart';

final _logger = Logger("util:cache_network_image");

typedef _SimpleDecoderCallback =
    Future<ui.Codec> Function(ui.ImmutableBuffer buffer);

abstract class BaseCacheManager<T> {
  Future<bool> exist(String key);
  Future<T?> read(String key);
  Future<void> write(String key, T? value);
  Future<void> clear();
  Future<int> size();
}

class FetchNetworkImage {
  @protected
  static final Dio dio = Dio();

  Future<Response<Uint8List>> fetch(
    String url, {
    ProgressCallback? onReceiveProgress,
  }) async {
    final Response<Uint8List> response = await dio.fetch(
      RequestOptions(
        baseUrl: url,
        responseType: .bytes,
        onReceiveProgress: onReceiveProgress,
      ),
    );

    if (response.data == null || response.data!.isEmpty) {
      throw Exception('FetchNetworkImage is an empty file: $url');
    }

    return response;
  }
}

class MemoryImageCacheManager {
  MemoryImageCacheManager._();

  static MemoryImageCacheManager get instance =>
      MemoryImageCacheManager._initInstances();
  static MemoryImageCacheManager? _instance;

  static MemoryImageCacheManager _initInstances() {
    _instance ??= MemoryImageCacheManager._();
    return _instance!;
  }

  final _cacheKeys = <WeakReference<CacheNetworkImage>>{};

  void add(CacheNetworkImage value) {
    _cacheKeys.add(WeakReference(value));
  }

  void evict(String url) {
    for (final key in _cacheKeys) {
      if (key.target != null && key.target!.url == url) {
        PaintingBinding.instance.imageCache.evict(key.target!);
        _cacheKeys.remove(key);
        break;
      }
    }
  }

  void clear() {
    for (final key in _cacheKeys) {
      if (key.target != null) {
        PaintingBinding.instance.imageCache.evict(key.target!);
      }
    }
    _cacheKeys.clear();
  }
}

class CacheNetworkImage extends ImageProvider<CacheNetworkImage> {
  const CacheNetworkImage(
    this.url, {
    this.scale = 1.0,
    this.cacheManager,
    this.fetchNetworkImage,
  });

  final String url;

  final double scale;

  final BaseCacheManager<Uint8List>? cacheManager;

  final FetchNetworkImage? fetchNetworkImage;

  static final FetchNetworkImage _defaultFetchNetworkImage =
      FetchNetworkImage();

  FetchNetworkImage get _fetchNetworkImage =>
      fetchNetworkImage ?? _defaultFetchNetworkImage;

  @override
  Future<CacheNetworkImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<CacheNetworkImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    CacheNetworkImage key,
    ImageDecoderCallback decode,
  ) {
    final StreamController<ImageChunkEvent> chunkEvents =
        StreamController<ImageChunkEvent>();

    MemoryImageCacheManager.instance.add(key);

    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents, decode: decode),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      debugLabel: key.url,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<CacheNetworkImage>('Image key', key),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
    CacheNetworkImage key,
    StreamController<ImageChunkEvent> chunkEvents, {
    required _SimpleDecoderCallback decode,
  }) async {
    try {
      assert(key == this);

      Uint8List? bytes;

      try {
        if (cacheManager != null && await cacheManager!.exist(key.url)) {
          bytes = await cacheManager!.read(key.url);
        }
      } catch (e) {
        _logger.warning(
          "cache manager (${cacheManager.runtimeType}) read fail $e",
        );
      }

      bytes ??= (await _fetchNetworkImage.fetch(
        key.url,
        onReceiveProgress: (cumulative, total) {
          chunkEvents.add(
            ImageChunkEvent(
              cumulativeBytesLoaded: cumulative,
              expectedTotalBytes: total,
            ),
          );
        },
      )).data!;

      Future<ui.Codec> warpDecode(ui.ImmutableBuffer buffer) async {
        try {
          final result = await decode(buffer);
          if (cacheManager != null) {
            try {
              await cacheManager!.write(key.url, bytes);
            } catch (e) {
              _logger.warning(
                "cache manager (${cacheManager.runtimeType}) write fail $e",
              );
            }
          }
          return result;
        } catch (e) {
          if (cacheManager != null) {
            try {
              await cacheManager!.write(key.url, null);
            } catch (e) {
              _logger.warning(
                "cache manager (${cacheManager.runtimeType}) write fail $e",
              );
            }
          }
          rethrow;
        }
      }

      return warpDecode(await ui.ImmutableBuffer.fromUint8List(bytes));
    } catch (e) {
      // Depending on where the exception was thrown, the image cache may not
      // have had a chance to track the key in the cache at all.
      // Schedule a microtask to give the cache a chance to add the key.
      scheduleMicrotask(() {
        PaintingBinding.instance.imageCache.evict(key);
      });
      rethrow;
    } finally {
      chunkEvents.close();
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is CacheNetworkImage &&
        other.url == url &&
        other.scale == scale &&
        other._fetchNetworkImage == _fetchNetworkImage;
  }

  @override
  int get hashCode => Object.hash(url, scale, _fetchNetworkImage.hashCode);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'CacheNetworkImage')}("$url", scale: ${scale.toStringAsFixed(1)})';
}
