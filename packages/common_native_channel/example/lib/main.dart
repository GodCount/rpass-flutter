import 'package:flutter/material.dart';

import 'features/prev_focus_window.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final Map<String, WidgetBuilder> routes = {
    "Prev Focus Window": (context) => const PrevFocusWindowPage(),
  };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: _HomePage(routes: routes.keys.toList()),
      onGenerateRoute: (settings) {
        if (routes.containsKey(settings.name)) {
          return MaterialPageRoute(
            builder: routes[settings.name]!,
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
      appBar: AppBar(title: const Text("通用插件测试测试")),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: routes
              .map(
                (item) => TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(item);
                  },
                  child: Text(item),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
