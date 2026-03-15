import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Comportamento di scroll personalizzato per l’app Agenda.
///
/// - Rimuove glow e scrollbar visibili.
/// - Mantiene la compatibilità con mouse, touch e trackpad.
/// - Usa una fisica permissiva che evita conflitti con PageView
///   e altri scroll orizzontali annidati.
///
/// Questo risolve i casi in cui il PageView esterno non riceve
/// mai il gesto perché la scroll view interna lo cattura completamente.
class NoScrollbarBehavior extends ScrollBehavior {
  const NoScrollbarBehavior();

  /// 🔹 Disabilita completamente la scrollbar visiva.
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  /// 🔹 Abilita lo scroll con tutti i tipi di input
  /// (touch, mouse, trackpad, ecc.)
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };

  /// 🔹 Fisica dello scroll:
  /// - `BouncingScrollPhysics` → effetto “elastic” ai bordi (mobile-like).
  /// - `AlwaysScrollableScrollPhysics` → consente lo scroll anche
  ///   quando non c’è overflow, così i gesti possono passare
  ///   al PageView esterno.
  ///
  /// Risultato: scroll fluido, niente blocchi, compatibile con nested scroll.
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}
