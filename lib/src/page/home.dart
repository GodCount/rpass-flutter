import 'package:flutter/material.dart';
import '../store/index.dart';

class Home extends StatefulWidget {
  const Home({super.key, required this.store});

  static const routeName = "/";

  final Store store;

  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: DropdownButton<ThemeMode>(
          // Read the selected themeMode from the controller
          value: widget.store.settings.themeMode,
          // Call the updateThemeMode method any time the user selects a theme.
          onChanged: widget.store.settings.setThemeMode,
          items: const [
            DropdownMenuItem(
              value: ThemeMode.system,
              child: Text('System Theme'),
            ),
            DropdownMenuItem(
              value: ThemeMode.light,
              child: Text('Light Theme'),
            ),
            DropdownMenuItem(
              value: ThemeMode.dark,
              child: Text('Dark Theme'),
            )
          ],
        ),
      ),
    );
  }
}
