import 'package:flutter/material.dart';

const List<Color> availableColors = [
  Color(0xFF659BFF),
  Colors.red,
  Colors.green,
  Colors.yellow,
  Colors.blue,
  Colors.grey,
  Colors.blueGrey,
  Colors.lightBlue,
  Colors.cyan,
  Colors.teal,
  Colors.indigo,
  Colors.lightGreen,
  Colors.orange,
  Colors.deepOrange,
  Colors.purple,
  Colors.deepPurple,
  Colors.brown,
  Colors.amber,
  Colors.lime,
  Colors.pink,
];

ThemeData theme(Brightness brightness, [Color? seedColor]) {
  final scheme = ColorScheme.fromSeed(
    seedColor: seedColor ?? availableColors[0],
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      scrolledUnderElevation: 2.0,
      backgroundColor: scheme.primaryContainer,
      shadowColor: scheme.shadow,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainer,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      selectedTileColor: scheme.primaryContainer,
    ),
    cardTheme: CardThemeData(elevation: 2.0),
  );
}
