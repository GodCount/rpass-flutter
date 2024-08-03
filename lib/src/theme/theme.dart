import 'package:flutter/material.dart';

const color = Color(0x11659AFF);

ThemeData theme(Brightness brightness) {
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(seedColor: color, brightness: brightness),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 2,
    ),
  );
}
