import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/appointment.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/current_business_user_provider.dart';
import '../../clients/providers/clients_providers.dart';
import '../../services/providers/services_provider.dart';
import 'booking_reschedule_provider.dart';
import 'bookings_provider.dart';
import 'bookings_repository_provider.dart';
import 'business_providers.dart';
import 'date_range_provider.dart';
import 'location_providers.dart';

/// Arrotonda un DateTime ai 5 minuti più vicini.
/// Es: 10:12 → 10:10, 10:13 → 10:15
DateTime _roundToNearestFiveMinutes(DateTime dt) {
  final minutes = dt.minute;
  final roundedMinutes = ((minutes + 2) ~/ 5) * 5;
  return DateTime(
    dt.year,
    dt.month,
    dt.day,
    dt.hour,
    0,
  ).add(Duration(minutes: roundedMinutes));
}

class AppointmentsNotifier extends AsyncNotifier<List<Appointment>> {
  @override
  Future<List<Appointment>> build() async {
    // Verifica autenticazione
    final authState = ref.watch(authProvider);
    if (!authState.isAuthenticated) {
      return [];
    }

    final repository = ref.watch(bookingsRepositoryProvider);
    final location = ref.watch(currentLocationProvider);
    final business = ref.watch(currentBusinessProvider);
    final date = ref.watch(agendaDateProvider);

    if (location.id <= 0) {
      return [];
    }

    // Usa il nuovo metodo che ritorna anche i metadata dei booking (incluse le note)
    final result = await repository.getAppointmentsWithMetadata(
      locationId: location.id,
      businessId: business.id,
      date: date,
    );

    // Popola bookingsProvider con i metadata dei booking (incluse le note)
    final bookingsNotifier = ref.read(bookingsProvider.notifier);
    for (final entry in result.bookingMetadata.entries) {
      final metadata = entry.value;
      bookingsNotifier.ensureBooking(
        bookingId: metadata.id,
        businessId: metadata.businessId,
        locationId: metadata.locationId,
        clientId: metadata.clientId,
        clientName: metadata.clientName ?? '',
        notes: metadata.notes,
        status: metadata.status ?? 'confirmed',
      );
    }

    return result.appointments;
  }

