import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:rpass/src/i18n.dart';

import './store/index.dart';
import './page/page.dart';
import 'context/kdbx.dart';
import 'context/store.dart';
import 'theme/theme.dart';
import './util/common.dart';

final _logger = Logger("mobile:app");

class AuthGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    final kdbx = KdbxProvider.of(router.globalRouterKey.currentContext!);
    print(router.currentPath);
    print(kdbx);
    if (kdbx == null) {
      final store = StoreProvider.of(router.globalRouterKey.currentContext!);
      resolver.redirectUntil(
        NamedRoute(
          store.localInfo.localKdbxFileExists ? "LoadKdbxPage" : "InitialPage",
        ),
        replace: true,
      );
    } else {
      resolver.next();
    }
  }
}

RootStackRouter createAutoRoute() {
  return RootStackRouter.build(
    defaultRouteType: const RouteType.material(),
    guards: [AuthGuard()],
    routes: [
      NamedRouteDef(
        name: "InitialPage",
        path: "/initial",
        builder: (context, data) {
          return const InitialPage();
        },
      ),
      NamedRouteDef(
        name: "LoadKdbxPage",
        path: "/load_kdbx",
        builder: (context, data) {
          return const LoadKdbxPage();
        },
      ),
      NamedRouteDef(
        name: "Home",
        path: "/home",
        initial: true,
        builder: (context, data) {
          return const Home();
        },
        children: [
          NamedRouteDef(
            name: "PasswordsPage",
            path: "passwords",
            builder: (context, data) {
              return const PasswordsPage();
            },
          ),
          NamedRouteDef(
            name: "GroupsPage",
            path: "groups",
            builder: (context, data) {
              return const GroupsPage();
            },
          ),
          NamedRouteDef(
            name: "SettingsPage",
            path: "settings",
            builder: (context, data) {
              return const SettingsPage();
            },
          ),
        ],
      ),
      NamedRouteDef(
        name: "LoadExternalKdbxPage",
        path: "/load_external_kdbx",
        builder: (context, data) {
          return const LoadExternalKdbxPage();
        },
      ),
      NamedRouteDef(
        name: "ModifyPasswordPage",
        path: "/modify_password",
        builder: (context, data) {
          return const ModifyPasswordPage();
        },
      ),
      NamedRouteDef(
        name: "VerifyOwnerPage",
        path: "/verify_owner",
        builder: (context, data) {
          return const VerifyOwnerPage();
        },
      ),
      NamedRouteDef(
        name: "SelectIconPage",
        path: "/select_icon",
        builder: (context, data) {
          return const SelectIconPage();
        },
      ),
      NamedRouteDef(
        name: "RecycleBinPage",
        path: "/recycle_bin",
        builder: (context, data) {
          return const RecycleBinPage();
        },
      ),
      NamedRouteDef(
        name: "KdbxSettingPage",
        path: "/kdbx_setting",
        builder: (context, data) {
          return const KdbxSettingPage();
        },
      ),
      NamedRouteDef(
        name: "ManageGroupEntry",
        path: "/manage_group_entry",
        builder: (context, data) {
          return const ManageGroupEntry();
        },
      ),
      NamedRouteDef(
        name: "EditAccountPage",
        path: "/edit_account",
        builder: (context, data) {
          return const EditAccountPage();
        },
      ),
      NamedRouteDef(
        name: "GenPassword",
        path: "/gen_password",
        builder: (context, data) {
          return const GenPassword();
        },
      ),
      NamedRouteDef(
        name: "EditNotes",
        path: "/edit_notes",
        builder: (context, data) {
          return const EditNotes();
        },
      ),
      NamedRouteDef(
        name: "LookAccountPage",
        path: "/look_account",
        builder: (context, data) {
          return const LookAccountPage();
        },
      ),
      NamedRouteDef(
        name: "QrCodeScannerPage",
        path: "/scanner_code",
        builder: (context, data) {
          return const QrCodeScannerPage();
        },
      ),
      NamedRouteDef(
        name: "ChangeLocalePage",
        path: "/change_locale",
        builder: (context, data) {
          return const ChangeLocalePage();
        },
      ),
      NamedRouteDef(
        name: "ExportAccountPage",
        path: "/export_account",
        builder: (context, data) {
          return const ExportAccountPage();
        },
      ),
      NamedRouteDef(
        name: "ImportAccountPage",
        path: "/import_account",
        builder: (context, data) {
          return const ImportAccountPage();
        },
      ),
      NamedRouteDef(
        name: "MoreSecurityPage",
        path: "/more_security",
        builder: (context, data) {
          return const MoreSecurityPage();
        },
      ),
    ],
  );
}

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

// class RpassApp extends StatelessWidget {
//   const RpassApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final store = Store();
//     return StoreProvider(
//       store: store,
//       child: ListenableBuilder(
//         listenable: store.settings,
//         builder: (context, child) {
//           final kdbx = KdbxProvider.of(context);

//           final String initialRoute;

//           if (kdbx == null) {
//             initialRoute = store.localInfo.localKdbxFileExists
//                 ? LoadKdbxPage.routeName
//                 : InitialPage.routeName;
//           } else {
//             initialRoute = Home.routeName;
//           }

//           return MaterialApp(
//             restorationScopeId: 'app',
//             theme: theme(Brightness.light),
//             darkTheme: theme(Brightness.dark),
//             themeMode: store.settings.themeMode,
//             locale: store.settings.locale,
//             localizationsDelegates: I18n.localizationsDelegates,
//             supportedLocales: I18n.supportedLocales,
//             localeResolutionCallback: (locale, locales) {
//               if (locale != null &&
//                   store.settings.locale == null &&
//                   I18n.delegate.isSupported(locale)) {
//                 return locale;
//               }
//               return null;
//             },
//             initialRoute: initialRoute,
//             routes: {
//               Home.routeName: (context) => const Home(),
//               InitialPage.routeName: (context) => const InitialPage(),
//               LoadKdbxPage.routeName: (context) => const LoadKdbxPage(),
//               LoadExternalKdbxPage.routeName: (context) =>
//                   const LoadExternalKdbxPage(),
//               ModifyPasswordPage.routeName: (context) =>
//                   const ModifyPasswordPage(),
//               VerifyOwnerPage.routeName: (context) => const VerifyOwnerPage(),
//               SelectIconPage.routeName: (context) => const SelectIconPage(),
//               RecycleBinPage.routeName: (context) => const RecycleBinPage(),
//               KdbxSettingPage.routeName: (context) => const KdbxSettingPage(),
//               ManageGroupEntry.routeName: (context) => const ManageGroupEntry(),
//               EditAccountPage.routeName: (context) => const EditAccountPage(),
//               GenPassword.routeName: (context) => const GenPassword(),
//               EditNotes.routeName: (context) => const EditNotes(),
//               LookAccountPage.routeName: (context) => const LookAccountPage(),
//               QrCodeScannerPage.routeName: (context) =>
//                   const QrCodeScannerPage(),
//               ChangeLocalePage.routeName: (context) => const ChangeLocalePage(),
//               ExportAccountPage.routeName: (context) =>
//                   const ExportAccountPage(),
//               ImportAccountPage.routeName: (context) =>
//                   const ImportAccountPage(),
//               MoreSecurityPage.routeName: (context) => const MoreSecurityPage(),
//             },
//           );
//         },
//       ),
//     );
//   }
// }
