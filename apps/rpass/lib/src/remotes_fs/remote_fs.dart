import 'package:flutter/material.dart';
import 'package:keepass_core/keepass_core.dart';
import 'package:remote_fs/remote_fs.dart';

import '../i18n.dart';
import '../kdbx/kdbx.dart';
import 'auth_field.dart';

enum RemoteType { webdav }

extension _WebDavKdbxEntryField on WebDavConfig {
  static final kdbxKeyType = "webdav_type";
  static final kdbxKeyPath = "webdav_path";
  static final kdbxKeyAuthHeader = "webdav_auth_header";

  Map<String, FieldValue> toKdbx() {
    return {
      RemoteFileKdbxEntryField.kdbxKeyType: FieldValue.plaintext(RemoteType.webdav.name),
      KdbxKeyCommon.URL: FieldValue.plaintext(url),
      KdbxKeyCommon.USER_NAME: FieldValue.plaintext(username),
      KdbxKeyCommon.PASSWORD: FieldValue.protected(password),
      kdbxKeyPath: FieldValue.plaintext(path),
      kdbxKeyType: FieldValue.plaintext(type.name),
      if (authHeader != null) kdbxKeyAuthHeader: FieldValue.plaintext(authHeader!),
    };
  }

  static WebDavConfig fromKdbx(EntryData entry) {
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
  static final kdbxKeyType = "remote_type";

  Map<String, FieldValue> toKdbx() {
    return switch (this) {
      WebDavConfig config => config.toKdbx(),
      _ => throw UnsupportedError("type is $runtimeType"),
    };
  }

  static RemoteFileConfig? fromKdbx(EntryData entry) {
    final remoteType = entry.getActualString(kdbxKeyType);
    return switch (remoteType) {
      "webdav" => _WebDavKdbxEntryField.fromKdbx(entry),
      _ => null,
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
