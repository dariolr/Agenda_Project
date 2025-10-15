import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Comportamento di scroll che disattiva scrollbar, effetto glow e spazio riservato
class NoScrollbarBehavior extends ScrollBehavior {
  const NoScrollbarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child; // 🔕 nessuna scrollbar
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  }; // abilita lo scroll anche col mouse

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics(); // nessun overscroll o padding aggiuntivo
}
