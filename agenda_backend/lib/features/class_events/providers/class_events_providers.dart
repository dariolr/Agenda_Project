import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/models/class_booking.dart';
import '/core/models/class_event.dart';
import '/core/models/class_type.dart';
import '/core/network/network_providers.dart';
import '/core/services/tenant_time_service.dart';
import '../../agenda/providers/business_providers.dart';
import '../../agenda/providers/date_range_provider.dart';
import '../../agenda/providers/location_providers.dart';
import '../../agenda/providers/tenant_time_provider.dart';
import '../data/class_events_repository.dart';

final classEventsRepositoryProvider = Provider<ClassEventsRepository>((ref) {
  return ClassEventsRepository(ref.watch(apiClientProvider));
});

final classEventsRangeProvider = Provider<({DateTime from, DateTime to})>((
  ref,
) {
  final date = ref.watch(agendaDateProvider);
  final timezone = ref.watch(effectiveTenantTimezoneProvider);
  final from = TenantTimeService.assumeTenantLocal(
    DateTime(date.year, date.month, date.day),
    timezone,
  );
  final to = from.add(const Duration(days: 1));
  return (from: from.toUtc(), to: to.toUtc());
});

class SelectedClassTypeIdNotifier extends Notifier<int?> {
  @override
  int? build() {
    // Reset selected class type when switching business.
    ref.watch(currentBusinessIdProvider);
    return null;
  }

  void set(int? classTypeId) => state = classTypeId;

  void clear() => state = null;
}

final selectedClassTypeIdProvider =
    NotifierProvider<SelectedClassTypeIdNotifier, int?>(
      SelectedClassTypeIdNotifier.new,
    );

final classTypesProvider = FutureProvider<List<ClassType>>((ref) async {
  final businessId = ref.watch(currentBusinessIdProvider);
  if (businessId <= 0) return const [];
  final repo = ref.watch(classEventsRepositoryProvider);
  return repo.listClassTypes(businessId: businessId);
});

final classTypesWithInactiveProvider = FutureProvider<List<ClassType>>((
  ref,
) async {
  final businessId = ref.watch(currentBusinessIdProvider);
  if (businessId <= 0) return const [];
  final repo = ref.watch(classEventsRepositoryProvider);
  return repo.listClassTypes(businessId: businessId, includeInactive: true);
});

final classEventsProvider = FutureProvider<List<ClassEvent>>((ref) async {
  final businessId = ref.watch(currentBusinessIdProvider);
  if (businessId <= 0) return const [];
  final range = ref.watch(classEventsRangeProvider);
  final location = ref.watch(currentLocationProvider);
  final classTypeId = ref.watch(selectedClassTypeIdProvider);
  final repo = ref.watch(classEventsRepositoryProvider);
  return repo.listEvents(
    businessId: businessId,
    fromUtc: range.from,
    toUtc: range.to,
    locationId: location.id,
    classTypeId: classTypeId,
  );
});

final upcomingClassEventsByTypeProvider =
    FutureProvider.family<List<ClassEvent>, int>((ref, classTypeId) async {
      final businessId = ref.watch(currentBusinessIdProvider);
      if (businessId <= 0 || classTypeId <= 0) return const [];

      final repo = ref.watch(classEventsRepositoryProvider);
      final timezone = ref.watch(effectiveTenantTimezoneProvider);
      final nowUtc = TenantTimeService.nowInTimezone(timezone).toUtc();
      final fromUtc = nowUtc.subtract(const Duration(days: 1));
      final toUtc = nowUtc.add(const Duration(days: 3650));

      final events = await repo.listEvents(
        businessId: businessId,
        fromUtc: fromUtc,
        toUtc: toUtc,
        classTypeId: classTypeId,
      );

      final upcoming =
          events
              .where(
                (event) =>
                    event.endsAtUtc.isAfter(nowUtc) &&
                    event.status.toUpperCase() != 'CANCELLED',
              )
              .toList()
            ..sort((a, b) => a.startsAtUtc.compareTo(b.startsAtUtc));

      return upcoming;
    });

final allClassEventsByTypeProvider =
    FutureProvider.family<List<ClassEvent>, int>((ref, classTypeId) async {
      final businessId = ref.watch(currentBusinessIdProvider);
      if (businessId <= 0 || classTypeId <= 0) return const [];

      final repo = ref.watch(classEventsRepositoryProvider);
      final timezone = ref.watch(effectiveTenantTimezoneProvider);
      final nowUtc = TenantTimeService.nowInTimezone(timezone).toUtc();
      final fromUtc = nowUtc.subtract(const Duration(days: 3650));
      final toUtc = nowUtc.add(const Duration(days: 3650));

      final events = await repo.listEvents(
        businessId: businessId,
        fromUtc: fromUtc,
        toUtc: toUtc,
        classTypeId: classTypeId,
      );

      final all =
          events
              .where((event) => event.status.toUpperCase() != 'CANCELLED')
              .toList()
            ..sort((a, b) => b.startsAtUtc.compareTo(a.startsAtUtc));

      return all;
    });

final upcomingClassEventsCountByTypeProvider = FutureProvider.family<int, int>((
  ref,
  classTypeId,
) async {
  final upcoming = await ref.watch(
    upcomingClassEventsByTypeProvider(classTypeId).future,
  );
  return upcoming.length;
});

