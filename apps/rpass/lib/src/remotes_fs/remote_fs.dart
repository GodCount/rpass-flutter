import 'package:flutter/material.dart';
import 'package:remote_fs/remote_fs.dart';

import '../i18n.dart';
import '../kdbx/kdbx.dart';
import 'auth_field.dart';

enum RemoteType { webdav }

extension _WebDavKdbxEntryField on WebDavConfig {
  static final kdbxKeyType = KdbxKey("webdav_type");
  static final kdbxKeyPath = KdbxKey("webdav_path");
  static final kdbxKeyAuthHeader = KdbxKey("webdav_auth_header");

  Map<KdbxKey, StringValue> toKdbx() {
    return {
      RemoteFileKdbxEntryField.kdbxKeyType: PlainValue(RemoteType.webdav.name),
      KdbxKeyCommon.URL: PlainValue(url),
      KdbxKeyCommon.USER_NAME: PlainValue(username),
      KdbxKeyCommon.PASSWORD: PlainValue(password),
      kdbxKeyPath: PlainValue(path),
      kdbxKeyType: PlainValue(type.name),
      if (authHeader != null) kdbxKeyAuthHeader: PlainValue(authHeader),
    };
  }

  static WebDavConfig fromKdbx(KdbxEntry entry) {
    return WebDavConfig.fromJson({
      "url": entry.getActualString(KdbxKeyCommon.URL),
      "username": entry.getActualString(KdbxKeyCommon.USER_NAME),
      "password": entry.getActualString(KdbxKeyCommon.PASSWORD),
      "path": entry.getActualString(kdbxKeyPath),
      "type": entry.getActualString(kdbxKeyType),
      "authHeader": entry.getActualString(kdbxKeyAuthHeader),
    });
  }
}

extension RemoteFileKdbxEntryField on RemoteFileConfig {
  static final kdbxKeyType = KdbxKey("remote_type");

  Map<KdbxKey, StringValue> toKdbx() {
    return switch (this) {
      WebDavConfig config => config.toKdbx(),
      _ => throw UnsupportedError("type is $runtimeType"),
    };
  }

  static RemoteFileConfig fromKdbx(KdbxEntry entry) {
    final remoteType = entry.getActualString(kdbxKeyType);
    return switch (remoteType) {
      "webdav" => _WebDavKdbxEntryField.fromKdbx(entry),
      _ => throw UnsupportedError("type is $remoteType"),
    };
  }
}

extension BuilderConfig on RemoteType {
  RemoteFileConfig buildRemoteFileConfig(Map<String, AuthField> formData) {
    final Map<String, String?> map = {};
    for (final item in formData.values) {
      map[item.key] = item.value.toString();
    }
    return switch (this) {
      .webdav => WebDavConfig.fromJson(map),
    };
  }

  Map<String, AuthField> buildAuthFields(
    BuildContext context,
    Map<String, String?>? config,
  ) {
    final t = I18n.of(context)!;
    config ??= {};
    return switch (this) {
      .webdav => {
        "url": TextAuthField(
          key: "url",
          description: t.api_url,
          value: config["url"] ?? "",
        ),
        "username": TextAuthField(
          key: "username",
          description: t.account,
          value: config["username"] ?? "",
        ),
        "password": PasswordAuthField(
          key: "password",
          description: t.password,
          value: config["password"] ?? "",
        ),
        "type": OptionAuthField(
          key: "type",
          description: t.auth_type,
          value: config["type"] ?? AuthType.NoAuth.name,
          optionList: AuthType.values.map((item) => item.name).toList(),
        ),
        "authHeader": TextAuthField(
          key: "authHeader",
          value: config["authHeader"] ?? "",
          description: "Digest Auth Header",
        ),
      },
    };
  }
}
