import 'package:flutter/material.dart';

import './store/index.dart';
import './page/home.dart';

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
          onGenerateRoute: (RouteSettings routeSettings) {
            return MaterialPageRoute<void>(
              settings: routeSettings,
              builder: (BuildContext context) {
                switch (routeSettings.name) {
                  case Home.routeName:
                    return Home(store: store);
                  default:
                    return Home(store: store);
                }
              },
            );
          },
        );
      },
    );
  }
}
