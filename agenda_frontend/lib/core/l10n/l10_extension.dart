import 'package:flutter/widgets.dart';

import 'l10n.dart';

/// 🔤 Estensione per accedere facilmente alle stringhe localizzate.
///
/// Permette di scrivere:
/// ```dart
/// Text(context.l10n.welcomeMessage)
/// ```
/// invece di:
/// ```dart
/// Text(L10n.of(context).welcomeMessage)
/// ```
///
/// ✅ Compatibile con aggiornamenti runtime della lingua.
/// ✅ Evita dipendenze da `L10n.current` statico.
/// ✅ Standard consigliato per progetti Flutter internazionalizzati.
extension L10nX on BuildContext {
  /// Restituisce l'istanza corrente di [L10n] per questo [BuildContext].
  L10n get l10n => L10n.of(this);
}
