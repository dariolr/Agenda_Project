import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/time_block.dart';
import 'business_providers.dart';
import 'date_range_provider.dart';
import 'location_providers.dart';

class TimeBlocksNotifier extends Notifier<List<TimeBlock>> {
  bool _initialized = false;

  @override
  List<TimeBlock> build() {
    if (!_initialized) {
      _initialized = true;
      state = _mockTimeBlocks();
    }
    return state;
  }

  List<TimeBlock> _mockTimeBlocks() {
    // Nessun blocco di default
    return [];
  }

  /// Aggiunge un nuovo blocco di non disponibilità.
  TimeBlock addBlock({
    required List<int> staffIds,
    required DateTime startTime,
    required DateTime endTime,
    String? reason,
    bool isAllDay = false,
  }) {
    final business = ref.read(currentBusinessProvider);
    final location = ref.read(currentLocationProvider);

    final nextId = state.isEmpty
        ? 1
        : state.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;

    final block = TimeBlock(
      id: nextId,
      businessId: business.id,
      locationId: location.id,
      staffIds: staffIds,
      startTime: startTime,
      endTime: endTime,
      reason: reason,
      isAllDay: isAllDay,
    );

    state = [...state, block];
    return block;
  }

  /// Aggiorna un blocco esistente.
  void updateBlock(TimeBlock updated) {
    state = [
      for (final block in state)
        if (block.id == updated.id) updated else block,
    ];
  }

  /// Elimina un blocco per id.
  void deleteBlock(int blockId) {
    state = [
      for (final block in state)
        if (block.id != blockId) block,
    ];
  }

  /// Sposta un blocco a un nuovo orario.
  void moveBlock({
    required int blockId,
    required DateTime newStart,
    required DateTime newEnd,
  }) {
    state = [
      for (final block in state)
        if (block.id == blockId)
          block.copyWith(startTime: newStart, endTime: newEnd)
        else
          block,
    ];
  }

  /// Modifica gli staff assegnati a un blocco.
  void updateBlockStaff({required int blockId, required List<int> staffIds}) {
    state = [
      for (final block in state)
        if (block.id == blockId) block.copyWith(staffIds: staffIds) else block,
    ];
  }
}

final timeBlocksProvider =
    NotifierProvider<TimeBlocksNotifier, List<TimeBlock>>(
      TimeBlocksNotifier.new,
    );

/// Blocchi filtrati per la sede corrente e la data corrente dell'agenda.
final timeBlocksForCurrentLocationProvider = Provider<List<TimeBlock>>((ref) {
  final location = ref.watch(currentLocationProvider);
  final currentDate = ref.watch(agendaDateProvider);
  final dayStart = DateUtils.dateOnly(currentDate);
  final dayEnd = dayStart.add(const Duration(days: 1));
  final blocks = ref.watch(timeBlocksProvider);

  return [
    for (final block in blocks)
      if (block.locationId == location.id &&
          !block.endTime.isBefore(dayStart) &&
          block.startTime.isBefore(dayEnd))
        block,
  ];
});

/// Blocchi per uno staff specifico nella data corrente dell'agenda.
final timeBlocksForStaffProvider = Provider.family<List<TimeBlock>, int>((
  ref,
  staffId,
) {
  final blocks = ref.watch(timeBlocksForCurrentLocationProvider);
  return [
    for (final block in blocks)
      if (block.includesStaff(staffId)) block,
  ];
});
