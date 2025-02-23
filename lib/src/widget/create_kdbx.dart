import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../i18n.dart';
import '../kdbx/kdbx.dart';
import '../page/page.dart';
import '../util/file.dart';
import 'shake_widget.dart';
import './extension_state.dart';


final _logger = Logger("widget:create_kdbx");

typedef OnCreatedKdbx = void Function(Kdbx kdbx);

class CreateKdbx extends StatefulWidget {
  const CreateKdbx({
    super.key,
    required this.kdbxName,
    required this.onCreatedKdbx,
  });

  final OnCreatedKdbx onCreatedKdbx;
  final String kdbxName;

  @override
  State<CreateKdbx> createState() => CreateKdbxState();
}

class CreateKdbxState extends State<CreateKdbx> {
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _globalKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _createKdbx() {
    final kdbx = Kdbx.create(
      password: _passwordController.text,
      name: widget.kdbxName,
    );
    widget.onCreatedKdbx(kdbx);
  }

  void _importKdbx() async {
    try {
      // 安卓不支持指定 kdbx 后缀
      final file = await SimpleFile.openFile(
        allowedExtensions: !Platform.isAndroid ? ["kdbx"] : null,
      );

      if (!file.$1.endsWith(".kdbx")) {
        throw Exception("Invalid file extension");
      }

      final kdbx = await Navigator.pushNamed(
        context,
        LoadKdbxPage.routeName,
        arguments: LoadKdbxPageArguments(
          readKdbxFile: () async => file,
        ),
      );
      if (kdbx != null && kdbx is Kdbx) {
        widget.onCreatedKdbx(kdbx);
      }
    } catch (e) {
      if (e is! CancelException) {
        _logger.warning("open file fail!", e);
        showError(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

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
              child: Text(t.init_main_password, textAlign: TextAlign.center),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Form(
                key: _globalKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxWidth: 264),
                      child: ShakeFormField<String>(
                        validator: (value) => value == null || value.length < 4
                            ? t.at_least_4digits
                            : null,
                        builder: (context, validator) {
                          return TextFormField(
                            validator: validator,
                            controller: _passwordController,
                            autofocus: true,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: t.password,
                              border: const OutlineInputBorder(),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.only(top: 12),
                      constraints: const BoxConstraints(maxWidth: 264),
                      child: ShakeFormField<String>(
                        validator: (value) => value == null ||
                                value.isEmpty ||
                                value == _passwordController.text
                            ? null
                            : t.password_not_equal,
                        builder: (context, validator) {
                          return TextFormField(
                            validator: validator,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: t.confirm_password,
                              border: const OutlineInputBorder(),
                            ),
                            onFieldSubmitted: (value) {
                              if (_globalKey.currentState!.validate()) {
                                _createKdbx();
                              }
                            },
                          );
                        },
                      ),
                    ),
                    Container(
                      width: 180,
                      padding: const EdgeInsets.only(top: 24),
                      child: ElevatedButton(
                        onPressed: () {
                          if (_globalKey.currentState!.validate()) {
                            _createKdbx();
                          }
                        },
                        child: Text(t.init),
                      ),
                    ),
                    Container(
                      width: 180,
                      padding: const EdgeInsets.only(top: 24),
                      child: ElevatedButton(
                        onPressed: _importKdbx,
                        child: Text(t.import),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
