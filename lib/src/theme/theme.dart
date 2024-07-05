import 'package:flutter/material.dart';

final class RpassTheme {
  static final dark = ThemeData(
    brightness: Brightness.dark,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 2,
    ),
  );

  static final light = ThemeData(
    brightness: Brightness.light,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 2,
    ),
  );
}
