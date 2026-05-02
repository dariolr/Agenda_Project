import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/models/class_event.dart';
import 'booking_direct_link_provider.dart';
import 'booking_provider.dart';
import 'locations_provider.dart';
import 'my_bookings_provider.dart';

/// Notifier per gli eventi di classe pubblici della location corrente.
/// Carica una volta per location e si aggiorna se la location cambia.
class ClassEventsNotifier extends StateNotifier<AsyncValue<List<ClassEvent>>> {
  final Ref _ref;
  bool _hasFetched = false;
  int? _lastLocationId;
  String? _lastLinkSlug;

  ClassEventsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _ref.listen(effectiveLocationIdProvider, (previous, next) {
      if (next > 0 && next != _lastLocationId) {
        _hasFetched = false;
        _lastLocationId = next;
        _loadData();
      }
    }, fireImmediately: true);
    _ref.listen(bookingDirectLinkSlugProvider, (previous, next) {
      if (next != _lastLinkSlug) {
        _hasFetched = false;
        _lastLinkSlug = next;
        state = const AsyncValue.loading();
        _loadData();
      }
    }, fireImmediately: true);
  }

  Future<void> _loadData() async {
    if (_hasFetched) return;

    if (_ref.read(bookingDirectLinkBlockingErrorProvider)) return;

    final locationId = _ref.read(effectiveLocationIdProvider);
    final linkSlug = _ref.read(bookingDirectLinkSlugProvider);
    if (locationId <= 0) return;

    if (linkSlug != null) {
      final directLinkAsync = _ref.read(bookingDirectLinkProvider);
      if (directLinkAsync.value == null) {
        return;
      }
    }

    _hasFetched = true;

    try {
      final repository = _ref.read(bookingRepositoryProvider);
      final events = await repository.getClassEvents(
        locationId,
        linkSlug: linkSlug,
      );
      state = AsyncValue.data(events);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    _hasFetched = false;
    state = const AsyncValue.loading();
    await _loadData();
  }
}

final classEventsProvider =
    StateNotifierProvider<ClassEventsNotifier, AsyncValue<List<ClassEvent>>>(
      (ref) => ClassEventsNotifier(ref),
    );

/// Filtra gli eventi applicando i vincoli di prenotazione della location:
/// - bookingOpenAt / bookingCloseAt
/// - maxBookingAdvanceDays
/// Usa locationNowProvider per coerenza con il fuso orario della sede.
final filteredClassEventsProvider = Provider<AsyncValue<List<ClassEvent>>>((
  ref,
) {
  final eventsAsync = ref.watch(classEventsProvider);
  final now = ref.watch(locationNowProvider);
  final maxDays = ref.watch(maxBookingAdvanceDaysProvider);
  return eventsAsync.whenData(
    (events) => events
        .where(
          (e) =>
              e.isBookingOpenAt(now) &&
              e.isWithinAdvanceBookingWindow(now, maxDays),
        )
        .toList(),
  );
});

/// Mappa eventId → status ('confirmed' | 'waitlisted') per le prenotazioni
/// attive dell'utente. Usato per impedire doppie prenotazioni e mostrare
/// lo stato corrente sul tile dell'evento.
final bookedClassEventStatusProvider = Provider<Map<int, String>>((ref) {
  final bookings = ref.watch(myBookingsProvider);
  return {
    for (final b in bookings.upcomingClass)
      if (b.isConfirmed || b.isWaitlisted) b.classEventId: b.status,
  };
});

/// True quando esistono solo eventi prenotabili (nessun servizio/pacchetto).
final isEventOnlyModeProvider = Provider<bool>((ref) {
  final classEvents = ref.watch(filteredClassEventsProvider).value ?? [];
  final servicesData = ref.watch(servicesDataProvider).value;
  final packages = ref.watch(servicePackagesProvider).value ?? [];
  final hasClassEvents = classEvents.isNotEmpty;
  final hasServices =
      (servicesData?.bookableServices.isNotEmpty ?? false) ||
      packages.isNotEmpty;
  return hasClassEvents && !hasServices;
});

/// True quando esistono sia servizi che eventi prenotabili.
final hasBothServicesAndEventsProvider = Provider<bool>((ref) {
  final classEvents = ref.watch(filteredClassEventsProvider).value ?? [];
  final servicesData = ref.watch(servicesDataProvider).value;
  final packages = ref.watch(servicePackagesProvider).value ?? [];
  final hasClassEvents = classEvents.isNotEmpty;
  final hasServices =
      (servicesData?.bookableServices.isNotEmpty ?? false) ||
      packages.isNotEmpty;
  return hasClassEvents && hasServices;
});
