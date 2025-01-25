import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> mainNavigatorKey =
      GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> subNavigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: mainNavigatorKey,
      navigatorObservers: [MyNavigatorObserver(subNavigatorKey)],
      initialRoute: '/',
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) => HomeScreen());
          case '/second':
            return MaterialPageRoute(builder: (context) => SecondScreen());
          default:
            return MaterialPageRoute(builder: (context) => HomeScreen());
        }
      },
    );
  }
}

class MyNavigatorObserver extends NavigatorObserver {
  final GlobalKey<NavigatorState> subNavigatorKey;

  MyNavigatorObserver(this.subNavigatorKey);

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name == '/second') {
      // 转发导航到子 Navigator
      subNavigatorKey.currentState?.push(route);
    }
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Screen'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushNamed('/second');
          },
          child: Text('Go to Second Screen'),
        ),
      ),
    );
  }
}

class SecondScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Second Screen'),
      ),
      body: Center(
        child: Text('This is the Second Screen'),
      ),
    );
  }
}

class SubNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> subNavigatorKey;

  SubNavigator(this.subNavigatorKey);

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: subNavigatorKey,
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/third':
            return MaterialPageRoute(builder: (context) => ThirdScreen());
          default:
            return MaterialPageRoute(builder: (context) => ThirdScreen());
        }
      },
    );
  }
}

class ThirdScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Third Screen'),
      ),
      body: Center(
        child: Text('This is the Third Screen'),
      ),
    );
  }
}
