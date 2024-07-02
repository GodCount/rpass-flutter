import 'package:flutter/material.dart';

import './store/index.dart';
import './page/page.dart';

class AuthNavigatorRoute extends NavigatorObserver {
  AuthNavigatorRoute(this._store);

  final Store _store;

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);

    if (route.settings.name == Home.routeName) {
      if (!_store.verify.initialled) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          route.navigator?.pushReplacementNamed(InitPassword.routeName);
        });
      } else if (_store.verify.token == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          route.navigator?.pushReplacementNamed(VerifyPassword.routeName);
        });
      }
    }
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
          theme: ThemeData(),
          darkTheme: ThemeData.dark(),
          themeMode: store.settings.themeMode,
          initialRoute: "/",
          navigatorObservers: [AuthNavigatorRoute(store)],
          routes: {
            Home.routeName: (context) => Home(store: store),
            InitPassword.routeName: (context) =>
                InitPassword(verifyContrller: store.verify),
            VerifyPassword.routeName: (context) =>
                VerifyPassword(verifyContrller: store.verify)
          },
        );
      },
    );
  }
}
