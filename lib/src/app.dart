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
            initialRoute:
                kdbx == null ? InitKdbxPage.routeName : Home.routeName,
            navigatorObservers: [UnfocusNavigatorRoute()],
            routes: {
              Home.routeName: (context) => const Home(),
              CreateKdbxPage.routeName: (context) => const CreateKdbxPage(),
              LoadKdbxPage.routeName: (context) => const LoadKdbxPage(),
              InitKdbxPage.routeName: (context) => const InitKdbxPage(),
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
              VerifyOwnerPage.routeName: (context) => const VerifyOwnerPage(),
            },
          );
        },
      ),
    );
  }
}
