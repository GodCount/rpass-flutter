import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../context/kdbx.dart';
import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../remotes_fs/auth_field.dart';
import '../../remotes_fs/remote_fs.dart';
import '../../util/route.dart';
import '../../widget/common.dart';
import '../../widget/extension_state.dart';

enum AuthRemoteRouteType {
  sync,
  import,
}

class _AuthRemoteFsArgs extends PageRouteArgs {
  _AuthRemoteFsArgs({
    super.key,
    this.type = AuthRemoteRouteType.sync,
    required this.config,
  });

  final AuthRemoteRouteType type;
  final RemoteClientConfig config;
}

class AuthRemoteFsRoute extends PageRouteInfo<_AuthRemoteFsArgs> {
  AuthRemoteFsRoute({
    Key? key,
    AuthRemoteRouteType type = AuthRemoteRouteType.sync,
    required RemoteClientConfig config,
  }) : super(
          name,
          args: _AuthRemoteFsArgs(
            key: key,
            type: type,
            config: config,
          ),
          rawPathParams: {
            "type": type,
          },
        );

  static const name = "AuthRemoteFsRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_AuthRemoteFsArgs>();
      return AuthRemoteFsPage(
        key: args.key,
        type: args.type,
        config: args.config,
      );
    },
  );
}

class AuthRemoteFsPage extends StatefulWidget {
  const AuthRemoteFsPage({
    super.key,
    this.type = AuthRemoteRouteType.sync,
    required this.config,
  });

  final AuthRemoteRouteType type;
  final RemoteClientConfig config;

  @override
  State<AuthRemoteFsPage> createState() => _AuthRemoteFsState();
}

class _AuthRemoteFsState extends State<AuthRemoteFsPage> {
  GlobalKey<FormState> _form = GlobalKey();

  late final RemoteClientConfig _config = widget.config;

  late Map<String, AuthField> _formData;

  bool _loading = false;

  KdbxEntry? _syncAccountEntry;

