import 'package:biometric_storage/biometric_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../context/biometric.dart';
import '../i18n.dart';
import '../kdbx/kdbx.dart';
import 'extension_state.dart';

typedef OnLoadedKdbx = void Function(Kdbx kdbx);

typedef ReadKdbxFile = Future<(String, Uint8List)> Function();

class LoadKdbx extends StatefulWidget {
  const LoadKdbx({
    super.key,
    required this.readKdbxFile,
    this.biometric = false,
    required this.onLoadedKdbx,
  });

  final OnLoadedKdbx onLoadedKdbx;
  final ReadKdbxFile readKdbxFile;
  final bool biometric;

  @override
  State<LoadKdbx> createState() => _LoadKdbxState();
}

class _LoadKdbxState extends State<LoadKdbx> {
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _obscureText = true;
  bool _biometricDisable = false;
  String? _errorMessage;
  (String, Uint8List)? _kdbxFile;

  @override
  void initState() {
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _errorMessage != null) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
    if (widget.biometric) {
      _verifyBiometric();
    }
    super.initState();
  }

  Future<(String, Uint8List)> _readKdbxFile() async {
    if (_kdbxFile != null) return _kdbxFile!;
    _kdbxFile = await widget.readKdbxFile();
    return _kdbxFile!;
  }

  void _verifyPassword() async {
    if (_passwordController.text.isNotEmpty) {
      try {
        final (filepath, data) = await _readKdbxFile();

        final kdbx = await Kdbx.loadBytes(
          data: data,
          password: _passwordController.text,
          filepath: filepath,
        );
        widget.onLoadedKdbx(kdbx);
      } catch (error) {
        setState(() {
          _errorMessage = error.toString();
        });
      }
    }
  }

  void _verifyBiometric() async {
    try {
      final biometric = Biometric.of(context);
      if (biometric.enable) {
        final (filepath, data) = await _readKdbxFile();

        final hash = await biometric.getCredentials(context);
        final kdbx = await Kdbx.loadBytesFromHash(
          data: data,
          password: hash,
          filepath: filepath,
        );
        widget.onLoadedKdbx(kdbx);
      }
    } on AuthException catch (e) {
      if (e.code == AuthExceptionCode.userCanceled ||
          e.code == AuthExceptionCode.canceled ||
          e.code == AuthExceptionCode.timeout) {
        return;
      }
      rethrow;
    } catch (e) {
      showToast(I18n.of(context)!.biometric_throw(e.toString()));
      setState(() {
        _biometricDisable = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    final biometric = Biometric.of(context);
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
              child: TextField(
                focusNode: _focusNode,
                controller: _passwordController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofocus: true,
                obscureText: _obscureText,
                obscuringCharacter: "*",
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: t.password,
                  hintText: t.input_num_password,
                  errorText: _errorMessage != null
                      ? t.verify_password_throw(_errorMessage!)
                      : null,
                  border: const OutlineInputBorder(),
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
                onSubmitted: (value) {
                  _verifyPassword();
                },
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
