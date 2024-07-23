import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/rpass_localizations.dart';

import '../../store/settings/controller.dart';

class ChangeLocalePage extends StatefulWidget {
  const ChangeLocalePage({super.key, required this.settingsController});

  static const routeName = "/change_locale";

  final SettingsController settingsController;

  @override
  State<ChangeLocalePage> createState() => _ChangeLocalePageState();
}

class _ChangeLocalePageState extends State<ChangeLocalePage> {
  final Map<String, String> _locales = {};

  @override
  void initState() {
    for (var locale in RpassLocalizations.supportedLocales) {
      _locales[locale.toString()] =
          lookupRpassLocalizations(locale).locale_name;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("设置语言"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(6),
        children: [null, ...RpassLocalizations.supportedLocales].map((locale) {
          return ListTile(
            title: Text(locale != null ? _locales[locale.toString()]! : "系统"),
            trailing: widget.settingsController.locale == locale
                ? const Icon(Icons.check)
                : null,
            onTap: () {
              widget.settingsController.setLocale(locale);
            },
          );
        }).toList(),
      ),
    );
  }
}
