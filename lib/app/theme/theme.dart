import 'package:flutter/material.dart';

import 'theme_config.dart';

ThemeData buildTheme(AppThemeConfig config, Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: config.seedColor,
    brightness: brightness,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    brightness: brightness,

    // Sfondo principale
    scaffoldBackgroundColor: colorScheme.surface,

    // AppBar coerente con il tema
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      centerTitle: true,
      elevation: 0,
    ),

    // Pulsante flottante coerente
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
    ),

    // Stile card aggiornato per Material 3
    cardTheme: CardThemeData(
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      margin: const EdgeInsets.all(8),
    ),

    // Tipografia coerente
    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontSize: 14),
      titleMedium: TextStyle(fontWeight: FontWeight.w600),
    ),
  );
}