final classEventDetailProvider = FutureProvider.family<ClassEvent, int>((
  ref,
  classEventId,
) async {
  final businessId = ref.watch(currentBusinessIdProvider);
  final repo = ref.watch(classEventsRepositoryProvider);
  return repo.getEvent(businessId: businessId, classEventId: classEventId);
});

final classEventParticipantsProvider =
    FutureProvider.family<List<ClassBooking>, int>((ref, classEventId) async {
      final businessId = ref.watch(currentBusinessIdProvider);
      final repo = ref.watch(classEventsRepositoryProvider);
      return repo.participants(
        businessId: businessId,
        classEventId: classEventId,
      );
    });

class ClassEventBookingController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> book({required int classEventId, int? customerId}) async {
    state = const AsyncLoading();
    final businessId = ref.read(currentBusinessIdProvider);
    final repo = ref.read(classEventsRepositoryProvider);
    try {
      await repo.book(
        businessId: businessId,
        classEventId: classEventId,
        customerId: customerId,
      );
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
    ref.invalidate(classEventsProvider);
    ref.invalidate(classEventDetailProvider(classEventId));
    ref.invalidate(classEventParticipantsProvider(classEventId));
  }

  Future<void> cancel({required int classEventId, int? customerId}) async {
    state = const AsyncLoading();
    final businessId = ref.read(currentBusinessIdProvider);
    final repo = ref.read(classEventsRepositoryProvider);
    try {
      await repo.cancelBooking(
        businessId: businessId,
        classEventId: classEventId,
        customerId: customerId,
      );
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
    ref.invalidate(classEventsProvider);
    ref.invalidate(classEventDetailProvider(classEventId));
    ref.invalidate(classEventParticipantsProvider(classEventId));
  }
}

final classEventBookingControllerProvider =
    AsyncNotifierProvider<ClassEventBookingController, void>(
      ClassEventBookingController.new,
    );

class ClassEventCreateController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<ClassEvent> create({
    required int classTypeId,
    required String startsAtIsoUtc,
    required String endsAtIsoUtc,
    required int locationId,
    required int staffId,
    required int capacityTotal,
  }) async {
    state = const AsyncLoading();
    final businessId = ref.read(currentBusinessIdProvider);
    final repo = ref.read(classEventsRepositoryProvider);

    try {
      final created = await repo.create(
        businessId: businessId,
        payload: {
          'class_type_id': classTypeId,
          'starts_at': startsAtIsoUtc,
          'ends_at': endsAtIsoUtc,
          'location_id': locationId,
          'staff_id': staffId,
          'capacity_total': capacityTotal,
        },
      );
      state = const AsyncData(null);
      ref.invalidate(classEventsProvider);
      return created;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final classEventCreateControllerProvider =
    AsyncNotifierProvider<ClassEventCreateController, void>(
      ClassEventCreateController.new,
    );

class ClassTypeMutationController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<ClassType> create({
    required String name,
    String? description,
    bool isActive = true,
    List<int>? locationIds,
  }) async {
    state = const AsyncLoading();
    final businessId = ref.read(currentBusinessIdProvider);
    final repo = ref.read(classEventsRepositoryProvider);
    try {
      final created = await repo.createClassType(
        businessId: businessId,
        payload: {
          'name': name.trim(),
          'description': description?.trim().isEmpty == true
              ? null
              : description?.trim(),
          'is_active': isActive,
          if (locationIds != null) 'location_ids': locationIds,
        },
      );
      state = const AsyncData(null);
      ref.invalidate(classTypesProvider);
      ref.invalidate(classTypesWithInactiveProvider);
      ref.invalidate(classEventsProvider);
      return created;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<ClassType> updateType({
    required int classTypeId,
    required String name,
    String? description,
    required bool isActive,
    List<int>? locationIds,
  }) async {
    state = const AsyncLoading();
    final businessId = ref.read(currentBusinessIdProvider);
    final repo = ref.read(classEventsRepositoryProvider);
    try {
      final updated = await repo.updateClassType(
        businessId: businessId,
        classTypeId: classTypeId,
        payload: {
          'name': name.trim(),
          'description': description?.trim().isEmpty == true
              ? null
              : description?.trim(),
          'is_active': isActive,
          if (locationIds != null) 'location_ids': locationIds,
        },
      );
      state = const AsyncData(null);
      ref.invalidate(classTypesProvider);
      ref.invalidate(classTypesWithInactiveProvider);
      ref.invalidate(classEventsProvider);
      return updated;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteType({required int classTypeId}) async {
    state = const AsyncLoading();
    final businessId = ref.read(currentBusinessIdProvider);
    final repo = ref.read(classEventsRepositoryProvider);
    try {
      await repo.deleteClassType(
        businessId: businessId,
        classTypeId: classTypeId,
      );
      state = const AsyncData(null);
      ref.invalidate(classTypesProvider);
      ref.invalidate(classTypesWithInactiveProvider);
      ref.invalidate(classEventsProvider);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final classTypeMutationControllerProvider =
    AsyncNotifierProvider<ClassTypeMutationController, void>(
      ClassTypeMutationController.new,
    );
