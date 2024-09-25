import 'package:flutter/material.dart';
import 'package:rpass/src/i18n.dart';

import './store/index.dart';
import './page/page.dart';
import 'context/store.dart';
import 'theme/theme.dart';

class UnfocusNavigatorRoute extends NavigatorObserver {
  UnfocusNavigatorRoute();

  @override
  void didPush(route, previousRoute) {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void didPop(route, previousRoute) {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void didRemove(route, previousRoute) {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void didReplace({newRoute, oldRoute}) {
    FocusManager.instance.primaryFocus?.unfocus();
  }
}

class RpassApp extends StatelessWidget {
  const RpassApp({
    super.key,
    required this.store,
  });

  final Store store;

  @override
  Widget build(BuildContext context) {
    return StoreProvider(
      store: store,
      child: MaterialApp(
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
        initialRoute: !store.verify.initialled
            ? InitPassword.routeName
            : store.verify.token == null
                ? VerifyPassword.routeName
                : Home.routeName,
        navigatorObservers: [UnfocusNavigatorRoute()],
        routes: {
          InitPassword.routeName: (context) => const InitPassword(),
          VerifyPassword.routeName: (context) => const VerifyPassword(),
          ForgetPassword.routeName: (context) => const ForgetPassword(),
          Home.routeName: (context) => const Home(),
          AboutPage.routeName: (context) => const AboutPage(),
          EditAccountPage.routeName: (context) => const EditAccountPage(),
          LookAccountPage.routeName: (context) =>
              const LookAccountPage(accountId: ""),
          QrCodeScannerPage.routeName: (context) => const QrCodeScannerPage(),
          ExportAccountPage.routeName: (context) => const ExportAccountPage(),
          ImportAccountPage.routeName: (context) => const ImportAccountPage(),
          ChangeLocalePage.routeName: (context) => const ChangeLocalePage()
        },
      ),
    );
  }
}
