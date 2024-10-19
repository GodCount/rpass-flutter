import 'package:flutter/material.dart';

const color = Color(0x11659AFF);

ThemeData theme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: color, brightness: brightness);
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 4.0,
      scrolledUnderElevation: 4.0,
      backgroundColor: scheme.secondaryContainer,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainer,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.0))),
    ),
  );
}
