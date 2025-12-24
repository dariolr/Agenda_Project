import 'package:flutter/material.dart';

class AppInteractionColors extends ThemeExtension<AppInteractionColors> {
  const AppInteractionColors({
    required this.hoverFill,
    required this.pressedFill,
    required this.alternatingRowFill,
  });

  final Color hoverFill;
  final Color pressedFill;

  /// Colore di sfondo per righe alternate (es. liste, tabelle)
  final Color alternatingRowFill;

  @override
  AppInteractionColors copyWith({
    Color? hoverFill,
    Color? pressedFill,
    Color? alternatingRowFill,
  }) {
    return AppInteractionColors(
      hoverFill: hoverFill ?? this.hoverFill,
      pressedFill: pressedFill ?? this.pressedFill,
      alternatingRowFill: alternatingRowFill ?? this.alternatingRowFill,
    );
  }

  @override
  AppInteractionColors lerp(AppInteractionColors? other, double t) {
    if (other == null) return this;
    return AppInteractionColors(
      hoverFill: Color.lerp(hoverFill, other.hoverFill, t) ?? hoverFill,
      pressedFill: Color.lerp(pressedFill, other.pressedFill, t) ?? pressedFill,
      alternatingRowFill:
          Color.lerp(alternatingRowFill, other.alternatingRowFill, t) ??
          alternatingRowFill,
    );
  }

  @override
  int get hashCode => Object.hash(hoverFill, pressedFill, alternatingRowFill);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppInteractionColors &&
        other.hoverFill == hoverFill &&
        other.pressedFill == pressedFill &&
        other.alternatingRowFill == alternatingRowFill;
  }
}
