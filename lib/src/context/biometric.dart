import 'dart:collection';
import 'dart:convert';

import 'package:biometric_storage/biometric_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../i18n.dart';
import '../store/index.dart';

final _logger = Logger("context:biometric");

class Biometric extends StatefulWidget {
  const Biometric({super.key, required this.child});

  final Widget child;

  static BiometricState of(BuildContext context) {
    BiometricState? biometric;
    if (context is StatefulElement && context.state is BiometricState) {
      biometric = context.state as BiometricState;
    }

    biometric = biometric ?? context.findAncestorStateOfType<BiometricState>();

    assert(() {
      if (biometric == null) {
        throw FlutterError(
          'Biometric operation requested with a context that does not include a Biometric.\n'
          'The context used to verify or updateToken from the Biometric must be that of a '
          'widget that is a descendant of a Biometric widget.',
        );
      }
      return true;
    }());

    return biometric!;
  }

  @override
  State<Biometric> createState() => BiometricState();
}

enum BiometricStorageKey {
  // 存储 kdbx 解密密钥
  credentials,
  // 用来验证指纹的，执行一下危险操作时确认权限
  owner,
}

class BiometricState extends State<Biometric> {
  static CanAuthenticateResponse _authenticateResponse =
      CanAuthenticateResponse.unsupported;

  static final BiometricStorage _biometric = BiometricStorage();

  final Map<String, BiometricStorageFile> _storageMap = HashMap();

  bool get isSupport =>
      _authenticateResponse == CanAuthenticateResponse.success ||
      _authenticateResponse == CanAuthenticateResponse.statusUnknown;

  bool get enable => isSupport && Store.instance.settings.enableBiometric;

  static Future<void> initCanAuthenticate() async {
    try {
      _authenticateResponse = await _biometric.canAuthenticate();
    } catch (e) {
      _logger.warning("unsupport biometric!", e);
    }
  }

  /// 需要 MaterialApp 下的 BuildContext 以获取 I18 context
  PromptInfo _getPromptInfo(BuildContext context) {
    final t = I18n.of(context)!;
    final iosPromptInfo = IosPromptInfo(
      saveTitle: t.biometric_prompt_subtitle,
      accessTitle: t.biometric_prompt_subtitle,
    );
    return PromptInfo(
      iosPromptInfo: iosPromptInfo,
      macOsPromptInfo: iosPromptInfo,
      androidPromptInfo: AndroidPromptInfo(
        title: t.biometric_prompt_title,
        subtitle: t.biometric_prompt_subtitle,
        negativeButton: t.cancel,
      ),
    );
  }

  void _assertBiometric() {
    if (!isSupport) {
      throw Exception(
          "unsupprt biometric authenticate response is $_authenticateResponse");
    }
  }

  Future<BiometricStorageFile> _getStorageFile(
    BuildContext context,
    BiometricStorageKey key, {
    // 只有第一次初始化时才有效
    StorageFileInitOptions? options,
  }) async {
    _assertBiometric();

    if (_storageMap.containsKey(key.name)) return _storageMap[key.name]!;

    _storageMap[key.name] = await _biometric.getStorage(
      key.name,
      options: options,
      promptInfo: _getPromptInfo(context),
    );

    return _storageMap[key.name]!;
  }

  String _encode(Uint8List data) {
    return base64.encode(data);
  }

  Uint8List _decode(String data) {
    return base64.decode(data);
  }

  Future<Uint8List> getCredentials(BuildContext context) async {
    _assertBiometric();

    if (!enable) {
      throw Exception("not enabled biometric");
    }

    final credentials =
        await (await _getStorageFile(context, BiometricStorageKey.credentials))
            .read(promptInfo: _getPromptInfo(context));
    if (credentials == null || credentials.isEmpty) {
      Store.instance.settings.seEnableBiometric(false);
      throw Exception("no record token from biometric");
    }

    return _decode(credentials);
  }

  Future<void> verifyOwner(BuildContext context) async {
    _assertBiometric();

    // 通过写入触发生物识别以验证权限
    await (await _getStorageFile(context, BiometricStorageKey.owner)).write(
      "owner",
      promptInfo: _getPromptInfo(context),
    );
  }

  Future<void> updateCredentials(
    BuildContext context,
    Uint8List? credentials,
  ) async {
    _assertBiometric();

    if (credentials == null) {
      await (await _getStorageFile(context, BiometricStorageKey.credentials))
          .delete(promptInfo: _getPromptInfo(context));
    } else {
      await (await _getStorageFile(
        context,
        BiometricStorageKey.credentials,
      ))
          .write(_encode(credentials), promptInfo: _getPromptInfo(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
