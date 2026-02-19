import 'package:flutter/material.dart';

import 'theme_config.dart';

const colorPrimary = Color(0xFF141414);
const colorBackground = Color(0xFFFEFEFE);
const colorAccent = Color(0xFF2196F3);
const _appFontFamily = 'Roboto';
const List<String> _emojiFontFallback = [
  'Apple Color Emoji',
  'Segoe UI Emoji',
  'Segoe UI Symbol',
  'Noto Color Emoji',
  'Noto Emoji',
  'Emoji',
  'sans-serif',
];

TextTheme _withEmojiFallback(TextTheme textTheme) {
  TextStyle? apply(TextStyle? style) =>
      style?.copyWith(fontFamilyFallback: _emojiFontFallback);

  return textTheme.copyWith(
    displayLarge: apply(textTheme.displayLarge),
    displayMedium: apply(textTheme.displayMedium),
    displaySmall: apply(textTheme.displaySmall),
    headlineLarge: apply(textTheme.headlineLarge),
    headlineMedium: apply(textTheme.headlineMedium),
    headlineSmall: apply(textTheme.headlineSmall),
    titleLarge: apply(textTheme.titleLarge),
    titleMedium: apply(textTheme.titleMedium),
    titleSmall: apply(textTheme.titleSmall),
    bodyLarge: apply(textTheme.bodyLarge),
    bodyMedium: apply(textTheme.bodyMedium),
    bodySmall: apply(textTheme.bodySmall),
    labelLarge: apply(textTheme.labelLarge),
    labelMedium: apply(textTheme.labelMedium),
    labelSmall: apply(textTheme.labelSmall),
  );
}

/// Crea il tema dell'app
ThemeData buildTheme(AppThemeConfig config, Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  final background = isDark ? colorPrimary : colorBackground;
  final onBackground = isDark ? colorBackground : colorPrimary;

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: colorAccent,
    onPrimary: Colors.white,
    secondary: colorAccent,
    onSecondary: Colors.white,
    error: Colors.red,
    onError: Colors.white,
    surface: background,
    onSurface: onBackground,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    brightness: brightness,
    scaffoldBackgroundColor: background,
    fontFamily: _appFontFamily,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: onBackground,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: background,
      elevation: 0,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: onBackground.withOpacity(0.1)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorAccent,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorPrimary,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: colorPrimary.withOpacity(0.2)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorAccent,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: onBackground.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: onBackground.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: colorAccent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colorAccent.withOpacity(0.1),
      selectedColor: colorAccent,
      labelStyle: TextStyle(color: onBackground),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dividerColor: onBackground.withOpacity(0.1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: colorAccent,
    ),
  );

  return base.copyWith(
    textTheme: _withEmojiFallback(
      base.textTheme.apply(
        bodyColor: onBackground,
        displayColor: onBackground,
        fontFamily: _appFontFamily,
      ),
    ),
  );
}
