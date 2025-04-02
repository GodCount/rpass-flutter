import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../context/store.dart';
import '../../i18n.dart';
import '../../util/route.dart';

class _ChangeLocaleArgs extends PageRouteArgs {
  _ChangeLocaleArgs({super.key});
}

class ChangeLocaleRoute extends PageRouteInfo<_ChangeLocaleArgs> {
  ChangeLocaleRoute({
    Key? key,
  }) : super(
          name,
          args: _ChangeLocaleArgs(key: key),
        );

  static const name = "ChangeLocaleRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_ChangeLocaleArgs>();
      return ChangeLocalePage(key: args.key);
    },
  );
}

class ChangeLocalePage extends StatefulWidget {
  const ChangeLocalePage({super.key});

  @override
  State<ChangeLocalePage> createState() => _ChangeLocalePageState();
}

class _ChangeLocalePageState extends State<ChangeLocalePage> {
  final Map<String, String> _locales = {};

  @override
  void initState() {
    for (var locale in I18n.supportedLocales) {
      _locales[locale.toString()] =
          I18n.lookupLocalizations(locale).locale_name;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;
    final store = StoreProvider.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.language_setting),
      ),
      body: ListView(
        children: [null, ...I18n.supportedLocales].map((locale) {
          return ListTile(
            title: Text(
              locale != null ? _locales[locale.toString()]! : t.system,
            ),
            trailing: store.settings.locale == locale
                ? const Icon(Icons.check)
                : null,
            onTap: () {
              store.settings.setLocale(locale);
            },
          );
        }).toList(),
      ),
    );
  }
}
