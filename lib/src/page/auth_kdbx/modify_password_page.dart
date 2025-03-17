import 'package:biometric_storage/biometric_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

import '../../context/biometric.dart';
import '../../context/kdbx.dart';
import '../../context/store.dart';
import '../../kdbx/kdbx.dart';
import 'authorized_page.dart';

final _logger = Logger("page:auth:modify");

class ModifyPasswordPage extends AuthorizedPage {
  const ModifyPasswordPage({super.key});

  static const routeName = "/modify_password";

  @override
  ModifyPasswordPageState createState() => ModifyPasswordPageState();
}

class ModifyPasswordPageState extends AuthorizedPageState {
  @override
  AuthorizedType get authType => AuthorizedType.modify_password;

  @override
  bool get enableBack => true;

  @override
  Future<void> confirm() async {
    if (form.currentState!.validate()) {
      final passowrd = passwordController.text;
      final keyFile = keyFilecontroller.keyFile;

      if (!isPassword && keyFile == null) {
        throw Exception("Lack of key file.");
      }

      final store = StoreProvider.of(context);
      final kdbx = KdbxProvider.of(context)!;
      final biometric = Biometric.of(context);

      final oldCredentials = kdbx.credentials;
      final credentials =
          Kdbx.createCredentials(isPassword ? passowrd : null, keyFile?.$2);

      if (biometric.enable) {
        try {
          await biometric.updateCredentials(
            context,
            credentials.getHash(),
          );
          _logger.finest("update credentials to biometric done!");
        } catch (error, stackTrace) {
          if (error is AuthException &&
              (error.code == AuthExceptionCode.userCanceled ||
                  error.code == AuthExceptionCode.canceled ||
                  error.code == AuthExceptionCode.timeout)) {
            return;
          }
          _logger.severe(
            "update credentials to biometric fail!",
            error,
            stackTrace,
          );
          rethrow;
        }
      }

      try {
        kdbx
          ..modifyCredentials(credentials)
          ..save();
        _logger.finest("update credentials done!");
      } catch (error, stackTrace) {
        kdbx.modifyCredentials(oldCredentials);
        await biometric.updateCredentials(
          context,
          oldCredentials.getHash(),
        );
        _logger.severe(
          "update credentials fail!",
          error,
          stackTrace,
        );
        rethrow;
      }

      if (store.settings.enableRecordKeyFilePath) {
        await store.settings.setKeyFilePath(keyFile?.$1);
      }

      Navigator.of(context).pop();
    }
  }
}
