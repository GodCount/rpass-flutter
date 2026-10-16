import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' show posix;
import '../remote_fs_base.dart';

class LocalConfig extends RemoteFileConfig {
  LocalConfig({required this.path});

  final String path;

  factory LocalConfig.fromJson(Map<String, String?> config) {
    return LocalConfig(
      path: config["path"] ?? Directory.current.path,
    );
  }

  @override
  Future<RemoteFile> open() {
    return LocalFile.open(this);
  }

  @override
  Map<String, String?> toJson() {
    return {"path": path};
  }

  LocalConfig copyWith({required String? path}) {
    return LocalConfig(path: path ?? this.path);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is LocalConfig && other.path == path;
  }

  @override
  int get hashCode => path.hashCode;
}

class LocalFile implements RemoteFile {
  LocalFile._({required LocalConfig config, required this.path})
    : _config = config,
      name = posix.basename(path);

  static Future<LocalFile> open(LocalConfig config) async {
    return LocalFile._(config: config, path: config.path);
  }

  final LocalConfig _config;

  @override
  final String name;
  @override
  final String path;

  @override
  Future<LocalFile> copy(String to) async {
    await _copy(path, to);
    return LocalFile._(config: _config, path: to);
  }

  static Future<void> _copy(String from, String to) async {
    final type = await FileSystemEntity.type(from, followLinks: false);
    switch (type) {
      case FileSystemEntityType.directory:
        await Directory(to).create(recursive: true);
        await for (final item in Directory(from).list()) {
          await _copy(item.path, posix.join(to, posix.basename(item.path)));
        }
      case FileSystemEntityType.link:
        final target = await Link(from).target();
        final link = Link(to);
        if (await link.exists()) {
          await link.delete();
        }
        await link.create(target);
      case FileSystemEntityType.notFound:
        throw PathNotFoundException(
          from,
          const OSError("No such file or directory", 2),
          "Cannot copy file",
        );
      default:
        await File(from).copy(to);
    }
  }

  @override
  Future<void> delete() async {
    final type = await FileSystemEntity.type(path, followLinks: false);
    switch (type) {
      case FileSystemEntityType.directory:
        await Directory(path).delete(recursive: true);
      case FileSystemEntityType.link:
        await Link(path).delete();
      default:
        await File(path).delete();
    }
  }

  @override
  Future<bool> exists() async {
    return await FileSystemEntity.type(path) != FileSystemEntityType.notFound;
  }

  @override
  Future<List<RemoteFileStat>> list() async {
    final List<RemoteFileStat> result = [];
    await for (final item in Directory(path).list()) {
      final stat = await item.stat();
      result.add(
        RemoteFileStat(
          name: posix.basename(item.path),
          changed: stat.changed,
          modified: stat.modified,
          type: stat.type,
          size: stat.size,
        ),
      );
    }
    return result;
  }

  @override
  Future<void> mkdir([bool recursive = false]) async {
    await Directory(path).create(recursive: recursive);
  }

  @override
  Future<Uint8List> read() {
    return File(path).readAsBytes();
  }

  @override
  Future<LocalFile> relative(String path) async {
    return LocalFile._(config: _config, path: posix.join(this.path, path));
  }

  @override
  Future<LocalFile> rename(String to) async {
    await File(path).rename(to);
    return LocalFile._(config: _config, path: to);
  }

  @override
  Future<RemoteFileStat> stat() async {
    final stat = await File(path).stat();
    return RemoteFileStat(
      name: posix.basename(path),
      changed: stat.changed,
      modified: stat.modified,
      type: stat.type,
      size: stat.size,
    );
  }

  @override
  Future<LocalConfig> toConfig() async {
    return _config.copyWith(path: path);
  }

  @override
  Future<void> write(Uint8List bytes) {
    return File(path).writeAsBytes(bytes);
  }
}
