import 'dart:io';
import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:biometric_storage/biometric_storage.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../context/biometric.dart';
import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../store/index.dart';
import '../../util/file.dart';
import '../../widget/shake_widget.dart';
import '../../widget/extension_state.dart';

final _logger = Logger("page:auth");

enum AuthorizedType {
  initial,
  load,
  modify_password,
  verify_owner,
}

abstract class AuthorizedPage extends StatefulWidget {
  const AuthorizedPage({super.key});
}

abstract class AuthorizedPageState<T extends AuthorizedPage> extends State<T> {
  @protected
  final GlobalKey<FormState> form = GlobalKey<FormState>();
  @protected
  final TextEditingController passwordController = TextEditingController();
  @protected
  final TextEditingController confirmController = TextEditingController();
  @protected
  final KeyFileController keyFilecontroller = KeyFileController();

  @protected
  AuthorizedType get authType =>
      throw UnimplementedError('authType has not been implemented.');

  @protected
  bool get enableBiometric => false;

  @protected
  bool get enableBack => false;

  @protected
  bool get enableImport => false;

  @protected
  bool get enableRemoteImport => false;

  @protected
  bool get readHistoryKeyFile => true;

  @protected
  bool isPassword = true;

  @protected
  bool disableClickBiometric = false;

  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _initKeyFile();
  }

  void _initKeyFile() async {
    keyFilecontroller.enableGenKeyFile = authType == AuthorizedType.initial ||
        authType == AuthorizedType.modify_password;

    if (readHistoryKeyFile) {
      final store = Store.instance;
      if (store.settings.enableRecordKeyFilePath &&
          store.settings.keyFilePath != null) {
        try {
          await keyFilecontroller.setKeyFile(store.settings.keyFilePath!);
        } catch (error) {
          _logger.warning("read history key file", error);
        }
      }
    }
  }

  @protected
  Future<void> confirm() {
    throw UnimplementedError('confirm() has not been implemented.');
  }

  @protected
  Future<void> importKdbx() {
    throw UnimplementedError('importKdbx() has not been implemented.');
  }

  @protected
  Future<void> importKdbxByWebDav() {
    throw UnimplementedError('importKdbxByWebDav() has not been implemented.');
  }

  @protected
  Future<void> verifyBiometric() {
    throw UnimplementedError('verifyBiometric() has not been implemented.');
  }

  @protected
  void back() {
    context.router.pop();
  }

  void _confirm() async {
    try {
      await confirm();
    } on KdbxInvalidKeyException {
      showError(I18n.of(context)!.password_error);
    } catch (error) {
      showError(error);
    }
  }

  void _importKdbx() async {
    try {
      await importKdbx();
    } catch (error) {
      if (error is! CancelException) {
        _logger.warning("import file fail!", error);
        showError(error);
      }
    }
  }

  void _importKdbxByWebDav() async {
    try {
      await importKdbxByWebDav();
    } catch (error) {
      _logger.warning("import remote file fail!", error);
      showError(error);
    }
  }

  @protected
  void startBiometric() async {
    try {
      await verifyBiometric();
    } catch (error) {
      if (error is AuthException &&
          (error.code == AuthExceptionCode.userCanceled ||
              error.code == AuthExceptionCode.canceled ||
              error.code == AuthExceptionCode.timeout)) {
        return;
      }

      _logger.warning("verify biometric fail!", error);
      showError(error);
      setState(() {
        disableClickBiometric = true;
      });
    }
  }

  void _moreImport() {
    final t = I18n.of(context)!;
    showBottomSheetList(
      title: t.more,
      children: [
        ListTile(
          leading: const Icon(Icons.storage),
          title: Text(t.local_import),
          enabled: enableImport,
          onTap: () async {
            context.pop();
            _importKdbx();
          },
        ),
        ListTile(
          leading: const Icon(Icons.cloud),
          title: Text(t.from_import("WebDAV")),
          enabled: enableRemoteImport,
          onTap: () async {
            context.pop();
            _importKdbxByWebDav();
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmController.dispose();
    keyFilecontroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;
    final biometric = Biometric.of(context);

    final String subtitle;
    switch (authType) {
      case AuthorizedType.initial:
        subtitle = t.init_main_password;
        break;
      case AuthorizedType.verify_owner:
      case AuthorizedType.load:
        subtitle = t.verify_password;
        break;
      case AuthorizedType.modify_password:
        subtitle = t.modify_password;
        break;
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
        child: Card(
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
                  child: Text(subtitle, textAlign: TextAlign.center),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Form(
                    key: form,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          constraints: const BoxConstraints(maxWidth: 264),
                          child: ShakeFormField<String>(
                            validator: (value) {
                              if (isPassword &&
                                  (value == null || value.length < 4)) {
                                return t.at_least_4digits;
                              }
                              return null;
                            },
                            builder: (context, validator) {
                              return TextFormField(
                                validator: validator,
                                controller: passwordController,
                                obscureText: _obscureText,
                                readOnly: !isPassword,
                                autofocus: true,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText:
                                      isPassword ? t.password : t.none_password,
                                  border: const OutlineInputBorder(),
                                  prefixIcon: Checkbox(
                                    value: isPassword,
                                    onChanged: (value) {
                                      setState(() {
                                        isPassword = value ?? true;
                                      });
                                    },
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _obscureText = !_obscureText;
                                      });
                                    },
                                    icon: Icon(
                                      _obscureText
                                          ? Icons.remove_red_eye_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (authType == AuthorizedType.initial ||
                            authType == AuthorizedType.modify_password)
                          Container(
                            padding: const EdgeInsets.only(top: 12),
                            constraints: const BoxConstraints(maxWidth: 264),
                            child: ShakeFormField<String>(
                              validator: (value) {
                                if (isPassword &&
                                    value != passwordController.text) {
                                  return t.password_not_equal;
                                }
                                return null;
                              },
                              builder: (context, validator) {
                                return TextFormField(
                                  validator: validator,
                                  textInputAction: TextInputAction.done,
                                  controller: confirmController,
                                  obscureText: _obscureText,
                                  readOnly: !isPassword,
                                  decoration: InputDecoration(
                                    labelText: isPassword
                                        ? t.confirm_password
                                        : t.none_password,
                                    border: const OutlineInputBorder(),
                                  ),
                                );
                              },
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.only(top: 12),
                          constraints: const BoxConstraints(maxWidth: 264),
                          child: ShakeFormField<(String, Uint8List)?>(
                            validator: (value) {
                              if (!isPassword && value == null) {
                                return t.lack_key_file;
                              }
                              return null;
                            },
                            builder: (context, validator) {
                              return KeyFileFormField(
                                validator: validator,
                                controller: keyFilecontroller,
                              );
                            },
                          ),
                        ),
                        Container(
                          width: 180,
                          padding: const EdgeInsets.only(top: 24),
                          child: ElevatedButton(
                            onPressed: _confirm,
                            child: Text(t.confirm),
                          ),
                        ),
                        if (authType == AuthorizedType.initial)
                          Container(
                            width: 180,
                            padding: const EdgeInsets.only(top: 24),
                            child: ElevatedButton(
                              onPressed: _moreImport,
                              child: Text(t.more),
                            ),
                          ),
                        if (enableBiometric && biometric.enable)
                          Container(
                            width: 180,
                            padding: const EdgeInsets.only(top: 24),
                            child: ElevatedButton(
                              onPressed: !disableClickBiometric
                                  ? startBiometric
                                  : null,
                              child: Text(t.biometric),
                            ),
                          ),
                        if (enableBack)
                          Container(
                            width: 180,
                            padding: const EdgeInsets.only(top: 24),
                            child: ElevatedButton(
                              onPressed: back,
                              child: Text(t.back),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class KeyFileController with ChangeNotifier {
  KeyFileController({
    bool? enableGenKeyFile,
  }) : _enableGenKeyFile = enableGenKeyFile ?? false;

  bool _enableGenKeyFile;

  (String, Uint8List)? _keyFile;

  bool get enableGenKeyFile => _enableGenKeyFile;

  set enableGenKeyFile(bool enable) {
    _enableGenKeyFile = enable;
    notifyListeners();
  }

  (String, Uint8List)? get keyFile => _keyFile;

  Future<void> setKeyFile(String keyFilePath, [Uint8List? data]) async {
    if (data != null) {
      _keyFile = (keyFilePath, data);
    } else {
      _keyFile = (keyFilePath, await File(keyFilePath).readAsBytes());
    }
    notifyListeners();
  }

  Future<void> genKeyFile() async {
    final keyFile = Kdbx.randomKeyFile();
    final keyFilePath = await SimpleFile.saveFile(
      data: keyFile,
      filename: "rpass.key",
    );
    _keyFile = (keyFilePath, keyFile);
    notifyListeners();
  }

  void clearKeyFile() {
    _keyFile = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _keyFile = null;
    super.dispose();
  }
}

class KeyFileFormField extends StatefulWidget {
  const KeyFileFormField({
    super.key,
    required this.controller,
    this.validator,
  });

  final KeyFileController controller;
  final FormFieldValidator<(String, Uint8List)>? validator;

  @override
  State<KeyFileFormField> createState() => _KeyFileFormFieldState();
}

class _KeyFileFormFieldState extends State<KeyFileFormField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    widget.controller.addListener(() {
      _controller.text = widget.controller.keyFile?.$1 ?? "";
      setState(() {});
    });
    super.initState();
  }

  IconData _getSuffixIcons() {
    if (_controller.text.isNotEmpty) return Icons.close;
    if (widget.controller.enableGenKeyFile) return Icons.create;
    return Icons.open_in_browser;
  }

  void _choiceKeyFile() async {
    try {
      final file = await SimpleFile.openFile();
      await widget.controller.setKeyFile(file.$1, file.$2);
    } catch (e) {
      if (e is! CancelException) {
        _logger.warning("open key file fail!", e);
        showError(e);
      }
    }
  }

  void _genKeyFile() async {
    try {
      await widget.controller.genKeyFile();
    } catch (e) {
      if (e is! CancelException) {
        _logger.warning("open key file fail!", e);
        showError(e);
      }
    }
  }

  void _suffix() {
    if (_controller.text.isNotEmpty) {
      widget.controller.clearKeyFile();
    } else if (widget.controller.enableGenKeyFile) {
      _genKeyFile();
    } else {
      _choiceKeyFile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    return TextFormField(
      onTap: _choiceKeyFile,
      controller: _controller,
      readOnly: true,
      validator: (_) => widget.validator != null
          ? widget.validator!(widget.controller.keyFile)
          : null,
      decoration: InputDecoration(
        labelText: t.key_file,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          onPressed: _suffix,
          icon: Icon(_getSuffixIcons()),
        ),
      ),
    );
  }
}
