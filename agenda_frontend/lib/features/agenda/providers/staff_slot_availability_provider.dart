import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../staff/presentation/staff_availability_screen.dart';
import 'date_range_provider.dart';
import 'layout_config_provider.dart';

/// Provider che fornisce la disponibilità degli slot per uno staff specifico
/// in base alla data corrente dell'agenda.
///
/// Ritorna un `Set<int>` contenente gli indici degli slot DISPONIBILI.
/// Uno slot NON è disponibile se il suo indice NON è presente nel set.
final staffSlotAvailabilityProvider = Provider.family<Set<int>, int>((
  ref,
  staffId,
) {
  final agendaDate = ref.watch(agendaDateProvider);
  final asyncByStaff = ref.watch(staffAvailabilityByStaffProvider);

  // Determina il giorno della settimana (1 = Lunedì, 7 = Domenica)
  // DateTime.weekday: 1 = Monday, ..., 7 = Sunday
  final dayOfWeek = agendaDate.weekday;

  // Ottieni i dati di disponibilità per lo staff
  final allData = asyncByStaff.value ?? const <int, Map<int, Set<int>>>{};
  final staffData = allData[staffId];

  if (staffData == null) {
    // Nessun dato: considera tutti gli slot come disponibili
    // Questo evita di mostrare tutto come non disponibile
    // quando i dati non sono ancora caricati
    return const <int>{};
  }

  // Ritorna gli slot disponibili per il giorno corrente
  return staffData[dayOfWeek] ?? const <int>{};
});

/// Provider che verifica se uno slot specifico è disponibile.
/// Più efficiente per query puntuali.
final isSlotAvailableProvider =
    Provider.family<bool, ({int staffId, int slotIndex})>((ref, params) {
      final availableSlots = ref.watch(
        staffSlotAvailabilityProvider(params.staffId),
      );

      // Se il set è vuoto, consideriamo lo staff come "sempre disponibile"
      // (dati non ancora caricati o nessuna configurazione)
      if (availableSlots.isEmpty) {
        return true;
      }

      return availableSlots.contains(params.slotIndex);
    });

/// Provider che raggruppa gli slot non disponibili consecutivi
/// per ottimizzare il rendering (un solo widget per range).
///
/// Ritorna una lista di (startIndex, count) per ogni range non disponibile.
final unavailableSlotRangesProvider =
    Provider.family<List<({int startIndex, int count})>, int>((ref, staffId) {
      final availableSlots = ref.watch(staffSlotAvailabilityProvider(staffId));
      final layoutConfig = ref.watch(layoutConfigProvider);
      final totalSlots = layoutConfig.totalSlots;

      // Se non ci sono dati, nessun range non disponibile
      if (availableSlots.isEmpty) {
        return const [];
      }

      final List<({int startIndex, int count})> ranges = [];
      int? rangeStart;
      int rangeCount = 0;

      for (int i = 0; i < totalSlots; i++) {
        final isAvailable = availableSlots.contains(i);

        if (!isAvailable) {
          // Slot non disponibile
          if (rangeStart == null) {
            rangeStart = i;
            rangeCount = 1;
          } else {
            rangeCount++;
          }
        } else {
          // Slot disponibile: chiudi il range precedente se esiste
          if (rangeStart != null) {
            ranges.add((startIndex: rangeStart, count: rangeCount));
            rangeStart = null;
            rangeCount = 0;
          }
        }
      }

      // Chiudi l'ultimo range se necessario
      if (rangeStart != null) {
        ranges.add((startIndex: rangeStart, count: rangeCount));
      }

      return ranges;
    });