  /// Restituisce gli appointments associati a un booking specifico,
  /// ordinati per orario di inizio.
  List<Appointment> getByBookingId(int bookingId) {
    final currentList = state.value ?? [];
    return currentList.where((a) => a.bookingId == bookingId).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  void moveAppointment({
    required int appointmentId,
    required int newStaffId,
    required DateTime newStart,
    required DateTime newEnd,
  }) async {
    final currentList = state.value;
    if (currentList == null) return;

    // Trova l'appointment originale per calcolare extra blocked
    final originalAppt = currentList.firstWhere(
      (a) => a.id == appointmentId,
      orElse: () => throw Exception('Appointment not found'),
    );

    // Arrotonda gli orari a multipli di 5 minuti
    final roundedStart = _roundToNearestFiveMinutes(newStart);
    final duration = newEnd.difference(newStart);
    final roundedEnd = roundedStart.add(duration);

    // Calcola extra blocked minutes
    final oldTotalMinutes = originalAppt.endTime
        .difference(originalAppt.startTime)
        .inMinutes;
    final newTotalMinutes = roundedEnd.difference(roundedStart).inMinutes;
    final oldBlocked = originalAppt.blockedExtraMinutes;
    final baseMinutes = oldTotalMinutes - oldBlocked;

    int newBlocked = oldBlocked;
    if (newTotalMinutes <= baseMinutes) {
      newBlocked = 0;
    } else {
      newBlocked = newTotalMinutes - baseMinutes;
    }

    final newList = [
      for (final appt in currentList)
        if (appt.id == appointmentId)
          _applyResizeToAppointment(
            appt,
            staffId: newStaffId,
            startTime: roundedStart,
            endTime: roundedEnd,
          )
        else
          appt,
    ];

    state = AsyncData(newList);

    // API update: chiama l'API per reschedule appointment
    final location = ref.read(currentLocationProvider);
    final repository = ref.read(bookingsRepositoryProvider);

    try {
      await repository.updateAppointment(
        locationId: location.id,
        appointmentId: appointmentId,
        startTime: roundedStart,
        endTime: roundedEnd,
        staffId: newStaffId,
        extraBlockedMinutes: newBlocked,
      );
    } catch (_) {
      // Rollback on error
      state = AsyncData(currentList);
    }
  }

  Future<bool> moveBookingByAnchor({
    required BookingRescheduleSession session,
    required DateTime targetStart,
    required int targetStaffId,
  }) async {
    if (session.items.isEmpty) return false;
    final currentList = state.value;

    final anchor = session.items.firstWhere(
      (i) => i.appointmentId == session.anchorAppointmentId,
      orElse: () => session.items.first,
    );
    final delta = targetStart.difference(anchor.startTime);

    final updates = <int, ({Appointment appointment, int blockedMinutes})>{};
    final updatedStarts = <int, DateTime>{};
    final updatedEnds = <int, DateTime>{};
    final updatedStaffIds = <int, int>{};
    final updatedBlocked = <int, int>{};

    for (final item in session.items) {
      final rawStart = item.startTime.add(delta);
      final rawEnd = item.endTime.add(delta);

      final roundedStart = _roundToNearestFiveMinutes(rawStart);
      final duration = rawEnd.difference(rawStart);
      final roundedEnd = roundedStart.add(duration);

      final oldTotalMinutes = item.endTime.difference(item.startTime).inMinutes;
      final newTotalMinutes = roundedEnd.difference(roundedStart).inMinutes;
      final oldBlocked = item.blockedExtraMinutes;
      final baseMinutes = oldTotalMinutes - oldBlocked;

      int newBlocked = oldBlocked;
      if (newTotalMinutes <= baseMinutes) {
        newBlocked = 0;
      } else {
        newBlocked = newTotalMinutes - baseMinutes;
      }

      final newStaffId = item.appointmentId == anchor.appointmentId
          ? targetStaffId
          : item.staffId;

      updatedStarts[item.appointmentId] = roundedStart;
      updatedEnds[item.appointmentId] = roundedEnd;
      updatedStaffIds[item.appointmentId] = newStaffId;
      updatedBlocked[item.appointmentId] = newBlocked;
    }

    if (currentList != null) {
      for (final appt in currentList) {
        if (!updatedStarts.containsKey(appt.id)) continue;
        updates[appt.id] = (
          appointment: _applyResizeToAppointment(
            appt,
            staffId: updatedStaffIds[appt.id]!,
            startTime: updatedStarts[appt.id]!,
            endTime: updatedEnds[appt.id]!,
          ),
          blockedMinutes: updatedBlocked[appt.id]!,
        );
      }

      final optimistic = [
        for (final appt in currentList)
          if (updates.containsKey(appt.id)) updates[appt.id]!.appointment else appt,
      ];
      state = AsyncData(optimistic);
    }

    final location = ref.read(currentLocationProvider);
    final repository = ref.read(bookingsRepositoryProvider);

    try {
      for (final item in session.items) {
        await repository.updateAppointment(
          locationId: location.id,
          appointmentId: item.appointmentId,
          startTime: updatedStarts[item.appointmentId],
          endTime: updatedEnds[item.appointmentId],
          staffId: updatedStaffIds[item.appointmentId],
          extraBlockedMinutes: updatedBlocked[item.appointmentId],
        );
      }
      ref.invalidateSelf();
      return true;
    } catch (_) {
      if (currentList != null) {
        state = AsyncData(currentList);
      }
      return false;
    }
  }

  Appointment _applyResizeToAppointment(
    Appointment appt, {
    required int staffId,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    final oldTotalMinutes = appt.endTime.difference(appt.startTime).inMinutes;
    final newTotalMinutes = endTime.difference(startTime).inMinutes;
    final oldBlocked = appt.blockedExtraMinutes;
    final baseMinutes = oldTotalMinutes - oldBlocked;

    int newBlocked = oldBlocked;
    if (newTotalMinutes <= baseMinutes) {
      newBlocked = 0;
    } else {
      newBlocked = newTotalMinutes - baseMinutes;
    }

    final processingMinutes = appt.processingExtraMinutes;
    final extraMinutesType = newBlocked > 0
        ? ExtraMinutesType.blocked
        : (processingMinutes > 0 ? ExtraMinutesType.processing : null);
    final extraMinutes = extraMinutesType == ExtraMinutesType.blocked
        ? newBlocked
        : (extraMinutesType == ExtraMinutesType.processing
              ? processingMinutes
              : null);

    return appt.copyWith(
      staffId: staffId,
      startTime: startTime,
      endTime: endTime,
      extraMinutes: extraMinutes,
      extraMinutesType: extraMinutesType,
      extraBlockedMinutes: newBlocked,
      extraProcessingMinutes: processingMinutes,
    );
  }

  /// Elimina un singolo appuntamento (booking_item).
  /// Usa deleteBookingItem per eliminare solo l'item, non l'intero booking.
  void deleteAppointment(int appointmentId) async {
    final currentList = state.value;
    if (currentList == null) return;

    int? relatedBookingId;
    for (final appt in currentList) {
      if (appt.id == appointmentId) {
        relatedBookingId = appt.bookingId;
        break;
      }
    }

    // Se non troviamo il booking, non possiamo eliminare
    if (relatedBookingId == null) {
      return;
    }

    final newList = [
      for (final appt in currentList)
        if (appt.id != appointmentId) appt,
    ];

    state = AsyncData(newList);

    // Aggiorna lo stato locale dei bookings se vuoto
    ref.read(bookingsProvider.notifier).removeIfEmpty(relatedBookingId);

    // API delete: elimina il singolo booking_item
    final repository = ref.read(bookingsRepositoryProvider);

    try {
      await repository.deleteBookingItem(
        bookingId: relatedBookingId,
        itemId: appointmentId,
      );
    } catch (_) {
      // Rollback on error
      state = AsyncData(currentList);
    }
  }

  /// Aggiunge un nuovo appuntamento chiamando l'API
  /// Se bookingId è fornito, aggiunge un item a un booking esistente
  /// Altrimenti crea un nuovo booking
  Future<Appointment?> addAppointment({
    int? bookingId,
    required int staffId,
    required int serviceId,
    required int serviceVariantId,
    int? clientId,
    required String clientName,
    required String serviceName,
    required DateTime start,
    required DateTime end,
    double? price,
    int? extraMinutes,
    ExtraMinutesType? extraMinutesType,
    int? extraBlockedMinutes,
    int? extraProcessingMinutes,
  }) async {
    final location = ref.read(currentLocationProvider);
    final repository = ref.read(bookingsRepositoryProvider);

    // Arrotonda gli orari a multipli di 5 minuti
    final roundedStart = _roundToNearestFiveMinutes(start);
    final duration = end.difference(start);
    final roundedEnd = roundedStart.add(duration);

    try {
      // Se bookingId è fornito, aggiungi un item al booking esistente
      if (bookingId != null) {
        final created = await repository.addBookingItem(
          bookingId: bookingId,
          businessId: location.businessId,
          locationId: location.id,
          staffId: staffId,
          serviceId: serviceId,
          serviceVariantId: serviceVariantId,
          startTime: roundedStart,
          endTime: roundedEnd,
          serviceNameSnapshot: serviceName,
          clientNameSnapshot: clientName,
          price: price,
          extraBlockedMinutes: extraBlockedMinutes,
          extraProcessingMinutes: extraProcessingMinutes,
        );

        // Aggiorna lo state locale con il nuovo appuntamento
        final currentList = state.value ?? [];
        state = AsyncData([...currentList, created]);

        return created;
      }

      // Altrimenti crea un nuovo booking
      final bookingResponse = await repository.createBooking(
        locationId: location.id,
        idempotencyKey: const Uuid().v4(),
        serviceIds: [serviceId],
        startTime: roundedStart.toIso8601String(),
        staffId: staffId,
        clientId: clientId,
        notes: null,
      );

      // Refresh state to get the new appointment with correct ID
      ref.invalidateSelf();
      await future; // Wait for refresh

      // Try to find the newly created appointment
      // Since we don't know the ID, we can look for one that matches the bookingId from response
      final currentList = state.value ?? [];
      final created = currentList.firstWhere(
        (a) => a.bookingId == bookingResponse.id,
        orElse: () => throw Exception('Appointment not found after creation'),
      );

      // Ensure booking metadata exists locally (if needed, but API should handle it)
      ref
          .read(bookingsProvider.notifier)
          .ensureBooking(
            bookingId: bookingResponse.id,
            businessId: bookingResponse.businessId,
            locationId: bookingResponse.locationId,
            clientId: bookingResponse.clientId,
            clientName: bookingResponse.clientName ?? clientName,
            notes: bookingResponse.notes,
            status: bookingResponse.status,
            replacesBookingId: bookingResponse.replacesBookingId,
            replacedByBookingId: bookingResponse.replacedByBookingId,
          );

      return created;
    } catch (_) {
      return null;
    }
  }

  /// Aggiorna un appuntamento esistente (match per id)
  Future<void> updateAppointment(Appointment updated) async {
    final currentList = state.value;
    if (currentList == null) return;

    // Arrotonda gli orari a multipli di 5 minuti
    final roundedStart = _roundToNearestFiveMinutes(updated.startTime);
    final duration = updated.endTime.difference(updated.startTime);
    final roundedEnd = roundedStart.add(duration);
    final roundedAppointment = updated.copyWith(
      startTime: roundedStart,
      endTime: roundedEnd,
    );

    final newList = [
      for (final appt in currentList)
        if (appt.id == updated.id) roundedAppointment else appt,
    ];

    state = AsyncData(newList);

    // API update: chiama l'API per reschedule appointment
    final location = ref.read(currentLocationProvider);
    final repository = ref.read(bookingsRepositoryProvider);

    try {
      await repository.updateAppointment(
        locationId: location.id,
        appointmentId: updated.id,
        startTime: roundedStart,
        endTime: roundedEnd,
        staffId: updated.staffId,
        serviceId: updated.serviceId,
        serviceVariantId: updated.serviceVariantId,
        serviceNameSnapshot: updated.serviceName,
        clientId: updated.clientId,
        clientName: updated.clientName,
        clientNameSnapshot: updated.clientName,
        extraBlockedMinutes: updated.extraBlockedMinutes,
        extraProcessingMinutes: updated.extraProcessingMinutes,
        price: updated.price,
        priceExplicitlySet: true,
      );
    } catch (_) {
      // Rollback on error
      state = AsyncData(currentList);
    }
  }

  /// Aggiorna il cliente di tutti gli appuntamenti di una prenotazione.
  /// Chiama l'API per persistere la modifica del client_id nel booking.
  Future<void> updateClientForBooking({
    required int bookingId,
    required int? clientId,
    required String clientName,
  }) async {
    final currentList = state.value;
    if (currentList == null) return;

    // Aggiornamento locale immediato per la UI
    final newList = [
      for (final appt in currentList)
        if (appt.bookingId == bookingId)
          appt.copyWith(clientId: clientId, clientName: clientName)
        else
          appt,
    ];

    state = AsyncData(newList);

    // Chiama API per persistere la modifica
    try {
      final repository = ref.read(bookingsRepositoryProvider);
      final location = ref.read(currentLocationProvider);

      await repository.updateBooking(
        locationId: location.id,
        bookingId: bookingId,
        clientId: clientId,
        clearClient: clientId == null, // Se null, rimuovi il cliente
      );

      // Aggiorna anche il booking locale
      ref
          .read(bookingsProvider.notifier)
          .updateClientForBooking(
            bookingId: bookingId,
            clientId: clientId,
            clientName: clientName,
          );
    } catch (e) {
      // Rollback: ripristina lo stato precedente
      state = AsyncData(currentList);
      rethrow; // Propaga l'errore per gestirlo nella UI
    }
  }

  /// Aggiorna localmente lo stato booking per tutti gli appuntamenti della prenotazione.
  void setBookingStatusForBooking({
    required int bookingId,
    required String status,
  }) {
    final currentList = state.value;
    if (currentList == null) return;

    state = AsyncData([
      for (final appt in currentList)
        if (appt.bookingId == bookingId)
          appt.copyWith(bookingStatus: status)
        else
          appt,
    ]);
  }

  /// Duplica un appuntamento
  Future<Appointment?> duplicateAppointment(
    Appointment original, {
    bool intoSameBooking = true,
  }) async {
    // If intoSameBooking is true, we should add to existing booking.
    // But createBooking creates a NEW booking.
    // The API doesn't seem to support adding item to existing booking yet (store endpoint creates booking).
    // So we can only support creating new booking for now.

    if (intoSameBooking) {
      // Not supported by API yet (need add item to booking endpoint)
      // Fallback to creating new booking or show error?
      // For now, let's create a new booking anyway but maybe warn?
      // Or just implement local duplication if we want to keep UI working without persistence

      // Let's try to create a new booking for now as duplication usually implies new slot
      return addAppointment(
        staffId: original.staffId,
        serviceId: original.serviceId,
        serviceVariantId: original.serviceVariantId,
        clientId: original.clientId,
        clientName: original.clientName,
        serviceName: original.serviceName,
        start: original.startTime, // Should probably be shifted?
        end: original.endTime,
      );
    } else {
      return addAppointment(
        staffId: original.staffId,
        serviceId: original.serviceId,
        serviceVariantId: original.serviceVariantId,
        clientId: original.clientId,
        clientName: original.clientName,
        serviceName: original.serviceName,
        start: original.startTime,
        end: original.endTime,
      );
    }
  }

  /// Cancella tutti gli appuntamenti appartenenti a una prenotazione.
  Future<void> deleteByBooking(int bookingId) async {
    final currentList = state.value;
    if (currentList == null) return;

    final location = ref.read(currentLocationProvider);
    final repository = ref.read(bookingsRepositoryProvider);
    final bookingsNotifier = ref.read(bookingsProvider.notifier);

    try {
      // Associa esplicitamente lo stato "cancelled" prima della cancellazione
      // definitiva della prenotazione.
      await repository.updateBooking(
        locationId: location.id,
        bookingId: bookingId,
        status: 'cancelled',
      );
      bookingsNotifier.setStatus(bookingId, 'cancelled');
      setBookingStatusForBooking(bookingId: bookingId, status: 'cancelled');

      // Chiama API per cancellare il booking
      await repository.deleteBooking(
        locationId: location.id,
        bookingId: bookingId,
      );

      // Aggiorna lo stato locale
      final newList = [
        for (final appt in currentList)
          if (appt.bookingId != bookingId) appt,
      ];

      state = AsyncData(newList);
    } catch (_) {
      // In caso di errore, mantieni lo stato corrente
    }
  }

  /// Crea rapidamente una prenotazione per un client
  Future<Appointment?> createQuickBookingForClient(int clientId) async {
    final clientsById = ref.read(clientsByIdProvider);
    final client = clientsById[clientId];
    if (client == null) return null;

    final agendaDate = ref.read(agendaDateProvider);
    final variants = ref.read(serviceVariantsProvider).value ?? [];
    if (variants.isEmpty) return null;
    final variant = variants.first;

    // Staff idoneo per il servizio e sede corrente
    final eligibleStaff = ref.read(
      eligibleStaffForServiceProvider(variant.serviceId),
    );
    if (eligibleStaff.isEmpty) return null;
    final staffId = eligibleStaff.first;

    // Orario: prossimo quarto d'ora oggi alle max 18:00
    final now = DateTime.now();
    final dayStart = DateUtils.dateOnly(agendaDate);
    DateTime base = now.isBefore(dayStart) ? dayStart : now;
    // clamp to today end
    final dayEnd = dayStart.add(const Duration(days: 1));
    if (base.isAfter(dayEnd)) base = dayStart.add(const Duration(hours: 10));
    final minutes = base.minute;
    final rounded = minutes % 15 == 0
        ? base
        : base.add(Duration(minutes: 15 - (minutes % 15)));
    final start = DateTime(
      dayStart.year,
      dayStart.month,
      dayStart.day,
      rounded.hour,
      rounded.minute,
    );
    final end = start.add(Duration(minutes: variant.durationMinutes));

    return addAppointment(
      staffId: staffId,
      serviceId: variant.serviceId,
      serviceVariantId: variant.id,
      clientId: client.id,
      clientName: client.name,
      serviceName: '',
      start: start,
      end: end,
      price: variant.price,
    );
  }
}

final appointmentsProvider =
    AsyncNotifierProvider<AppointmentsNotifier, List<Appointment>>(
      AppointmentsNotifier.new,
    );

final appointmentsForCurrentLocationProvider = Provider<List<Appointment>>((
  ref,
) {
  final location = ref.watch(currentLocationProvider);
  final currentDate = ref.watch(agendaDateProvider);
  final dayStart = DateUtils.dateOnly(currentDate);
  final dayEnd = dayStart.add(const Duration(days: 1));
  final appointmentsAsync = ref.watch(appointmentsProvider);
  final appointments = appointmentsAsync.value ?? [];

  // Filtro per ruolo: staff vede solo i propri appuntamenti
  final canViewAll = ref.watch(canViewAllAppointmentsProvider);
  final currentUserStaffId = ref.watch(currentUserStaffIdProvider);

  return [
    for (final appt in appointments)
      if (appt.locationId == location.id &&
          !appt.endTime.isBefore(dayStart) &&
          appt.startTime.isBefore(dayEnd) &&
          // Se può vedere tutto, mostra. Altrimenti solo i propri
          (canViewAll ||
              currentUserStaffId == null ||
              appt.staffId == currentUserStaffId))
        appt,
  ];
});
