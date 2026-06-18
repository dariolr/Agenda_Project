import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/appointment.dart';
import 'appointment_providers.dart';
import 'calendar_view_mode_provider.dart';
import 'staff_filter_providers.dart';

/// Riepilogo derivato della giornata visualizzata in agenda:
/// numero di appuntamenti (booking unici) e clienti unici.
class AgendaDaySummary {
  const AgendaDaySummary({
    required this.appointmentCount,
    required this.uniqueClientCount,
  });

  final int appointmentCount;
  final int uniqueClientCount;

  bool get isEmpty => appointmentCount == 0 && uniqueClientCount == 0;
}

/// Stati booking inclusi nel riepilogo giornaliero.
///
/// Esclude `cancelled`, `no_show`, `replaced`; include `pending`,
/// `confirmed`, `arrived`, `completed`. Riusa gli helper esistenti del
/// modello (`isCancelled`, `isReplaced`) e gestisce localmente `no_show`,
/// senza modificare il modello.
bool _isCountable(Appointment appointment) {
  if (appointment.isCancelled || appointment.isReplaced) return false;
  if (appointment.bookingStatus == 'no_show') return false;
  return true;
}

/// Provider derivato (manuale, senza code generation) che calcola il riepilogo
/// della giornata corrente a partire dagli appuntamenti già caricati e filtrati
/// per data/sede/staff/servizi della vista corrente.
///
/// Restituisce `null` quando il riepilogo non deve essere mostrato:
/// - la vista corrente non è la day view;
/// - gli appuntamenti sono ancora in caricamento iniziale (nessun dato
///   precedente disponibile), per evitare flicker.
final agendaDaySummaryProvider = Provider<AgendaDaySummary?>((ref) {
  final viewMode = ref.watch(calendarViewModeProvider);
  if (viewMode != CalendarViewMode.day) {
    return null;
  }

  // Evita flicker durante il primo caricamento: nascondi finché non c'è
  // almeno un valore (in seguito i refresh mantengono il valore precedente).
  final appointmentsAsync = ref.watch(appointmentsProvider);
  if (appointmentsAsync.isLoading && !appointmentsAsync.hasValue) {
    return null;
  }

  final appointments = ref.watch(appointmentsForCurrentLocationProvider);

  // Considera solo gli staff effettivamente visibili in agenda (filtro
  // colonne staff), così il riepilogo coincide con gli appuntamenti mostrati.
  final visibleStaffIds = <int>{
    for (final staff in ref.watch(filteredStaffProvider)) staff.id,
  };

  final bookingIds = <int>{};
  final clientIds = <int>{};
  for (final appointment in appointments) {
    if (!_isCountable(appointment)) continue;
    if (!visibleStaffIds.contains(appointment.staffId)) continue;
    bookingIds.add(appointment.bookingId);
    final clientId = appointment.clientId;
    if (clientId != null) {
      clientIds.add(clientId);
    }
  }

  return AgendaDaySummary(
    appointmentCount: bookingIds.length,
    uniqueClientCount: clientIds.length,
  );
});
