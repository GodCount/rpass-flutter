import 'dart:io';
import 'dart:typed_data';

import '../remote_fs.dart';

class RemoteFileStat {
  RemoteFileStat({
    required this.name,
    required this.changed,
    required this.modified,
    required this.type,
    required this.size,
  });
  final String name;
  final DateTime changed;
  final DateTime modified;
  final FileSystemEntityType type;
  final int size;
}

abstract class RemoteFileConfig {
  const RemoteFileConfig();

  factory RemoteFileConfig.fromJson(Map<String, String?> config) {
    throw UnimplementedError('Subclasses must implement fromJson');
  }

  Future<RemoteFile> open();

  Map<String, String?> toJson();

}

abstract interface class RemoteFile {
  String get path;
  String get name;

  /// 根据当前状态输出配置
  Future<RemoteFileConfig> toConfig();

  /// 文件或文件夹是否存在
  Future<bool> exists();

  /// 读取文件内容
  /// 如果是文件夹则会报错
  Future<Uint8List> read();

  /// 写入内容
  /// 如果是文件夹则会报错
  Future<void> write(Uint8List bytes);

  /// 拷贝到指定路径
  /// [to] 一个绝对路径
  Future<RemoteFile> copy(String to);

  /// 重命名文件, 移动文件
  /// [to] 一个绝对路径
  Future<RemoteFile> rename(String to);

  /// 删除当前文件或文件夹
  /// 如果文件夹存在内容则全部删除
  Future<void> delete();

  /// 创建文件夹
  /// 如果是文件或文件夹存在则会报错
  Future<void> mkdir([bool recursive = false]);

  /// 获取文件或文件夹信息
  Future<RemoteFileStat> stat();

  /// 获取当前文件夹下内容
  /// 如果是文件则报错
  Future<List<RemoteFileStat>> list();

  /// 基于当前相对路径打开一个新的远程文件
  /// [..] 则可以打开上层文件夹
  Future<RemoteFile> relative(String path);

  static Future<RemoteFile> open(Map<String, String?> config) async {
    switch (config["type"]) {
      case "webdav":
        return WebDavConfig.fromJson(config).open();
    }
    throw UnsupportedError("Adapter type ${config["type"]}");
  }
}
