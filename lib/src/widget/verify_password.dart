import 'dart:io';
import 'dart:typed_data';

import 'package:biometric_storage/biometric_storage.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../context/biometric.dart';
import '../context/store.dart';
import '../i18n.dart';
import '../kdbx/kdbx.dart';
import '../util/file.dart';
import 'extension_state.dart';
import 'shake_widget.dart';

final _logger = Logger("widget:verify_password");

enum VerifyType { password, biometric }

class OnVerifyPasswordParam {
  OnVerifyPasswordParam({
    required this.type,
    this.password,
    this.keyFile,
  });

  VerifyType type;
  String? password;
  Uint8List? keyFile;
}

typedef OnVerifyPassword = Future<void> Function(OnVerifyPasswordParam param);

class VerifyPassword extends StatefulWidget {
  const VerifyPassword({
    super.key,
    required this.onVerifyPassword,
    this.biometric = false,
    this.autoPopUpBiometric = false,
  });

  final OnVerifyPassword onVerifyPassword;
  final bool biometric;
  final bool autoPopUpBiometric;

  @override
  State<VerifyPassword> createState() => _VerifyPasswordState();
}

class _VerifyPasswordState extends State<VerifyPassword> {
  final OnVerifyPasswordParam param = OnVerifyPasswordParam(
    type: VerifyType.biometric,
  );

  final FocusNode _focusNode = FocusNode();
  final GlobalKey<ShakeWidgetState> _shakeKey = GlobalKey();

  bool _obscureText = true;
  bool _isPassword = true;
  bool _biometricDisable = false;
  String? _errorMessage;

