import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/recurrence_rule.dart';
import '../../../core/models/time_block.dart';
import '../../../core/network/network_providers.dart';
import '../../auth/providers/auth_provider.dart';
import 'date_range_provider.dart';
import 'location_providers.dart';

class TimeBlocksNotifier extends AsyncNotifier<List<TimeBlock>> {
  @override
  Future<List<TimeBlock>> build() async {
    final authState = ref.watch(authProvider);
    if (!authState.isAuthenticated) {
      return [];
    }

    final apiClient = ref.watch(apiClientProvider);
    final location = ref.watch(currentLocationProvider);
    final agendaDate = ref.watch(agendaDateProvider);

    // Non caricare se location non è ancora valida
    if (location.id <= 0) {
      return [];
    }

    // Carica blocchi per la data corrente dell'agenda (stesso pattern degli appuntamenti)
    final dayStart = DateUtils.dateOnly(agendaDate);
    final dayEnd = dayStart.add(const Duration(days: 1));

    try {
      final data = await apiClient.getTimeBlocks(
        location.id,
        fromDate: _formatDateTime(dayStart),
        toDate: _formatDateTime(dayEnd),
      );
      return data.map(_parseTimeBlock).toList();
    } catch (_) {
      return [];
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  TimeBlock _parseTimeBlock(Map<String, dynamic> json) {
    return TimeBlock(
      id: json['id'] as int,
      businessId: json['business_id'] as int,
      locationId: json['location_id'] as int,
      staffIds: (json['staff_ids'] as List).map((e) => e as int).toList(),
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      reason: json['reason'] as String?,
      isAllDay: (json['is_all_day'] as int?) == 1,
    );
  }

  Future<void> refresh() async {
    // Invalida il provider per forzare un rebuild con la data corrente
    ref.invalidateSelf();
  }

  /// Aggiunge un nuovo blocco di non disponibilità.
  Future<TimeBlock> addBlock({
    required List<int> staffIds,
    required DateTime startTime,
    required DateTime endTime,
    String? reason,
    bool isAllDay = false,
  }) async {
    final apiClient = ref.read(apiClientProvider);
    final location = ref.read(currentLocationProvider);

    final data = await apiClient.createTimeBlock(
      locationId: location.id,
      startTime: _formatDateTime(startTime),
      endTime: _formatDateTime(endTime),
      staffIds: staffIds,
      isAllDay: isAllDay,
      reason: reason,
    );

    final block = _parseTimeBlock(data);
    final current = state.value ?? [];
    state = AsyncData([...current, block]);
    return block;
  }

  /// Aggiunge una serie di blocchi ricorrenti.
  Future<List<TimeBlock>> addRecurringBlocks({
    required List<int> staffIds,
    required DateTime startTime,
    required DateTime endTime,
    required RecurrenceConfig recurrence,
    String? reason,
    bool isAllDay = false,
  }) async {
    final apiClient = ref.read(apiClientProvider);
    final location = ref.read(currentLocationProvider);
    final duration = endTime.difference(startTime);
    final occurrences = recurrence.calculateOccurrences(startTime);
    final createdBlocks = <TimeBlock>[];

    for (final occurrenceStart in occurrences) {
      final data = await apiClient.createTimeBlock(
        locationId: location.id,
        startTime: _formatDateTime(occurrenceStart),
        endTime: _formatDateTime(occurrenceStart.add(duration)),
        staffIds: staffIds,
        isAllDay: isAllDay,
        reason: reason,
      );
      createdBlocks.add(_parseTimeBlock(data));
    }

    final current = state.value ?? [];
    state = AsyncData([...current, ...createdBlocks]);
    return createdBlocks;
  }

  /// Aggiorna un blocco esistente.
  Future<void> updateBlock({
    required int blockId,
    DateTime? startTime,
    DateTime? endTime,
    List<int>? staffIds,
    String? reason,
    bool? isAllDay,
  }) async {
    final apiClient = ref.read(apiClientProvider);

    final data = await apiClient.updateTimeBlock(
      blockId: blockId,
      startTime: startTime != null ? _formatDateTime(startTime) : null,
      endTime: endTime != null ? _formatDateTime(endTime) : null,
      staffIds: staffIds,
      isAllDay: isAllDay,
      reason: reason,
    );

    final updated = _parseTimeBlock(data);
    final current = state.value ?? [];
    state = AsyncData([
      for (final block in current)
        if (block.id == updated.id) updated else block,
    ]);
  }

  /// Elimina un blocco per id.
  Future<void> deleteBlock(int blockId) async {
    final apiClient = ref.read(apiClientProvider);
    await apiClient.deleteTimeBlock(blockId);

    final current = state.value ?? [];
    state = AsyncData([
      for (final block in current)
        if (block.id != blockId) block,
    ]);
  }

  /// Sposta un blocco a un nuovo orario.
  Future<void> moveBlock({
    required int blockId,
    required DateTime newStart,
    required DateTime newEnd,
  }) async {
    await updateBlock(blockId: blockId, startTime: newStart, endTime: newEnd);
  }

  /// Modifica gli staff assegnati a un blocco.
  Future<void> updateBlockStaff({
    required int blockId,
    required List<int> staffIds,
  }) async {
    await updateBlock(blockId: blockId, staffIds: staffIds);
  }
}

final timeBlocksProvider =
    AsyncNotifierProvider<TimeBlocksNotifier, List<TimeBlock>>(
      TimeBlocksNotifier.new,
    );

/// Blocchi filtrati per la sede corrente e la data corrente dell'agenda.
/// Il provider principale già carica solo i blocchi per la data dell'agenda,
/// quindi qui filtriamo solo per location (in caso di blocchi multi-location).
final timeBlocksForCurrentLocationProvider = Provider<List<TimeBlock>>((ref) {
  final location = ref.watch(currentLocationProvider);
  final blocksAsync = ref.watch(timeBlocksProvider);
  final blocks = blocksAsync.value ?? [];

  return [
    for (final block in blocks)
      if (block.locationId == location.id) block,
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
