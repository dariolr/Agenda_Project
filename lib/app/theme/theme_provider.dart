import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_config.dart';

/// 🔹 Notifier moderno per gestire il tema dinamico
class ThemeNotifier extends Notifier<AppThemeConfig> {
  @override
  AppThemeConfig build() {
    // Stato iniziale del tema
    return const AppThemeConfig(
      seedColor: Color(0xFFFFD700), // Oro
      brightness: Brightness.dark,
    );
  }

  /// Cambia il colore principale (seed color)
  void updateSeed(Color color) {
    state = state.copyWith(seedColor: color);
  }

  /// Inverte la modalità chiara/scura
  void toggleBrightness() {
    state = state.copyWith(
      brightness: state.brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
    );
  }
}

/// 🔹 Provider globale per il tema (versione Notifier)
final themeNotifierProvider = NotifierProvider<ThemeNotifier, AppThemeConfig>(
  ThemeNotifier.new,
);
