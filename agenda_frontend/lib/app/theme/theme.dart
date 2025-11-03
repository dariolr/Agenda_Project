import 'package:flutter/material.dart';

import 'theme_config.dart';

/// Crea un tema coerente partendo dal seed definito in [AppThemeConfig].
ThemeData buildTheme(AppThemeConfig _, Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  const colorPrimary1 = Colors.black; // colore base scuro
  const colorPrimary2 = Color(0xFFFEFEFE); // colore contrasto chiaro
  //const colorPrimary3 = Color(0xFFE5B24F); // accento caldo

  final background = isDark ? colorPrimary1 : colorPrimary2;
  final surface = background;
  final primary = colorPrimary1;
  final onPrimary = colorPrimary2;
  final onBackground = isDark ? colorPrimary2 : colorPrimary1;

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: primary,
    onPrimary: onPrimary,
    secondary: primary,
    onSecondary: onPrimary,
    error: Colors.red,
    onError: colorPrimary2,
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
      backgroundColor: colorPrimary2,
      foregroundColor: colorPrimary1,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: colorPrimary1),
      titleTextStyle: titleStyle.copyWith(color: colorPrimary1),
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
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: colorPrimary1,
      selectedIconTheme: const IconThemeData(color: colorPrimary2),
      unselectedIconTheme: const IconThemeData(color: colorPrimary2),
      selectedLabelTextStyle: const TextStyle(
        color: colorPrimary2,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: const TextStyle(color: colorPrimary2),
      minWidth: 68,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: colorPrimary1,
      selectedItemColor: colorPrimary2,
      unselectedItemColor: colorPrimary2,
      selectedIconTheme: const IconThemeData(color: colorPrimary2),
      unselectedIconTheme: const IconThemeData(color: colorPrimary2),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
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
