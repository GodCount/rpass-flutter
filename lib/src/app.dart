import 'package:flutter/material.dart';
import 'package:rpass/src/i18n.dart';

import './store/index.dart';
import './page/page.dart';
import 'context/kdbx.dart';
import 'context/store.dart';
import 'old/page/verify/verify.dart';
import 'old/store/index.dart';
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
  const RpassApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Store();
    final oldStore = OldStore();
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
            initialRoute: oldStore.accounts.isExistAccount
                ? VerifyPassword.routeName
                : kdbx == null
                    ? InitKdbxPage.routeName
                    : Home.routeName,
            navigatorObservers: [UnfocusNavigatorRoute()],
            routes: {
              Home.routeName: (context) => const Home(),
              CreateKdbxPage.routeName: (context) => const CreateKdbxPage(),
              LoadKdbxPage.routeName: (context) => const LoadKdbxPage(),
              InitKdbxPage.routeName: (context) => const InitKdbxPage(),
              SelectIconPage.routeName: (context) => const SelectIconPage(),
              RecycleBinPage.routeName: (context) => const RecycleBinPage(),
              KdbxSettingPage.routeName: (context) => const KdbxSettingPage(),

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

              // 旧版数据迁移,验证界面
              VerifyPassword.routeName: (context) => const VerifyPassword(),
            },
          );
        },
      ),
    );
  }
}
