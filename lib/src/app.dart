import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:rpass/src/i18n.dart';

import './store/index.dart';
import './page/page.dart';
import 'context/kdbx.dart';
import 'context/store.dart';
import 'theme/theme.dart';

final _logger = Logger("mobile:app");

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
  const RpassApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Store();
    return StoreProvider(
      store: store,
      child: ListenableBuilder(
        listenable: store.settings,
        builder: (context, child) {
          final kdbx = KdbxProvider.of(context);

          final String initialRoute;

          if (kdbx == null) {
            initialRoute = store.localInfo.localKdbxFileExists
                ? LoadKdbxPage.routeName
                : InitialPage.routeName;
          } else {
            initialRoute = Home.routeName;
          }

          return MaterialApp(
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
            initialRoute: initialRoute,
            navigatorObservers: [UnfocusNavigatorRoute()],
            routes: {
              Home.routeName: (context) => const Home(),
              InitialPage.routeName: (context) => const InitialPage(),
              LoadKdbxPage.routeName: (context) => const LoadKdbxPage(),
              LoadExternalKdbxPage.routeName: (context) =>
                  const LoadExternalKdbxPage(),
              ModifyPasswordPage.routeName: (context) =>
                  const ModifyPasswordPage(),
              VerifyOwnerPage.routeName: (context) => const VerifyOwnerPage(),
              SelectIconPage.routeName: (context) => const SelectIconPage(),
              RecycleBinPage.routeName: (context) => const RecycleBinPage(),
              KdbxSettingPage.routeName: (context) => const KdbxSettingPage(),
              ManageGroupEntry.routeName: (context) => const ManageGroupEntry(),
              EditAccountPage.routeName: (context) => const EditAccountPage(),
              GenPassword.routeName: (context) => const GenPassword(),
              EditNotes.routeName: (context) => const EditNotes(),
              LookAccountPage.routeName: (context) => const LookAccountPage(),
              QrCodeScannerPage.routeName: (context) =>
                  const QrCodeScannerPage(),
              ChangeLocalePage.routeName: (context) => const ChangeLocalePage(),
              ExportAccountPage.routeName: (context) =>
                  const ExportAccountPage(),
              ImportAccountPage.routeName: (context) =>
                  const ImportAccountPage(),
              MoreSecurityPage.routeName: (context) => const MoreSecurityPage(),
            },
          );
        },
      ),
    );
  }
}
