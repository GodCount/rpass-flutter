import 'package:auto_route/auto_route.dart';
import 'package:biometric_storage/biometric_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:keepass_core/keepass_core.dart';
import 'package:logging/logging.dart';

import '../../context/biometric.dart';
import '../../store/index.dart';
import '../../util/route.dart';
import 'authorized_page.dart';

final _logger = Logger("page:auth:modify");

class _ModifyPasswordArgs extends PageRouteArgs {
  _ModifyPasswordArgs({super.key});
}

class ModifyPasswordRoute extends PageRouteInfo<_ModifyPasswordArgs> {
  ModifyPasswordRoute({Key? key, bool dismissible = true})
    : super(
        name,
        args: _ModifyPasswordArgs(key: key),
        rawQueryParams: {"dismissible": dismissible.toString()},
      );

  static const name = "ModifyPasswordRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_ModifyPasswordArgs>(
        orElse: () => _ModifyPasswordArgs(),
      );
      final dismissible = data.queryParams.getBool("dismissible", true);
      return ModifyPasswordPage(key: args.key, dismissible: dismissible);
    },
  );
}

class ModifyPasswordPage extends AuthorizedPage {
  const ModifyPasswordPage({super.key, this.dismissible = true});

  final bool dismissible;

  @override
  AuthorizedPageState<ModifyPasswordPage> createState() =>
      _ModifyPasswordPageState();
}

class _ModifyPasswordPageState extends AuthorizedPageState<ModifyPasswordPage> {
  @override
  AuthorizedType get authType => AuthorizedType.modify_password;

  @override
  bool get enableBack => widget.dismissible;

  @override
  Future<void> confirm() async {
    if (form.currentState!.validate()) {
      final password = passwordController.text;
      final keyFile = keyFilecontroller.keyFile;

      if (!isPassword && keyFile == null) {
        throw Exception("Lack of key file.");
      }

      final kdbx = Store.kdbx.kdbx!;
      final biometric = Biometric.of(context);

      final credentials = Credentials.from(
        password: isPassword ? password : null,
        keyfile: keyFile?.$2,
      );

      try {
        await kdbx.modifyPassword(credentials: credentials);
        _logger.finest("update credentials done!");
      } catch (error, stackTrace) {
        _logger.severe("update credentials fail!", error, stackTrace);
        rethrow;
      }

      if (biometric.enable) {
        try {
          await biometric.updateCredentials(
            context,
            credentials.getCompositeKey(),
          );
          _logger.finest("update credentials to biometric done!");
        } catch (error, stackTrace) {
          if (error is AuthException &&
              (error.code == AuthExceptionCode.userCanceled ||
                  error.code == AuthExceptionCode.canceled ||
                  error.code == AuthExceptionCode.timeout)) {
            return;
          }
          await biometric.updateCredentials(context, null);
          _logger.warning(
            "update credentials to biometric fail!",
            error,
            stackTrace,
          );
        }
      }

      if (Store.settings.enableRecordKeyFilePath) {
        await Store.settings.setKeyFilePath(keyFile?.$1);
      }

      context.router.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(canPop: widget.dismissible, child: super.build(context));
  }
}
