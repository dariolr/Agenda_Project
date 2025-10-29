/// Entry point modulare per la feature "Agenda"
/// Importa qui tutti i componenti pubblici dell'agenda.
/// Così altrove potrai scrivere semplicemente:
///   import 'package:agenda/features/agenda/agenda_feature.dart';

library;

export 'domain/config/agenda_theme.dart'; // se aggiungi un tema centralizzato
// ──────────────────────────────────────────────
// � Domain & Config
// ──────────────────────────────────────────────
export 'domain/config/layout_config.dart';
// Schermata di agenda (entry screen)
export 'presentation/agenda_screen.dart';
export 'presentation/screens/day_view/hour_column.dart';
// Vista principale (giornaliera multi-staff)
export 'presentation/screens/day_view/multi_staff_day_view.dart';
// ──────────────────────────────────────────────
// 🎨 Presentation layer
// ──────────────────────────────────────────────

// Layout e componenti core
export 'presentation/screens/day_view/responsive_layout.dart';
export 'presentation/screens/day_view/staff_column.dart';
export 'presentation/screens/day_view/staff_header_row.dart';
export 'presentation/screens/widgets/agenda_dividers.dart';
// ──────────────────────────────────────────────
// � Application (providers, notifiers, stato)
// ──────────────────────────────────────────────
export 'providers/agenda_scroll_provider.dart';
