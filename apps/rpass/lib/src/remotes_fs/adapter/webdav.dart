import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:webdav_client/webdav_client.dart';

import '../../kdbx/kdbx.dart';
import '../auth_field.dart';
import '../remote_fs.dart';
import '../../util/common.dart';

class WebdavConfig extends RemoteClientConfig {
  static final kdbxKeyType = KdbxKey("webdav_type");

  WebdavConfig({
    this.uri = "",
    this.user = "",
    this.password = "",
    this.type = AuthType.NoAuth,
  });

  String uri;
  String user;
  String password;
  AuthType type;

  @override
  Map<String, AuthField> toAuthFields() {
    return {
      "uri": TextAuthField(
        key: "uri",
        description: "WebDAV Api Uri",
        value: uri,
      ),
      "user": TextAuthField(
        key: "user",
        description: "WebDAV User",
        value: user,
      ),
      "password": PasswordAuthField(
        key: "password",
        description: "WebDAV User Password",
        value: password,
      ),
      "type": OptionAuthField(
        key: "type",
        description: "Auth Type",
        value: type.name,
        optionList: AuthType.values.map((item) => item.name).toList(),
      )
    };
  }

  @override
  Map<KdbxKey, StringValue> toKdbx() {
    return {
      KdbxKeyCommon.URL: PlainValue(uri),
      KdbxKeyCommon.USER_NAME: PlainValue(user),
      KdbxKeyCommon.PASSWORD: PlainValue(password),
      kdbxKeyType: PlainValue(type.name),
    };
  }

  @override
  void updateAuthField(Map<String, AuthField> formData) {
    uri = getField<TextAuthField>(formData, "uri").value;
    user = getField<TextAuthField>(formData, "user").value;
    password = getField<PasswordAuthField>(formData, "password").value;
    type = AuthType.values.toEnum(
      getField<OptionAuthField>(formData, "type").value,
      AuthType.NoAuth,
    );
  }

  @override
  void updateByKdbx(KdbxEntry kdbxEntry) {
    uri = kdbxEntry.getNonNullString(KdbxKeyCommon.URL);
    user = kdbxEntry.getNonNullString(KdbxKeyCommon.USER_NAME);
    password = kdbxEntry.getNonNullString(KdbxKeyCommon.PASSWORD);
    type = AuthType.values.toEnum(
      kdbxEntry.getNonNullString(kdbxKeyType),
      AuthType.NoAuth,
    );
  }

  @override
  Future<WebdavClient> buildClient() {
    return WebdavClient._createByConfig(this);
  }
}

class WebdavClient extends RemoteClient<WebdavConfig> {
  static Future<WebdavClient> _createByConfig(WebdavConfig config) async {
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
      name: file.name,
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
