import 'package:flutter/material.dart';

class AppInteractionColors extends ThemeExtension<AppInteractionColors> {
  const AppInteractionColors({
    required this.hoverFill,
    required this.pressedFill,
  });

  final Color hoverFill;
  final Color pressedFill;

  @override
  AppInteractionColors copyWith({Color? hoverFill, Color? pressedFill}) {
    return AppInteractionColors(
      hoverFill: hoverFill ?? this.hoverFill,
      pressedFill: pressedFill ?? this.pressedFill,
    );
  }

  @override
  AppInteractionColors lerp(AppInteractionColors? other, double t) {
    if (other == null) return this;
    return AppInteractionColors(
      hoverFill: Color.lerp(hoverFill, other.hoverFill, t) ?? hoverFill,
      pressedFill: Color.lerp(pressedFill, other.pressedFill, t) ?? pressedFill,
    );
  }

  @override
  int get hashCode => Object.hash(hoverFill, pressedFill);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppInteractionColors &&
        other.hoverFill == hoverFill &&
        other.pressedFill == pressedFill;
  }
}
