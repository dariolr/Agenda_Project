import 'package:flutter/material.dart';

import 'theme_config.dart';

/// 🔹 Tema chiaro con sfondo bianco e testi neri
ThemeData buildTheme(AppThemeConfig config, Brightness brightness) {
  // Palette chiara, fissa (non dipende dal seed)
  const colorScheme = ColorScheme.light(
    primary: Colors.black,
    onPrimary: Colors.white,
    secondary: Colors.grey,
    onSecondary: Colors.white,
    background: Colors.white,
    onBackground: Colors.black,
    surface: Colors.white,
    onSurface: Colors.black,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colorScheme,

    // ✅ Sfondo bianco
    scaffoldBackgroundColor: Colors.white,
    canvasColor: Colors.white,

    // ✅ AppBar bianca, testo nero
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),

    // ✅ Card bianche con bordo grigio leggero (usa CardThemeData!)
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300, width: 0.5),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
    ),

    // ✅ Testi neri
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.black, fontSize: 14),
      bodySmall: TextStyle(color: Colors.black87, fontSize: 12),
      titleMedium: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      labelLarge: TextStyle(color: Colors.black),
    ),

    // ✅ Icone e divider coerenti
    iconTheme: const IconThemeData(color: Colors.black),
    dividerColor: Colors.grey,

    // ✅ Pulsanti coerenti
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // BorderRadiusGeometry ok
        ),
      ),
    ),
  );
}
