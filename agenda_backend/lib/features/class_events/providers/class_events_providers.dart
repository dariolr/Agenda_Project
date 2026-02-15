import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/models/class_booking.dart';
import '/core/models/class_event.dart';
import '/core/network/network_providers.dart';
import '../../agenda/providers/business_providers.dart';
import '../../agenda/providers/date_range_provider.dart';
import '../data/class_events_repository.dart';

final classEventsRepositoryProvider = Provider<ClassEventsRepository>((ref) {
  return ClassEventsRepository(ref.watch(apiClientProvider));
});

final classEventsRangeProvider = Provider<({DateTime from, DateTime to})>((ref) {
  final date = ref.watch(agendaDateProvider);
  final from = DateTime(date.year, date.month, date.day);
  final to = from.add(const Duration(days: 1));
  return (from: from.toUtc(), to: to.toUtc());
});

final classEventsProvider = FutureProvider<List<ClassEvent>>((ref) async {
  final businessId = ref.watch(currentBusinessIdProvider);
  if (businessId <= 0) return const [];
  final range = ref.watch(classEventsRangeProvider);
  final repo = ref.watch(classEventsRepositoryProvider);
  return repo.listEvents(
    businessId: businessId,
    fromUtc: range.from,
    toUtc: range.to,
  );
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
      return repo.participants(businessId: businessId, classEventId: classEventId);
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