  @override
  void initState() {
    _formData = _config.toAuthFields();

    final kdbx = KdbxProvider.of(context);

    if (widget.type == AuthRemoteRouteType.sync && kdbx != null) {
      _syncAccountEntry = kdbx.syncAccountEntry;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (_syncAccountEntry == null &&
            await showConfirmDialog(title: "选择账号", message: "从数据库中选择账号")) {
          _syncAccountEntry = await KdbxEntrySelectorDialog.openDialog(
            context,
            value: _syncAccountEntry,
          );
          if (_syncAccountEntry != null) {
            // 必须 强制重新渲染
            _form = GlobalKey();
            _config.updateByKdbx(_syncAccountEntry!);
            _formData = _config.toAuthFields();
            setState(() {});
          }
        }
      });
    }

    super.initState();
  }

  Future<void> _saveLoginInfo(RemoteClientConfig config) async {
    final kdbx = KdbxProvider.of(context);
    if (kdbx == null) return;

    if (_syncAccountEntry == null) {
      final t = I18n.of(context)!;

      if (await showConfirmDialog(
        title: t.save,
        message: t.save_sync_account_subtitle,
      )) {
        _syncAccountEntry = kdbx.createEntry(kdbx.kdbxFile.body.rootGroup)
          ..setString(KdbxKeyCommon.TITLE, PlainValue("WebDAV"));
      } else {
        return;
      }
    }

    for (final item in config.toKdbx().entries) {
      _syncAccountEntry!.setString(item.key, item.value);
    }

    kdbx.syncAccountEntry = _syncAccountEntry;
    await kdbxSave(kdbx);
  }

  void _login() async {
    if (_form.currentState!.validate()) {
      _form.currentState!.save();
      try {
        setState(() {
          _loading = true;
        });

        _config.updateAuthField(_formData);
        final client = await _config.buildClient();

        if (widget.type == AuthRemoteRouteType.sync) {
          await _saveLoginInfo(client.config);
        }

        context.router.pop(client);
      } catch (e) {
        showError(e);
      } finally {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _bindingKdbxEntry() async {
    final result = await KdbxEntrySelectorDialog.openDialog(
      context,
      value: _syncAccountEntry,
      title: I18n.of(context)!.save_as,
    );

    if (result == _syncAccountEntry) return;

    if (result != null && result != _syncAccountEntry) {
      // 必须 强制重新渲染
      _form = GlobalKey();
      _config.updateByKdbx(result);
      _formData = _config.toAuthFields();
    }

    _syncAccountEntry = result;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    final children = _formData.entries.map((item) {
      if (item.value is BoolAuthField) {
        return _boolField(item.value as BoolAuthField);
      } else if (item.value is NumberAuthField) {
        return _numberField(item.value as NumberAuthField);
      } else if (item.value is PasswordAuthField) {
        return _passwordField(item.value as PasswordAuthField);
      } else if (item.value is OptionAuthField) {
        return _optionField(item.value as OptionAuthField);
      } else if (item.value is TextAuthField) {
        return _textField(item.value as TextAuthField);
      }
      throw UnsupportedError(
        "type ${item.value.runtimeType} is unknown!",
      );
    }).toList();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24).copyWith(top: 6, right: 6),
            constraints: const BoxConstraints(maxWidth: 312),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.type == AuthRemoteRouteType.sync)
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      color: _syncAccountEntry != null
                          ? Theme.of(context).colorScheme.primary
                          : null,
                      onPressed: _bindingKdbxEntry,
                      icon: const Icon(Icons.link),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(right: 18),
                  child: Form(
                    key: _form,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 12,
                      children: [
                        Text(
                          "WebDAV",
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          widget.type == AuthRemoteRouteType.sync
                              ? t.logined_sync
                              : t.from_import("WebDAV"),
                          textAlign: TextAlign.center,
                        ),
                        ...children,
                        Container(
                          width: 180,
                          padding: const EdgeInsets.only(top: 8),
                          child: ElevatedButton(
                            onPressed: !_loading ? _login : null,
                            child: Text(t.confirm),
                          ),
                        ),
                        Container(
                          width: 180,
                          padding: const EdgeInsets.only(top: 8),
                          child: ElevatedButton(
                            onPressed:
                                !_loading ? () => context.router.pop() : null,
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

  Widget _textField(TextAuthField field) {
    return TextFormField(
      initialValue: field.value,
      onSaved: (value) => field.value = value ?? field.value,
      decoration: InputDecoration(
        labelText: field.description,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _boolField(BoolAuthField field) {
    return FormField<bool>(
      initialValue: field.value,
      onSaved: (value) => field.value = value ?? field.value,
      builder: (widget) {
        return ListTile(
          title: Text(field.description),
          trailing: Checkbox(
            value: widget.value,
            onChanged: widget.didChange,
          ),
        );
      },
    );
  }

  Widget _numberField(NumberAuthField field) {
    return TextFormField(
      initialValue: field.value.toString(),
      onSaved: (value) =>
          field.value = value != null ? int.parse(value) : field.value,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _NumericalRangeFormatter(min: field.min, max: field.max),
      ],
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: field.description,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _passwordField(PasswordAuthField field) {
    return FormField<(String, bool)>(
      initialValue: (field.value, true),
      onSaved: (value) => field.value = value?.$1 ?? field.value,
      builder: (widget) {
        final obscureText = widget.value?.$2 ?? true;
        return TextFormField(
          initialValue: field.value,
          obscureText: obscureText,
          onChanged: (value) => widget.didChange((value, obscureText)),
          decoration: InputDecoration(
            labelText: field.description,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: () {
                widget.didChange((widget.value?.$1 ?? "", !obscureText));
              },
              icon: Icon(
                obscureText
                    ? Icons.remove_red_eye_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _optionField(OptionAuthField field) {
    return FormField<String>(
      initialValue: field.value,
      onSaved: (value) => field.value = value ?? field.value,
      builder: (widget) {
        return DropdownMenu(
          initialSelection: field.value,
          onSelected: (value) => widget.didChange(value),
          enableSearch: false,
          requestFocusOnTap: false,
          expandedInsets: const EdgeInsets.all(0),
          label: Text(field.description),
          dropdownMenuEntries: field.optionList
              .map(
                (item) => DropdownMenuEntry(
                  label: item,
                  value: item,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _NumericalRangeFormatter extends TextInputFormatter {
  _NumericalRangeFormatter({
    this.min,
    this.max,
  });

  final int? min;
  final int? max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return oldValue;
    final value = int.parse(newValue.text);
    if (max != null && value > max! || min != null && value < min!) {
      return oldValue;
    }

    return newValue;
  }
}
