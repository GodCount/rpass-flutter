import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../i18n.dart';
import '../../remotes_fs/auth_field.dart';
import '../../remotes_fs/remote_fs.dart';
import '../../util/route.dart';
import '../../widget/extension_state.dart';

class _AuthRemoteFsArgs extends PageRouteArgs {
  _AuthRemoteFsArgs({super.key, required this.type, this.config});

  final RemoteType type;
  final Map<String, String?>? config;
}

class AuthRemoteFsRoute extends PageRouteInfo<_AuthRemoteFsArgs> {
  AuthRemoteFsRoute({
    Key? key,
    Map<String, String?>? config,
    required RemoteType type,
  }) : super(
         name,
         args: _AuthRemoteFsArgs(key: key, type: type, config: config),
         rawPathParams: {"type": type},
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
  const AuthRemoteFsPage({super.key, required this.type, this.config});

  final RemoteType type;
  final Map<String, String?>? config;

  @override
  State<AuthRemoteFsPage> createState() => _AuthRemoteFsState();
}

class _AuthRemoteFsState extends State<AuthRemoteFsPage> {
  final GlobalKey<FormState> _form = GlobalKey();

  late final Map<String, AuthField> _formData = widget.type.buildAuthFields(
    context,
    widget.config,
  );

  bool _loading = false;

  void _login() async {
    if (_form.currentState!.validate()) {
      _form.currentState!.save();
      try {
        setState(() {
          _loading = true;
        });

        final config = widget.type.buildRemoteFileConfig(_formData);

        await config.open();

        context.router.pop(config);
      } catch (e) {
        showError(e);
      } finally {
        setState(() {
          _loading = false;
        });
      }
    }
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
      throw UnsupportedError("type ${item.value.runtimeType} is unknown!");
    }).toList();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            constraints: const BoxConstraints(maxWidth: 312),
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 12,
                children: [
                  Text(switch (widget.type) {
                    .webdav => "WebDav",
                  }, style: Theme.of(context).textTheme.headlineSmall),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 12,
                        children: children,
                      ),
                    ),
                  ),
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
                      onPressed: !_loading ? () => context.router.pop() : null,
                      child: Text(t.back),
                    ),
                  ),
                ],
              ),
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
          trailing: Checkbox(value: widget.value, onChanged: widget.didChange),
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
              .map((item) => DropdownMenuEntry(label: item, value: item))
              .toList(),
        );
      },
    );
  }
}

class _NumericalRangeFormatter extends TextInputFormatter {
  _NumericalRangeFormatter({this.min, this.max});

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
