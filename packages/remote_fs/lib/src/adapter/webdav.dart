import 'dart:typed_data';
import 'package:path/path.dart' show basename, join;
import 'package:webdav_client/webdav_client.dart';

import '../remote_fs_base.dart';

export 'package:webdav_client/webdav_client.dart' show AuthType;

class WebDavConfig extends RemoteFileConfig {
  WebDavConfig({
    required this.url,
    required this.path,
    required this.username,
    required this.password,
    this.type = AuthType.NoAuth,
    this.authHeader,
  });

  factory WebDavConfig.fromJson(Map<String, String?> config) {
    return WebDavConfig(
      url: config["url"] as String,
      path: config["path"] ?? "/",
      username: config["username"] as String,
      password: config["password"] as String,
      type: switch (config["type"]) {
        "BasicAuth" => AuthType.BasicAuth,
        "DigestAuth" => AuthType.DigestAuth,
        _ => AuthType.NoAuth,
      },
      authHeader: config["authHeader"],
    );
  }

  final String url;
  final String path;
  final String username;
  final String password;
  final AuthType type;
  final String? authHeader;

  @override
  Future<WebDavFile> open() {
    return WebDavFile.open(this);
  }

  @override
  Map<String, String?> toJson() {
    return {
      "url": url,
      "path": path,
      "username": username,
      "password": password,
      "type": type.name,
      "authHeader": authHeader,
    };
  }

  WebDavConfig copyWith({
    String? url,
    String? path,
    String? username,
    String? password,
    AuthType? type,
    String? authHeader,
  }) {
    return WebDavConfig(
      url: url ?? this.url,
      path: path ?? this.path,
      username: username ?? this.username,
      password: password ?? this.password,
      type: type ?? this.type,
      authHeader: authHeader ?? this.authHeader,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is WebDavConfig &&
        other.url == url &&
        other.path == path &&
        other.username == username &&
        other.password == password &&
        other.type == type &&
        other.authHeader == authHeader;
  }

  @override
  int get hashCode =>
      Object.hash(url, path, username, password, type, authHeader);
}

class WebDavFile implements RemoteFile {
  WebDavFile._({
    required Client client,
    required WebDavConfig config,
    required this.path,
  }) : _client = client,
       _config = config,
       name = basename(path);

  static Future<WebDavFile> open(WebDavConfig config) async {
    final debug = false;
    final client = Client(
      uri: config.url,
      c: WdDio(debug: debug),
      auth: switch (config.type) {
        .BasicAuth => BasicAuth(user: config.username, pwd: config.password),
        .DigestAuth => DigestAuth(
          user: config.username,
          pwd: config.password,
          dParts: DigestParts(config.authHeader),
        ),
        .NoAuth => Auth(user: config.username, pwd: config.password),
      },
      debug: debug,
    );

    client.setHeaders({'accept-charset': 'utf-8'});
    client.setConnectTimeout(8000);
    client.setSendTimeout(8000);
    client.setReceiveTimeout(8000);

    await client.ping();

    return WebDavFile._(client: client, config: config, path: config.path);
  }

  final Client _client;
  final WebDavConfig _config;

  @override
  final String name;
  @override
  final String path;

  @override
  Future<WebDavFile> copy(String to) async {
    await _client.copy(path, to, true);
    return WebDavFile._(client: _client, config: _config, path: to);
  }

  @override
  Future<void> delete() async {
    await _client.removeAll(path);
  }

  @override
  Future<bool> exists() async {
    try {
      await stat();
      return true;
    } catch (e) {
      if (e is StateError || e.toString().contains("Not Found")) {
        return false;
      }
      rethrow;
    }
  }

  @override
  Future<List<RemoteFileStat>> list() async {
    final List<RemoteFileStat> result = [];
    for (final item in await _client.readDir(path)) {
      if (item.name != null) {
        result.add(
          RemoteFileStat(
            name: item.name ?? name,
            changed: item.cTime ?? DateTime.fromMillisecondsSinceEpoch(0),
            modified: item.mTime ?? DateTime.fromMillisecondsSinceEpoch(0),
            size: item.size ?? 0,
            type: item.isDir == true ? .directory : .file,
          ),
        );
      }
    }
    return result;
  }

  @override
  Future<void> mkdir([bool recursive = false]) async {
    if (recursive) {
      await _client.mkdirAll(path);
    } else {
      await _client.mkdir(path);
    }
  }

  @override
  Future<WebDavFile> rename(String to) async {
    await _client.rename(path, to, true);
    return WebDavFile._(client: _client, config: _config, path: to);
  }

  @override
  Future<Uint8List> read() async {
    return Uint8List.fromList(await _client.read(path));
  }

  @override
  Future<RemoteFileStat> stat() async {
    final file = await _client.readProps(path);
    return RemoteFileStat(
      name: file.name ?? name,
      changed: file.cTime ?? DateTime.fromMillisecondsSinceEpoch(0),
      modified: file.mTime ?? DateTime.fromMillisecondsSinceEpoch(0),
      size: file.size ?? 0,
      type: file.isDir == true ? .directory : .file,
    );
  }

  @override
  Future<void> write(Uint8List bytes) async {
    await _client.write(path, bytes);
  }

  @override
  Future<WebDavFile> relative(String path) async {
    return WebDavFile._(
      client: _client,
      config: _config,
      path: join(this.path, path),
    );
  }

  @override
  Future<WebDavConfig> toConfig() async {
    return _config.copyWith(path: path);
  }
}
