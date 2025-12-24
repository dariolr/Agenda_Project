import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/availability_exception.dart';
import '../../staff/presentation/staff_availability_screen.dart';
import '../../staff/providers/availability_exceptions_provider.dart';
import 'date_range_provider.dart';
import 'layout_config_provider.dart';

/// Provider che fornisce la disponibilità degli slot per uno staff specifico
/// in base alla data corrente dell'agenda.
///
/// La disponibilità finale è calcolata come:
/// 1. Base: template settimanale (es. Lun-Ven 09:00-18:00)
/// 2. + Eccezioni "available": aggiungono slot disponibili
/// 3. - Eccezioni "unavailable": rimuovono slot disponibili
///
/// Ritorna un `Set<int>` contenente gli indici degli slot DISPONIBILI.
/// - Set vuoto = nessuna disponibilità (staff non lavora quel giorno)
/// - Se non ci sono dati configurati, lo staff è considerato NON disponibile (comportamento restrittivo)
final staffSlotAvailabilityProvider = Provider.family<Set<int>, int>((
  ref,
  staffId,
) {
  final agendaDate = ref.watch(agendaDateProvider);
  final asyncByStaff = ref.watch(staffAvailabilityByStaffProvider);
  final layoutConfig = ref.watch(layoutConfigProvider);

  // Determina il giorno della settimana (1 = Lunedì, 7 = Domenica)
  final dayOfWeek = agendaDate.weekday;

  // ═══════════════════════════════════════════════════════════════
  // 1️⃣ BASE: Template settimanale
  // ═══════════════════════════════════════════════════════════════
  Set<int> baseSlots;

  final allData = asyncByStaff.value;
  if (allData == null) {
    baseSlots = <int>{};
  } else {
    final staffData = allData[staffId];
    if (staffData == null || !staffData.containsKey(dayOfWeek)) {
      baseSlots = <int>{};
    } else {
      baseSlots = Set<int>.from(staffData[dayOfWeek]!);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 2️⃣ ECCEZIONI: Applica modifiche per la data specifica
  // ═══════════════════════════════════════════════════════════════
  final exceptions = ref.watch(
    exceptionsForStaffOnDateProvider((staffId: staffId, date: agendaDate)),
  );

  if (exceptions.isEmpty) {
    return baseSlots;
  }

  // Applica le eccezioni in ordine
  Set<int> finalSlots = Set<int>.from(baseSlots);

  for (final exception in exceptions) {
    final exceptionSlots = exception.toSlotIndices(
      minutesPerSlot: layoutConfig.minutesPerSlot,
      totalSlotsPerDay: layoutConfig.totalSlots,
    );

    if (exception.type == AvailabilityExceptionType.available) {
      // AGGIUNGE disponibilità (es. turno extra)
      finalSlots = finalSlots.union(exceptionSlots);
    } else {
      // RIMUOVE disponibilità (es. ferie, malattia)
      finalSlots = finalSlots.difference(exceptionSlots);
    }
  }

  return finalSlots;
});

/// Provider che verifica se uno slot specifico è disponibile.
/// Più efficiente per query puntuali.
final isSlotAvailableProvider =
    Provider.family<bool, ({int staffId, int slotIndex})>((ref, params) {
      final availableSlots = ref.watch(
        staffSlotAvailabilityProvider(params.staffId),
      );

      // Se il set è vuoto, lo staff non è disponibile
      if (availableSlots.isEmpty) {
        return false;
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

      // Se il set è vuoto, l'intera giornata è non disponibile
      if (availableSlots.isEmpty) {
        return [(startIndex: 0, count: totalSlots)];
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
