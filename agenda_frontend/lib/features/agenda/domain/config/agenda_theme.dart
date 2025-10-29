import 'package:flutter/material.dart';

/// Tema visivo centralizzato per l'agenda.
/// Definisce colori, spessori, altezze e stili coerenti
/// per tutti i componenti della vista agenda.
///
/// In futuro potrai adattarlo dinamicamente (dark mode, branding, ecc.)
class AgendaTheme {
  // ──────────────────────────────────────────────
  // 🎨 COLORI BASE
  // ──────────────────────────────────────────────

  /// Colore principale per i separatori verticali/orizzontali
  static Color get dividerColor => Colors.grey.shade300;

  /// Colore per ombre leggere o bordi di separazione
  static Color get shadowColor => Colors.black.withOpacity(0.5);

  /// Colore di sfondo per lo slot orario
  static const Color backgroundHourSlot = Colors.white;

  /// Colore di sfondo per le intestazioni staff
  static Color staffHeaderBackground(Color base) =>
      base.withValues(alpha: 0.15);

  /// Colore del testo nelle intestazioni staff
  static const Color staffHeaderTextColor = Colors.black87;

  /// Colore del bordo di un appuntamento (card)
  static Color get appointmentBorder => Colors.grey.shade400;

  // ──────────────────────────────────────────────
  // 💧 OMBRE & BORDI
  // ──────────────────────────────────────────────

  /// Ombra leggera usata nei divider verticali
  static BoxShadow get subtleShadow =>
      BoxShadow(color: shadowColor, offset: const Offset(1, 0), blurRadius: 2);

  /// Stile base per i separatori verticali
  static BoxDecoration get verticalDividerDecoration =>
      BoxDecoration(color: dividerColor, boxShadow: [subtleShadow]);

  /// Stile base per i separatori orizzontali
  static BoxDecoration get horizontalDividerDecoration =>
      const BoxDecoration(color: Colors.grey);

  // ──────────────────────────────────────────────
  // 🧱 STILI TESTO
  // ──────────────────────────────────────────────

  static const TextStyle staffHeaderTextStyle = TextStyle(
    fontWeight: FontWeight.bold,
    color: staffHeaderTextColor,
  );

  static const TextStyle hourTextStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );

  static const TextStyle appointmentTextStyle = TextStyle(
    fontSize: 14,
    color: Colors.black87,
  );

  // ──────────────────────────────────────────────
  // 👻 EFFETTO DRAG / FANTASMA
  // ──────────────────────────────────────────────

  /// Opacità del "fantasma" lasciato dalla card originale durante il drag.
  /// Regola questo valore per rendere il ghost più o meno visibile.
  static const double ghostOpacity = 0.50;

  /// Durata dell’effetto fade-out del fantasma dopo il rilascio.
  /// Aumentala per una dissolvenza più lenta e visibile.
  static const Duration ghostFadeDuration = Duration(milliseconds: 500);
}
