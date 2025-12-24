import 'dart:math' as math;

import '../../../../../core/models/appointment.dart';
import '../../../domain/config/layout_config.dart';

/// Computes the amount of free minutes starting from the given [index] slot.
///
/// Behavior:
/// - If the slot is fully occupied by one or more appointments -> returns 0.
/// - If the slot is partially occupied -> returns only the free minutes
///   inside that slot (no look-ahead aggregation).
/// - If the slot is totally free -> extends over subsequent contiguous
///   free slots until the next busy slot (original behavior).
Duration computeFreeDurationForSlot(
  int index,
  List<Appointment> appointments,
  LayoutConfig layout,
) {
  final slotStart = Duration(minutes: index * layout.minutesPerSlot);
  final slotEnd = Duration(minutes: (index + 1) * layout.minutesPerSlot);
  final slotDurationMinutes = layout.minutesPerSlot;

  // Collect overlaps of appointments within the current slot.
  final overlaps =
      <(int, int)>[]; // intervals [start, end) in minutes relative to slot
  for (final a in appointments) {
    final apptStart = Duration(
      hours: a.startTime.hour,
      minutes: a.startTime.minute,
    );
    final apptEnd = Duration(hours: a.endTime.hour, minutes: a.endTime.minute);
    if (slotStart < apptEnd && slotEnd > apptStart) {
      final overlapStart = apptStart > slotStart ? apptStart : slotStart;
      final overlapEnd = apptEnd < slotEnd ? apptEnd : slotEnd;
      final relativeStart = overlapStart.inMinutes - slotStart.inMinutes;
      final relativeEnd = overlapEnd.inMinutes - slotStart.inMinutes;
      overlaps.add((
        relativeStart.clamp(0, slotDurationMinutes),
        relativeEnd.clamp(0, slotDurationMinutes),
      ));
    }
  }

  if (overlaps.isNotEmpty) {
    // Merge intervals to avoid double counting.
    overlaps.sort((a, b) => a.$1.compareTo(b.$1));
    final merged = <(int, int)>[];
    for (final o in overlaps) {
      if (merged.isEmpty) {
        merged.add(o);
      } else {
        final last = merged.last;
        if (o.$1 <= last.$2) {
          merged[merged.length - 1] = (last.$1, math.max(last.$2, o.$2));
        } else {
          merged.add(o);
        }
      }
    }
    final coveredMinutes = merged.fold<int>(
      0,
      (sum, it) => sum + (it.$2 - it.$1),
    );
    if (coveredMinutes >= slotDurationMinutes) {
      return Duration.zero;
    } else {
      return Duration(minutes: slotDurationMinutes - coveredMinutes);
    }
  }

  // Fully free slot: extend to next busy slot.
  int nextBusy = layout.totalSlots;
  for (int i = index + 1; i < layout.totalSlots; i++) {
    final sStart = Duration(minutes: i * layout.minutesPerSlot);
    final sEnd = Duration(minutes: (i + 1) * layout.minutesPerSlot);
    final isBusy = appointments.any((a) {
      final start = Duration(
        hours: a.startTime.hour,
        minutes: a.startTime.minute,
      );
      final end = Duration(hours: a.endTime.hour, minutes: a.endTime.minute);
      return sStart < end && sEnd > start;
    });
    if (isBusy) {
      nextBusy = i;
      break;
    }
  }

  final freeSlotsCount = nextBusy - index;
  final freeMinutes = freeSlotsCount * layout.minutesPerSlot;
  return Duration(minutes: freeMinutes);
}
