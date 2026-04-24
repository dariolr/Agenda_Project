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

    if (location.id <= 0) {
      return [];
    }

    final dayStart = DateUtils.dateOnly(agendaDate);
    final dayEnd = dayStart.add(const Duration(days: 1));

    try {
      final data = await apiClient.getTimeBlocks(
        location.id,
        fromDate: _formatDateTime(dayStart),
        toDate: _formatDateTime(dayEnd),
      );
      return data.map(TimeBlock.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  /// Adds a single or recurring series of time blocks.
  ///
  /// When [recurrence] is provided the backend creates the whole series in one
  /// call and returns `{time_blocks: [...], recurrence_rule_id, created_count}`.
  /// [excludedIndices] (0-based) skips those occurrences server-side.
  Future<List<TimeBlock>> addBlock({
    required List<int> staffIds,
    required DateTime startTime,
    required DateTime endTime,
    String? reason,
    bool isAllDay = false,
    bool allowOnlineBookingDuringBlock = false,
    RecurrenceConfig? recurrence,
    List<int>? excludedIndices,
  }) async {
    final apiClient = ref.read(apiClientProvider);
    final location = ref.read(currentLocationProvider);

    Map<String, dynamic>? recurrencePayload;
    if (recurrence != null) {
      recurrencePayload = {
        'frequency': recurrence.frequency.value,
        'interval_value': recurrence.intervalValue,
        if (recurrence.maxOccurrences != null)
          'max_occurrences': recurrence.maxOccurrences,
        if (recurrence.endDate != null)
          'end_date':
              '${recurrence.endDate!.year}-${recurrence.endDate!.month.toString().padLeft(2, '0')}-${recurrence.endDate!.day.toString().padLeft(2, '0')}',
      };
    }

    final response = await apiClient.createTimeBlock(
      locationId: location.id,
      startTime: _formatDateTime(startTime),
      endTime: _formatDateTime(endTime),
      staffIds: staffIds,
      isAllDay: isAllDay,
      allowOnlineBookingDuringBlock: allowOnlineBookingDuringBlock,
      reason: reason,
      recurrence: recurrencePayload,
      excludedIndices: excludedIndices,
    );

    final List<TimeBlock> created;
    if (response.containsKey('time_blocks')) {
      created = (response['time_blocks'] as List)
          .map((b) => TimeBlock.fromJson(Map<String, dynamic>.from(b as Map)))
          .toList();
    } else {
      created = [
        TimeBlock.fromJson(
          Map<String, dynamic>.from(response['time_block'] as Map),
        ),
      ];
    }

    final current = state.value ?? [];
    state = AsyncData([...current, ...created]);
    return created;
  }

  /// Updates a single block (scope='this') or shared fields across the series
  /// (scope='all'). When scope='all', the local state is refreshed entirely.
  Future<void> updateBlock({
    required int blockId,
    DateTime? startTime,
    DateTime? endTime,
    List<int>? staffIds,
    String? reason,
    bool? isAllDay,
    bool? allowOnlineBookingDuringBlock,
    String scope = 'this',
    int? fromIndex,
  }) async {
    final apiClient = ref.read(apiClientProvider);

    final response = await apiClient.updateTimeBlock(
      blockId: blockId,
      startTime: startTime != null ? _formatDateTime(startTime) : null,
      endTime: endTime != null ? _formatDateTime(endTime) : null,
      staffIds: staffIds,
      isAllDay: isAllDay,
      allowOnlineBookingDuringBlock: allowOnlineBookingDuringBlock,
      reason: reason,
      scope: scope,
      fromIndex: fromIndex,
    );

    if (scope == 'all' || scope == 'future') {
      // Reload to reflect all changes across the series
      ref.invalidateSelf();
      return;
    }

    final updated = TimeBlock.fromJson(
      Map<String, dynamic>.from(response['time_block'] as Map),
    );
    final current = state.value ?? [];
    state = AsyncData([
      for (final block in current)
        if (block.id == updated.id) updated else block,
    ]);
  }

  /// Deletes a single block (scope='this') or the entire series (scope='all').
  Future<void> deleteBlock(
    int blockId, {
    String scope = 'this',
    int? fromIndex,
  }) async {
    final apiClient = ref.read(apiClientProvider);
    await apiClient.deleteTimeBlock(
      blockId,
      scope: scope,
      fromIndex: fromIndex,
    );

    if (scope == 'all' || scope == 'future') {
      // We don't know all the IDs in the series, so invalidate and reload
      ref.invalidateSelf();
      return;
    }

    final current = state.value ?? [];
    state = AsyncData([
      for (final block in current)
        if (block.id != blockId) block,
    ]);
  }

  Future<void> moveBlock({
    required int blockId,
    required DateTime newStart,
    required DateTime newEnd,
  }) async {
    await updateBlock(blockId: blockId, startTime: newStart, endTime: newEnd);
  }

  Future<void> updateBlockStaff({
    required int blockId,
    required List<int> staffIds,
  }) async {
    await updateBlock(blockId: blockId, staffIds: staffIds);
  }

  /// Splits a shared block while resizing only one staff card.
  ///
  /// Creates a dedicated block for [staffId] with [newEndTime], then removes
  /// that staff from the original shared block. Local state is committed once
  /// at the end to avoid transient duplicate cards in UI.
  Future<void> splitBlockForSingleStaffResize({
    required TimeBlock originalBlock,
    required int staffId,
    required DateTime newEndTime,
  }) async {
    final apiClient = ref.read(apiClientProvider);
    final location = ref.read(currentLocationProvider);
    final remainingStaffIds = originalBlock.staffIds
        .where((id) => id != staffId)
        .toList();

    if (remainingStaffIds.isEmpty) {
      await updateBlock(blockId: originalBlock.id, endTime: newEndTime);
      return;
    }

    final createResponse = await apiClient.createTimeBlock(
      locationId: location.id,
      startTime: _formatDateTime(originalBlock.startTime),
      endTime: _formatDateTime(newEndTime),
      staffIds: [staffId],
      isAllDay: originalBlock.isAllDay,
      allowOnlineBookingDuringBlock:
          originalBlock.allowOnlineBookingDuringBlock,
      reason: originalBlock.reason,
    );

    final created = createResponse.containsKey('time_block')
        ? TimeBlock.fromJson(
            Map<String, dynamic>.from(createResponse['time_block'] as Map),
          )
        : TimeBlock.fromJson(
            Map<String, dynamic>.from(
              (createResponse['time_blocks'] as List).first as Map,
            ),
          );

    final updateResponse = await apiClient.updateTimeBlock(
      blockId: originalBlock.id,
      staffIds: remainingStaffIds,
      scope: 'this',
    );
    final updatedOriginal = TimeBlock.fromJson(
      Map<String, dynamic>.from(updateResponse['time_block'] as Map),
    );

    final current = state.value ?? [];
    final nextById = <int, TimeBlock>{};
    for (final block in current) {
      if (block.id == updatedOriginal.id) {
        nextById[block.id] = updatedOriginal;
      } else {
        nextById[block.id] = block;
      }
    }
    nextById[created.id] = created;
    state = AsyncData(nextById.values.toList());
  }
}

final timeBlocksProvider =
    AsyncNotifierProvider<TimeBlocksNotifier, List<TimeBlock>>(
      TimeBlocksNotifier.new,
    );

final timeBlocksForCurrentLocationProvider = Provider<List<TimeBlock>>((ref) {
  final location = ref.watch(currentLocationProvider);
  final blocksAsync = ref.watch(timeBlocksProvider);
  final blocks = blocksAsync.value ?? [];

  return [
    for (final block in blocks)
      if (block.locationId == location.id) block,
  ];
});

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

final timeBlocksForStaffOnDateProvider =
    FutureProvider.family<List<TimeBlock>, ({int staffId, DateTime date})>((
      ref,
      params,
    ) async {
      final authState = ref.watch(authProvider);
      if (!authState.isAuthenticated) {
        return const [];
      }

      final location = ref.watch(currentLocationProvider);
      if (location.id <= 0) {
        return const [];
      }

      final apiClient = ref.watch(apiClientProvider);
      final dayStart = DateUtils.dateOnly(params.date);
      final dayEnd = dayStart.add(const Duration(days: 1));

      String formatDateTime(DateTime dt) {
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
      }

      try {
        final data = await apiClient.getTimeBlocks(
          location.id,
          fromDate: formatDateTime(dayStart),
          toDate: formatDateTime(dayEnd),
        );
        return [
          for (final raw in data)
            if (TimeBlock.fromJson(raw).includesStaff(params.staffId))
              TimeBlock.fromJson(raw),
        ];
      } catch (_) {
        return const [];
      }
    });
