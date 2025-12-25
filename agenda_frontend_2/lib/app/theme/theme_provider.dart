import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme.dart';
import 'theme_config.dart';

/// Notifier per gestire il tema dinamico
class ThemeNotifier extends Notifier<AppThemeConfig> {
  @override
  AppThemeConfig build() => const AppThemeConfig(
        seedColor: colorPrimary,
        brightness: Brightness.light,
      );

  void updateSeed(Color color) {
    state = state.copyWith(seedColor: color);
  }

  void toggleBrightness() {
    final newBrightness = state.brightness == Brightness.light
        ? Brightness.dark
        : Brightness.light;
    state = state.copyWith(brightness: newBrightness);
  }
}

/// Provider globale per il tema
final themeNotifierProvider = NotifierProvider<ThemeNotifier, AppThemeConfig>(
  ThemeNotifier.new,
);
