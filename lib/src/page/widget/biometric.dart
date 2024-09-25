import 'package:biometric_storage/biometric_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../i18n.dart';
import '../../store/index.dart';

class Biometric extends StatefulWidget {
  const Biometric({super.key, required this.store, required this.child});

  final Store store;
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

  bool get enable => isSupport && widget.store.settings.enableBiometric;

  static Future<void> initCanAuthenticate() async {
    try {
      _authenticateResponse = await BiometricStorage().canAuthenticate();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  PromptInfo _getPromptInfo() {
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

  Future<BiometricStorageFile> _getStorageFile() async {
    _assertBiometric();
    if (_storageFile != null) return _storageFile!;
    _storageFile =
        await _biometric.getStorage("token", promptInfo: _getPromptInfo());
    return _storageFile!;
  }

  Future<void> verify() async {
    _assertBiometric();

    if (!enable) {
      throw Exception("not enabled biometric");
    }

    final token =
        await (await _getStorageFile()).read(promptInfo: _getPromptInfo());
    if (token == null || token.isEmpty) {
      widget.store.settings.seEnableBiometric(false);
      throw Exception("no record token from biometric");
    }

    widget.store.verify.verifyToken(token);
  }

  Future<void> updateToken(String? token) async {
    _assertBiometric();
    if (token == null) {
      await (await _getStorageFile()).delete(promptInfo: _getPromptInfo());
    } else {
      await (await _getStorageFile())
          .write(token, promptInfo: _getPromptInfo());
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
