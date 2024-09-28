import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../i18n.dart';
import '../kdbx/kdbx.dart';

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
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxWidth: 264),
                      child: TextFormField(
                        controller: _passwordController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: InputDecoration(
                          labelText: t.password,
                          hintText: t.input_num_password,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.length < 4
                            ? t.at_least_4digits
                            : null,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.only(top: 12),
                      constraints: const BoxConstraints(maxWidth: 264),
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: InputDecoration(
                          labelText: t.confirm_password,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) => value == null ||
                                value.isEmpty ||
                                value == _passwordController.text
                            ? null
                            : t.password_not_equal,
                        onFieldSubmitted: (value) {
                          if (_globalKey.currentState!.validate()) {
                            _createKdbx();
                          }
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
