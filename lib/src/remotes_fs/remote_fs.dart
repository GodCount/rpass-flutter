import 'dart:typed_data';

import 'auth_field.dart';

class CancelSignalException implements Exception {
  CancelSignalException(this.message, this.stackTrace);

  final StackTrace stackTrace;
  final Object message;

  @override
  String toString() {
    return "CancelSignalException: $message";
  }
}

typedef OnCancelSignal = void Function(CancelSignalException reason);
typedef OnProgress = void Function(int count, int total);

class CancelSignal {
  CancelSignalException? _error;

  CancelSignalException? get error => _error;

  OnCancelSignal? onCancelSignal;

  void cacnel([Object? reason]) {
    _error = CancelSignalException(reason ?? "Cancelled!", StackTrace.current);
    if (onCancelSignal != null) {
      onCancelSignal!(_error!);
    }
  }
}

abstract interface class RemoteFileSystem {
  Future<RemoteFile> writeFile({
    required String path,
    required Uint8List data,
    OnProgress? onProgress,
    CancelSignal? cancelSignal,
  });

  Future<RemoteFile> move({
    required String oldPath,
    required String newPath,
    bool overwrite = false,
    CancelSignal? cancelSignal,
  });

  Future<RemoteFile> copy({
    required String srcPath,
    required String destPath,
    bool overwrite = false,
    CancelSignal? cancelSignal,
  });

  Future<RemoteFile> readFileInfo(
    String path, [
    CancelSignal? cancelSignal,
  ]);
  Future<Uint8List> readFile({
    required String path,
    OnProgress? onProgress,
    CancelSignal? cancelSignal,
  });

  Future<List<RemoteFile>> readdir(
    String path, [
    CancelSignal? cancelSignal,
  ]);

  Future<RemoteFile> mkdir({
    required String path,
    bool recursive = false,
    CancelSignal? cancelSignal,
  });

  Future<void> delete(
    String path, [
    CancelSignal? cancelSignal,
  ]);
}

class RemoteFile {
  RemoteFile({
    required RemoteClient client,
    required String path,
    required bool dir,
    int size = 0,
    DateTime? cTime,
    DateTime? mTime,
  })  : _client = client,
        _path = path,
        _dir = dir,
        _size = size,
        _cTime = cTime,
        _mTime = mTime;

  final RemoteClient _client;

  late bool _dir;
  late int _size;
  late String _path;
  late DateTime? _cTime;
  late DateTime? _mTime;

  bool get dir => _dir;
  int get size => _size;
  String get path => _path;
  DateTime? get cTime => _cTime;
  DateTime? get mTime => _mTime;

  void _updateInfo(RemoteFile file) {
    _dir = file.dir;
    _size = file.size;
    _path = file.path;
    _cTime = file.cTime;
    _mTime = file.mTime;
  }

  Future<void> write(
    Uint8List data, [
    CancelSignal? cancelSignal,
  ]) async {
    assert(!dir, "this is dir");
    _updateInfo(await _client.writeFile(
      path: path,
      data: data,
      cancelSignal: cancelSignal,
    ));
  }

  Future<void> move({
    required String newPath,
    bool overwrite = false,
    CancelSignal? cancelSignal,
  }) async {
    _updateInfo(await _client.move(
      oldPath: path,
      newPath: newPath,
      overwrite: overwrite,
      cancelSignal: cancelSignal,
    ));
  }

  Future<RemoteFile> copy({
    required String destPath,
    bool overwrite = false,
    CancelSignal? cancelSignal,
  }) {
    return _client.copy(
      srcPath: path,
      destPath: destPath,
      overwrite: overwrite,
      cancelSignal: cancelSignal,
    );
  }

  Future<Uint8List> readFile({
    OnProgress? onProgress,
    CancelSignal? cancelSignal,
  }) {
    return _client.readFile(
      path: path,
      onProgress: onProgress,
      cancelSignal: cancelSignal,
    );
  }

  Future<List<RemoteFile>> readdir(
    String path, [
    CancelSignal? cancelSignal,
  ]) {
    assert(dir, "this not dir");
    return _client.readdir(path, cancelSignal);
  }

  Future<void> delete([
    CancelSignal? cancelSignal,
  ]) {
    return _client.delete(path, cancelSignal);
  }

  @override
  String toString() {
    return "RemoteFile {path: $path, dir: $dir, size:$size, cTime:$cTime, mTime:$mTime}";
  }
}

abstract class RemoteClient<T extends RemoteClientConfig>
    implements RemoteFileSystem {
  RemoteClient(this.config);

  final T config;
}
