import 'package:flutter/material.dart';
import 'package:rpass/src/i18n.dart';

import './store/index.dart';
import './page/page.dart';
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
    return ListenableBuilder(
      listenable: store.settings,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          restorationScopeId: 'app',
          theme: theme( Brightness.light),
          darkTheme: theme( Brightness.dark),
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
            InitPassword.routeName: (context) =>
                InitPassword(verifyContrller: store.verify),
            VerifyPassword.routeName: (context) =>
                VerifyPassword(verifyContrller: store.verify),
            ForgetPassword.routeName: (context) =>
                ForgetPassword(verifyContrller: store.verify),
            Home.routeName: (context) => Home(store: store),
            AboutPage.routeName: (context) => const AboutPage(),
            EditAccountPage.routeName: (context) =>
                EditAccountPage(accountsContrller: store.accounts),
            LookAccountPage.routeName: (context) => LookAccountPage(
                accountsContrller: store.accounts, accountId: ""),
            QrCodeScannerPage.routeName: (context) => const QrCodeScannerPage(),
            ExportAccountPage.routeName: (context) =>
                ExportAccountPage(store: store),
            ImportAccountPage.routeName: (context) =>
                ImportAccountPage(store: store),
            ChangeLocalePage.routeName: (context) =>
                ChangeLocalePage(settingsController: store.settings)
          },
        );
      },
    );
  }
}
