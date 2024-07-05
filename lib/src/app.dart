import 'package:flutter/material.dart';

import './store/index.dart';
import './page/page.dart';
import './page/test.dart';
import 'theme/theme.dart';

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
          theme: RpassTheme.light,
          darkTheme: RpassTheme.dark,
          themeMode: store.settings.themeMode,
          initialRoute: !store.verify.initialled
              ? InitPassword.routeName
              : store.verify.token == null
                  ? VerifyPassword.routeName
                  : Home.routeName,
          // navigatorObservers: [AuthNavigatorRoute(store)],
          routes: {
            "/": (context) =>
                const Center(child: Text("无人区, (根路由会在多数情况被多次 build )")),
            "/test": (context) => const OpenContainerTransformDemo(),
            Home.routeName: (context) => Home(store: store),
            InitPassword.routeName: (context) =>
                InitPassword(verifyContrller: store.verify),
            VerifyPassword.routeName: (context) =>
                VerifyPassword(verifyContrller: store.verify),
            ForgetPassword.routeName: (context) =>
                ForgetPassword(verifyContrller: store.verify)
          },
        );
      },
    );
  }
}
