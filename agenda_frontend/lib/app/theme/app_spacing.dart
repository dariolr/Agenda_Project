/// Costanti di spacing configurabili a livello applicativo.
/// Modifica questi valori per cambiare lo spacing in tutta l'app.
abstract class AppSpacing {
  AppSpacing._();
  // ─────────────────────────────────────────────────────────────────────────
  // General spacing
  // ─────────────────────────────────────────────────────────────────────────

  /// Spacing piccolo generico.
  static const double small = 8.0;

  /// Spacing medio generico.
  static const double medium = 12.0;

  /// Spacing grande generico.
  static const double large = 24.0;

  /// Spacing extra large generico.
  static const double xLarge = 60.0;

  // ─────────────────────────────────────────────────────────────────────────
  // Form spacing
  // ─────────────────────────────────────────────────────────────────────────
  /// Spacing verticale tra la prima riga dei form e il titolo.
  static const double formFirstRowSpacing = large;

  /// Spacing verticale tra le righe dei form (es. tra data/ora e servizio).
  static const double formRowSpacing = xLarge;

  /// Spacing orizzontale tra i campi sulla stessa riga (es. tra data e ora).
  static const double formFieldSpacing = medium;

  // ─────────────────────────────────────────────────────────────────────────
  // Bottom sheet spacing
  // ─────────────────────────────────────────────────────────────────────────

  /// Spacing tra il contenuto del form e i pulsanti azioni.
  static const double formToActionsSpacing = xLarge;

  /// Spacing tra i pulsanti azioni.
  static const double actionButtonSpacing = small;
}
