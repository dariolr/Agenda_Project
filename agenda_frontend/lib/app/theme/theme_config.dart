import 'package:flutter/material.dart';

class AppThemeConfig {
  final Color seedColor;
  final Brightness brightness;

  const AppThemeConfig({
    required this.seedColor,
    this.brightness = Brightness.light,
  });

  AppThemeConfig copyWith({Color? seedColor, Brightness? brightness}) {
    return AppThemeConfig(
      seedColor: seedColor ?? this.seedColor,
      brightness: brightness ?? this.brightness,
    );
  }
}
