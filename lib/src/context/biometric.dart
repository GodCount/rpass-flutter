import 'dart:convert';

import 'package:biometric_storage/biometric_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../i18n.dart';
import 'store.dart';

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

class BiometricState extends State<Biometric> {
  static CanAuthenticateResponse _authenticateResponse =
      CanAuthenticateResponse.unsupported;

  final BiometricStorage _biometric = BiometricStorage();

  BiometricStorageFile? _storageFile;

  bool get isSupport =>
      _authenticateResponse == CanAuthenticateResponse.success ||
      _authenticateResponse == CanAuthenticateResponse.statusUnknown;

  bool get enable =>
      isSupport && StoreProvider.of(context).settings.enableBiometric;

  static Future<void> initCanAuthenticate() async {
    try {
      _authenticateResponse = await BiometricStorage().canAuthenticate();
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

  Future<BiometricStorageFile> _getStorageFile(BuildContext context) async {
    _assertBiometric();
    if (_storageFile != null) return _storageFile!;
    _storageFile = await _biometric.getStorage("credentials",
        promptInfo: _getPromptInfo(context));
    return _storageFile!;
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

    final credentials = await (await _getStorageFile(context))
        .read(promptInfo: _getPromptInfo(context));
    if (credentials == null || credentials.isEmpty) {
      StoreProvider.of(context).settings.seEnableBiometric(false);
      throw Exception("no record token from biometric");
    }

    return _decode(credentials);
  }

  Future<void> updateCredentials(
    BuildContext context,
    Uint8List? credentials,
  ) async {
    _assertBiometric();
    if (credentials == null) {
      await (await _getStorageFile(context))
          .delete(promptInfo: _getPromptInfo(context));
    } else {
      await (await _getStorageFile(context))
          .write(_encode(credentials), promptInfo: _getPromptInfo(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
