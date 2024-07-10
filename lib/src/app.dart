import 'package:flutter/material.dart';

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
          theme: RpassTheme.light,
          darkTheme: RpassTheme.dark,
          themeMode: store.settings.themeMode,
          initialRoute: !store.verify.initialled
              ? InitPassword.routeName
              : store.verify.token == null
                  ? VerifyPassword.routeName
                  : Home.routeName,
          navigatorObservers: [UnfocusNavigatorRoute()],
          routes: {
            "/": (context) =>
                const Center(child: Text("无人区, (根路由会在多数情况被多次 build )")),
            // "/test": (context) => const BarcodeScannerSimple(),
            InitPassword.routeName: (context) =>
                InitPassword(verifyContrller: store.verify),
            VerifyPassword.routeName: (context) =>
                VerifyPassword(verifyContrller: store.verify),
            ForgetPassword.routeName: (context) =>
                ForgetPassword(verifyContrller: store.verify),
            Home.routeName: (context) => Home(store: store),
            EditAccountPage.routeName: (context) =>
                EditAccountPage(accountsContrller: store.accounts),
            LookAccountPage.routeName: (context) => LookAccountPage(
                  accountsContrller: store.accounts,
                  accountId: "",
                ),
            QrCodeScannerPage.routeName: (context) => const QrCodeScannerPage(),
            ExportAccountPage.routeName: (context) =>
                ExportAccountPage(store: store),
            ImportAccountPage.routeName: (context) =>
                ImportAccountPage(store: store),
          },
        );
      },
    );
  }
}
