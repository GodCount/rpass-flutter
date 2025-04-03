import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../remotes_fs/auth_field.dart';
import '../../remotes_fs/factory.dart';

class AuthRemoteFs extends StatefulWidget {
  const AuthRemoteFs({super.key, required this.type});

  final RemoteFsCase type;

  @override
  State<AuthRemoteFs> createState() => AuthRemoteFsState();
}

class AuthRemoteFsState extends State<AuthRemoteFs> {
  final GlobalKey<FormState> _form = GlobalKey();

  late final Map<String, AuthField> _formData;

  @override
  void initState() {
    _formData = getRemoteFsAuthField(widget.type);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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

    children.add(
      TextButton(
        onPressed: () async {
          if (_form.currentState!.validate()) {
            _form.currentState!.save();
            try {
              final client = await createRemoteFs(
                type: widget.type,
                formData: _formData,
              );
              Navigator.of(context).pop(client);
            } catch (e) {
              print(e);
            }
          }
        },
        child: Text("验证"),
      ),
    );

    return Scaffold(
      body: Form(
        key: _form,
        child: ListView.separated(
          padding: const EdgeInsets.all(24),
          separatorBuilder: (context, index) {
            return const SizedBox(
              height: 12,
            );
          },
          itemBuilder: (context, index) {
            return children[index];
          },
          itemCount: children.length,
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
        NumericalRangeFormatter(min: field.min, max: field.max),
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

class NumericalRangeFormatter extends TextInputFormatter {
  NumericalRangeFormatter({
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
    if (max != null && value > max! || min != null && value < min!)
      return oldValue;

    return newValue;
  }
}
