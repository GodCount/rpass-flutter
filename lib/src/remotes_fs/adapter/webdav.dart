import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:webdav_client/webdav_client.dart';

import '../auth_field.dart';
import '../remote_fs.dart';

class WebdavConfig extends RemoteClientConfig {
  WebdavConfig({
    required this.uri,
    required this.user,
    required this.password,
    required this.type,
  });

  static final Map<String, AuthField> authFields = {
    "uri": TextAuthField(
      key: "uri",
      description: "webdav api uri",
      value: "",
    ),
    "user": TextAuthField(
      key: "user",
      description: "webdav user",
      value: "",
    ),
    "password": PasswordAuthField(
      key: "password",
      description: "webdav user password",
      value: "",
    ),
    "type": OptionAuthField(
      key: "type",
      description: "auth type",
      value: AuthType.NoAuth.name,
      optionList: AuthType.values.map((item) => item.name).toList(),
    )
  };

  factory WebdavConfig.formAuthField(Map<String, AuthField> formData) {
    return WebdavConfig(
      uri: getField<TextAuthField>(formData, "uri").value,
      user: getField<TextAuthField>(formData, "user").value,
      password: getField<PasswordAuthField>(formData, "password").value,
      type: switch (getField<OptionAuthField>(formData, "type").value) {
        "BasicAuth" => AuthType.BasicAuth,
        "DigestAuth" => AuthType.DigestAuth,
        _ => AuthType.NoAuth
      },
    );
  }

  final String uri;
  final String user;
  final String password;
  final AuthType type;
}

class WebdavClient extends RemoteClient<WebdavConfig> {
  static Future<WebdavClient> create(Map<String, AuthField> formData) async {
    final WebdavConfig config = WebdavConfig.formAuthField(formData);

    final client = newClient(
      config.uri,
      user: config.user,
      password: config.password,
      // debug: true,
    );

    client.setHeaders({'accept-charset': 'utf-8'});
    client.setConnectTimeout(8000);
    client.setSendTimeout(8000);
    client.setReceiveTimeout(8000);

    await client.ping();
    return WebdavClient._(config, client);
  }

  WebdavClient._(super.config, Client client) : _client = client;

  final Client _client;

  CancelToken? _transformCancel(CancelSignal? cancelSignal) {
    if (cancelSignal == null) return null;
    final CancelToken cancelToken = CancelToken();
    cancelSignal.onCancelSignal = (reason) {
      cancelToken.cancel(reason);
    };
    return cancelToken;
  }

  RemoteFile _transformFile(File file) {
    assert(file.path != null, "path is null");
    return RemoteFile(
      client: this,
      path: file.path!,
      dir: file.isDir ?? false,
      size: file.size ?? 0,
      cTime: file.cTime,
      mTime: file.mTime,
    );
  }

  @override
  Future<void> delete(String path, [CancelSignal? cancelSignal]) {
    return _client.remove(path, _transformCancel(cancelSignal));
  }

  @override
  Future<RemoteFile> mkdir({
    required String path,
    bool recursive = false,
    CancelSignal? cancelSignal,
  }) async {
    final cancelToken = _transformCancel(cancelSignal);
    await (recursive
        ? _client.mkdirAll(path, cancelToken)
        : _client.mkdir(path, cancelToken));
    return await readFileInfo(path, cancelSignal);
  }

  @override
  Future<Uint8List> readFile({
    required String path,
    OnProgress? onProgress,
    CancelSignal? cancelSignal,
  }) async {
    return Uint8List.fromList(
      await _client.read(
        path,
        onProgress: onProgress,
        cancelToken: _transformCancel(cancelSignal),
      ),
    );
  }

  @override
  Future<RemoteFile> readFileInfo(
    String path, [
    CancelSignal? cancelSignal,
  ]) async {
    return _transformFile(
      await _client.readProps(
        path,
        _transformCancel(cancelSignal),
      ),
    );
  }

  @override
  Future<List<RemoteFile>> readdir(
    String path, [
    CancelSignal? cancelSignal,
  ]) async {
    return (await _client.readDir(path, _transformCancel(cancelSignal)))
        .map(_transformFile)
        .toList();
  }

  @override
  Future<RemoteFile> move({
    required String oldPath,
    required String newPath,
    bool overwrite = false,
    CancelSignal? cancelSignal,
  }) async {
    await _client.rename(
      oldPath,
      newPath,
      overwrite,
      _transformCancel(cancelSignal),
    );
    return await readFileInfo(newPath, cancelSignal);
  }

  @override
  Future<RemoteFile> copy({
    required String srcPath,
    required String destPath,
    bool overwrite = false,
    CancelSignal? cancelSignal,
  }) async {
    final cancelToken = _transformCancel(cancelSignal);

    await _client.copy(srcPath, destPath, overwrite, cancelToken);
    return await readFileInfo(destPath, cancelSignal);
  }

  @override
  Future<RemoteFile> writeFile({
    required String path,
    required Uint8List data,
    OnProgress? onProgress,
    CancelSignal? cancelSignal,
  }) async {
    await _client.write(
      path,
      data,
      onProgress: onProgress,
      cancelToken: _transformCancel(cancelSignal),
    );
    return await readFileInfo(path, cancelSignal);
  }
}
