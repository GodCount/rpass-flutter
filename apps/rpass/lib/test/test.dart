import 'package:flutter/material.dart';
import 'package:rpass/src/theme/theme.dart';

import 'page/shake_test.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _WidgetTestApp());
}

class _WidgetTestApp extends StatelessWidget {
  const _WidgetTestApp();

  static final Map<String, WidgetBuilder> routes = {
    ShakeTestPage.routeName: (context) => const ShakeTestPage(),
  };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: _HomePage(routes: routes.keys.toList()),
      theme: theme(Brightness.light),
      onGenerateRoute: (settings) {
        if (routes.containsKey(settings.name)) {
          return MaterialPageRoute(
            builder: (context) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(settings.name!.substring(1)),
                ),
                body: routes[settings.name]!(context),
              );
            },
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({required this.routes});

  final List<String> routes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("小部件测试"),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: routes
              .map((item) => TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(item);
                    },
                    child: Text(
                      item.substring(1),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