  @override
  void initState() {
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _errorMessage != null) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
    if (widget.biometric && widget.autoPopUpBiometric) {
      _verifyBiometric();
    }
    super.initState();
  }

  Future<void> _verifyPassword() async {
    if ((_isPassword && param.password != null && param.password!.isNotEmpty) ||
        (!_isPassword && param.keyFile != null)) {
      try {
        _errorMessage = null;
        param.type = VerifyType.password;
        await widget.onVerifyPassword(param);
      } on KdbxInvalidKeyException {
        _errorMessage = I18n.of(context)!.password_error;
      } catch (e) {
        _logger.warning("verify password fail!", e);
        _errorMessage = e.toString();
      } finally {
        setState(() {});
        if (_errorMessage != null) {
          _shakeKey.currentState?.shakeWidget();
        }
      }
    }
  }

  Future<void> _verifyBiometric() async {
    try {
      final biometric = Biometric.of(context);
      if (biometric.enable) {
        param.type = VerifyType.biometric;
        await widget.onVerifyPassword(param);
      }
    } catch (e) {
      if (e is AuthException &&
          (e.code == AuthExceptionCode.userCanceled ||
              e.code == AuthExceptionCode.canceled ||
              e.code == AuthExceptionCode.timeout)) {
        return;
      }
      _logger.warning("verify biometric fail!", e);
      showError(e);
      setState(() {
        _biometricDisable = true;
      });
    }
  }

  void _onKdbxKeyFileResault((String, Uint8List)? value) {
    final store = StoreProvider.of(context);

    if (store.settings.enableRecordKeyFilePath) {
      store.settings.setKeyFilePath(value?.$1);
    }
    param.keyFile = value?.$2;
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    final biometric = Biometric.of(context);
    final store = StoreProvider.of(context);

    return Card(
      margin: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.app_name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                t.verify_password,
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 24),
              constraints: const BoxConstraints(maxWidth: 264),
              child: ShakeWidget(
                key: _shakeKey,
                child: TextField(
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.done,
                  obscureText: _obscureText,
                  obscuringCharacter: "*",
                  readOnly: !_isPassword,
                  onChanged: (value) {
                    param.password = value;
                  },
                  decoration: InputDecoration(
                    labelText: _isPassword ? t.password : t.none_password,
                    errorText: _errorMessage != null
                        ? t.throw_message(_errorMessage!)
                        : null,
                    border: const OutlineInputBorder(),
                    prefixIcon: Checkbox(
                      value: _isPassword,
                      onChanged: (value) {
                        setState(() {
                          _isPassword = value ?? true;
                        });
                      },
                    ),
                    suffixIcon: IconButton(
                      onPressed: _isPassword
                          ? () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            }
                          : null,
                      icon: Icon(
                        _obscureText
                            ? Icons.remove_red_eye_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  onSubmitted: (value) {
                    _verifyPassword();
                  },
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 12),
              constraints: const BoxConstraints(maxWidth: 264),
              child: KdbxKeyFileWidget(
                generateKeyFile: false,
                keyFilePath: store.settings.enableRecordKeyFilePath
                    ? store.settings.keyFilePath
                    : null,
                onKdbxKeyFileResault: _onKdbxKeyFileResault,
              ),
            ),
            Container(
              width: 180,
              padding: const EdgeInsets.only(top: 24),
              child: ElevatedButton(
                onPressed: _verifyPassword,
                child: Text(t.confirm),
              ),
            ),
            if (widget.biometric && biometric.enable)
              Container(
                width: 180,
                padding: const EdgeInsets.only(top: 12),
                child: ElevatedButton(
                  onPressed: !_biometricDisable ? _verifyBiometric : null,
                  child: Text(t.biometric),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

typedef OnKdbxKeyFileResault = void Function(
  (String keyFilePath, Uint8List keyFile)?,
);

class KdbxKeyFileWidget extends StatefulWidget {
  const KdbxKeyFileWidget({
    super.key,
    this.generateKeyFile = true,
    this.keyFilePath,
    required this.onKdbxKeyFileResault,
  });

  final bool generateKeyFile;
  final OnKdbxKeyFileResault onKdbxKeyFileResault;
  final String? keyFilePath;

  @override
  State<KdbxKeyFileWidget> createState() => KdbxKeyFileWidgetState();
}

class KdbxKeyFileWidgetState extends State<KdbxKeyFileWidget> {
  String? keyFilePath;

  @override
  void initState() {
    super.initState();
    if (widget.keyFilePath != null) {
      _readKeyFile(widget.keyFilePath!);
    }
  }

  void _readKeyFile(String keyFile) async {
    try {
      // TODO! 桌面端可能会出现权限问题
      final file = File(keyFile);
      if (await file.exists()) {
        keyFilePath = keyFile;
        widget.onKdbxKeyFileResault(
          (
            keyFile,
            await file.readAsBytes(),
          ),
        );
        setState(() {});
      }
    } catch (e) {
      _logger.warning("read key file fail!", e);
    }
  }

  IconData _getSuffixIcons() {
    if (keyFilePath != null) return Icons.close;
    if (widget.generateKeyFile) return Icons.create;
    return Icons.open_in_browser;
  }

  void _choiceKeyFile() async {
    try {
      final file = await SimpleFile.openFile(allowedExtensions: ["keyx"]);
      keyFilePath = file.$1;
      widget.onKdbxKeyFileResault((file.$1, file.$2));
      setState(() {});
    } catch (e) {
      print(e);
      if (e is! CancelException) {
        _logger.warning("open key file fail!", e);
        showError(e);
      }
    }
  }

  void _saveKeyFile() async {
    try {
      final keyFile = Kdbx.randomKeyFile();
      keyFilePath = await SimpleFile.saveFile(
        data: keyFile,
        filename: "rpass.keyx",
      );
      widget.onKdbxKeyFileResault((keyFilePath!, keyFile));
      setState(() {});
    } catch (e) {
      if (e is! CancelException) {
        _logger.warning("open key file fail!", e);
        showError(e);
      }
    }
  }

  void _suffix() {
    if (keyFilePath != null) {
      keyFilePath = null;
      widget.onKdbxKeyFileResault(null);
      setState(() {});
    } else if (widget.generateKeyFile) {
      _saveKeyFile();
    } else {
      _choiceKeyFile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    return GestureDetector(
      onTap: _choiceKeyFile,
      child: InputDecorator(
        isEmpty: keyFilePath == null,
        decoration: InputDecoration(
          labelText: t.key_file,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            onPressed: _suffix,
            icon: Icon(_getSuffixIcons()),
          ),
        ),
        child: Text(keyFilePath ?? ""),
      ),
    );
  }
}
