import 'package:flutter/material.dart';

import 'theme_config.dart';

/// Crea un tema coerente partendo dal seed definito in [AppThemeConfig].
ThemeData buildTheme(AppThemeConfig _, Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  final background = isDark ? Colors.black : Colors.white;
  final surface = background;
  final primary = isDark ? Colors.white : Colors.black;
  final onPrimary = isDark ? Colors.black : Colors.white;
  final onBackground = isDark ? Colors.white : Colors.black;

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: primary,
    onPrimary: onPrimary,
    secondary: primary,
    onSecondary: onPrimary,
    error: Colors.red,
    onError: Colors.white,
    background: background,
    onBackground: onBackground,
    surface: surface,
    onSurface: onBackground,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    brightness: brightness,
    scaffoldBackgroundColor: background,
    canvasColor: surface,
  );

  final titleStyle =
      base.textTheme.titleLarge ??
      const TextStyle(fontSize: 18, fontWeight: FontWeight.w600);

  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: onBackground,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: onBackground),
      titleTextStyle: titleStyle.copyWith(color: onBackground),
    ),
    cardTheme: CardThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: onBackground.withOpacity(0.1), width: 0.5),
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: onBackground,
      displayColor: onBackground,
    ),
    iconTheme: IconThemeData(color: onBackground),
    dividerColor: onBackground.withOpacity(0.12),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: onPrimary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}
