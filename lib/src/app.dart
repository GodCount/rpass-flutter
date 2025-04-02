import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:rpass/src/i18n.dart';

import './store/index.dart';
import 'context/store.dart';
import 'route.dart';
import 'theme/theme.dart';

final _logger = Logger("mobile:app");

final RootStackRouter router = createAutoRoute();

class RpassApp extends StatelessWidget {
  const RpassApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Store();
    return StoreProvider(
      store: store,
      child: ListenableBuilder(
        listenable: store.settings,
        builder: (context, child) {
          return MaterialApp.router(
            restorationScopeId: 'app',
            theme: theme(Brightness.light),
            darkTheme: theme(Brightness.dark),
            themeMode: store.settings.themeMode,
            locale: store.settings.locale,
            localizationsDelegates: I18n.localizationsDelegates,
            supportedLocales: I18n.supportedLocales,
            localeResolutionCallback: (locale, locales) {
              if (locale != null &&
                  store.settings.locale == null &&
                  I18n.delegate.isSupported(locale)) {
                return locale;
              }
              return null;
            },
            routerConfig: router.config(),
          );
        },
      ),
    );
  }
}
