import 'package:flutter/material.dart';

import 'extensions.dart';
import 'theme_config.dart';

const colorPrimary1 = Color(0xFF141414); // colore base scuro
const colorPrimary2 = Color(0xFFFEFEFE); // colore contrasto chiaro
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

/// Crea un tema coerente partendo dal seed definito in [AppThemeConfig].
ThemeData buildTheme(AppThemeConfig _, Brightness brightness) {
  final isDark = brightness == Brightness.dark;

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
    fontFamily: _appFontFamily,
  );

  final titleStyle =
      base.textTheme.titleLarge ??
      const TextStyle(fontSize: 18, fontWeight: FontWeight.w600);

  final hoverFill = isDark
      ? colorPrimary2.withOpacity(0.12)
      : colorPrimary1.withOpacity(0.01);
  final pressedFill = isDark
      ? colorPrimary2.withOpacity(0.18)
      : colorPrimary1.withOpacity(0.1);
  final alternatingRowFill = isDark
      ? colorPrimary2.withOpacity(0.05)
      : colorPrimary1.withOpacity(0.03);

  final themeWithPalette = base.copyWith(
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
    textTheme: _withEmojiFallback(
      base.textTheme.apply(
        bodyColor: onBackground,
        displayColor: onBackground,
        fontFamily: _appFontFamily,
      ),
    ),
    iconTheme: IconThemeData(color: onBackground),
    dividerColor: onBackground.withOpacity(0.12),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: onPrimary,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: colorPrimary1,
      selectedIconTheme: const IconThemeData(color: colorPrimary2, size: 32),
      unselectedIconTheme: const IconThemeData(color: colorPrimary2, size: 32),
      selectedLabelTextStyle: const TextStyle(
        color: colorPrimary2,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: const TextStyle(color: colorPrimary2),
      minWidth: 80,
      indicatorColor: Colors.transparent,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: colorPrimary1,
      selectedItemColor: colorPrimary2,
      unselectedItemColor: colorPrimary2.withOpacity(0.5),
      selectedIconTheme: const IconThemeData(color: colorPrimary2, size: 26),
      unselectedIconTheme: IconThemeData(color: colorPrimary2.withOpacity(0.5)),
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 11,
      ),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
    // Colori ON globali per Switch/Radio in linea con il primary dell'app
    switchTheme: base.switchTheme.copyWith(
      overlayColor: MaterialStateProperty.all(Colors.transparent),
      thumbColor: MaterialStateProperty.resolveWith(
        (states) => states.contains(MaterialState.selected)
            ? colorScheme.primary
            : null,
      ),
      trackColor: MaterialStateProperty.resolveWith(
        (states) => states.contains(MaterialState.selected)
            ? colorScheme.primary.withOpacity(0.35)
            : null,
      ),
    ),
    radioTheme: base.radioTheme.copyWith(
      overlayColor: MaterialStateProperty.all(Colors.transparent),
      fillColor: MaterialStateProperty.resolveWith(
        (states) => states.contains(MaterialState.selected)
            ? colorScheme.primary
            : null,
      ),
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

  return themeWithPalette.copyWith(
    extensions: <ThemeExtension<dynamic>>[
      AppInteractionColors(
        hoverFill: hoverFill,
        pressedFill: pressedFill,
        alternatingRowFill: alternatingRowFill,
      ),
    ],
  );
}
