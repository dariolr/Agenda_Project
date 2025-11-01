import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_config.dart';

/// 🔹 Notifier moderno per gestire il tema dinamico
class ThemeNotifier extends Notifier<AppThemeConfig> {
  @override
  AppThemeConfig build() => const AppThemeConfig(
    seedColor: Colors.black,
    brightness: Brightness.light,
  );

  /// Cambia il colore principale (seed color)
  void updateSeed(Color color) {
    state = state.copyWith(seedColor: color);
  }

  /// Inverte la modalità chiara/scura
  void toggleBrightness() {
    if (state.brightness != Brightness.light) {
      state = state.copyWith(brightness: Brightness.light);
    }
  }
}

/// 🔹 Provider globale per il tema (versione Notifier)
final themeNotifierProvider = NotifierProvider<ThemeNotifier, AppThemeConfig>(
  ThemeNotifier.new,
);
