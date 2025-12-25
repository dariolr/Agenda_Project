import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/appointment.dart';
import '../../clients/providers/clients_providers.dart';
import '../../services/providers/services_provider.dart';
import 'bookings_provider.dart';
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

class AppointmentsNotifier extends Notifier<List<Appointment>> {
  bool _initialized = false;

  @override
  List<Appointment> build() {
    if (!_initialized) {
      _initialized = true;
      state = _mockAppointments();
    }
    return state;
  }

  List<Appointment> _mockAppointments() {
    final business = ref.read(currentBusinessProvider);
    final location = ref.read(currentLocationProvider);

    final now = DateTime.now();
    // Arrotonda l'orario corrente ai 5 minuti più vicini
    final roundedMinute = ((now.minute + 2) ~/ 5) * 5;
    final start = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      0,
    ).add(Duration(minutes: roundedMinute));
    final end = start.add(const Duration(minutes: 30));
    final endWithBlocked = end.add(const Duration(minutes: 10));

    return [
      Appointment(
        id: 1,
        bookingId: 100000,
        businessId: business.id,
        locationId: location.id,
        staffId: 1,
        serviceId: 1,
        serviceVariantId: 900001,
        clientId: 1,
        clientName: 'Mario Rossi',
        serviceName: 'Massaggio Relax',
        startTime: start,
        endTime: endWithBlocked,
        price: 45,
        extraMinutes: 10,
        extraMinutesType: ExtraMinutesType.blocked,
      ),
      Appointment(
        id: 2,
        bookingId: 100001,
        businessId: business.id,
        locationId: location.id,
        staffId: 4,
        serviceId: 2,
        serviceVariantId: 900002,
        clientId: 2,
        clientName: 'Giulia Bianchi',
        serviceName: 'Massaggio Sportivo',
        startTime: start.add(const Duration(hours: 3)),
        endTime: start.add(const Duration(hours: 3, minutes: 45)),
        price: 62,
        extraMinutes: 0,
        extraMinutesType: null,
      ),
      Appointment(
        id: 3,
        bookingId: 100002,
        businessId: business.id,
        locationId: location.id,
        staffId: 1,
        serviceId: 3,
        serviceVariantId: 900003,
        clientId: 3,
        clientName: 'Luca Verdi',
        serviceName: 'Trattamento Viso',
        startTime: start.add(const Duration(hours: 4)),
        endTime: start.add(const Duration(hours: 4, minutes: 40)),
        price: 55,
        extraMinutes: 0,
        extraMinutesType: null,
      ),
      Appointment(
        id: 4,
        bookingId: 100003,
        businessId: business.id,
        locationId: location.id,
        staffId: 2,
        serviceId: 4,
        serviceVariantId: 900004,
        clientId: 4,
        clientName: 'Sara Neri',
        serviceName: 'Trattamenti Corpo 2',
        startTime: start.add(const Duration(hours: 5)),
        endTime: start.add(const Duration(hours: 5, minutes: 30)),
        price: 50,
        extraMinutes: 10,
        extraMinutesType: ExtraMinutesType.processing,
      ),
      Appointment(
        id: 5,
        bookingId: 100004,
        businessId: business.id,
        locationId: location.id,
        staffId: 1,
        serviceId: 4,
        serviceVariantId: 900004,
        clientId: 5,
        clientName: 'Paolo Ricci',
        serviceName: 'Trattamenti Corpo 2',
        startTime: start.add(const Duration(hours: 1)),
        endTime: start.add(const Duration(hours: 1, minutes: 30)),
        price: 50,
        extraMinutes: 10,
        extraMinutesType: ExtraMinutesType.processing,
      ),
    ];
  }

  /*
  List<Appointment> _mockAppointments() {
    final business = ref.read(currentBusinessProvider);

    const seeds = [
      _StaffScheduleSeed(
        staffId: 1,
        locationIds: [101],
        serviceId: 1,
        serviceVariantId: 900001,
        serviceName: 'Massaggio Relax',
        basePrice: 45,
      ),
      _StaffScheduleSeed(
        staffId: 2,
        locationIds: [102],
        serviceId: 1,
        serviceVariantId: 900001,
        serviceName: 'Trattamento Viso',
        basePrice: 48,
      ),
      _StaffScheduleSeed(
        staffId: 3,
        locationIds: [101, 102],
        serviceId: 2,
        serviceVariantId: 900002,
        serviceName: 'Massaggio Sportivo',
        basePrice: 60,
      ),
      _StaffScheduleSeed(
        staffId: 4,
        locationIds: [101],
        serviceId: 3,
        serviceVariantId: 900003,
        serviceName: 'Hair Styling',
        basePrice: 50,
      ),
      _StaffScheduleSeed(
        staffId: 2,
        locationIds: [102],
        serviceId: 4,
        serviceVariantId: 900004,
        serviceName: 'Taglio & Barba',
        basePrice: 42,
      ),
    ];

    final random = Random(202511);
    const int slotsPerDay = 8;
    final startDate = DateTime(2025, 11, 1);
    const int totalDays = 30;

    final appointments = <Appointment>[];
    var appointmentId = 1;
    var bookingId = 100000;

    for (int dayOffset = 0; dayOffset < totalDays; dayOffset++) {
      final dayDate = startDate.add(Duration(days: dayOffset));
      for (final seed in seeds) {
        final locationIds = seed.locationIds;
        final locationId = locationIds.length == 1
            ? locationIds.first
            : locationIds[dayOffset % locationIds.length];

        int generated = 0;
        while (generated < slotsPerDay) {
          final startMinute =
              8 * 60 + random.nextInt(10 * 60); // tra 08:00 e 18:00
          final roundedStartMinute = (startMinute / 5).round() * 5;
          final durationMinutes = 15 * (1 + random.nextInt(8)); // 15-120
          final start = dayDate.add(Duration(minutes: roundedStartMinute));
          final end = start.add(Duration(minutes: durationMinutes));

          final currentBookingId = bookingId++;
          final clientId = (generated % 3) + 1; // associa mock clientId ciclico
          final clientBaseName =
              'Cliente ${seed.staffId}-${dayDate.day}-${generated + 1}';

          appointments.add(
            Appointment(
              id: appointmentId++,
              bookingId: currentBookingId,
              businessId: business.id,
              locationId: locationId,
              staffId: seed.staffId,
              serviceId: seed.serviceId,
              serviceVariantId: seed.serviceVariantId,
              clientId: clientId,
              clientName: clientBaseName,
              serviceName: seed.serviceName,
              startTime: start,
              endTime: end,
              price: seed.basePrice + generated,
            ),
          );
          generated++;

          final bool createPair =
              generated < slotsPerDay && random.nextDouble() < 0.3;
          if (createPair) {
            final separationMinutes = 15 * random.nextInt(3); // 0,15,30
            final secondStart = end.add(Duration(minutes: separationMinutes));
            final secondDurationMinutes =
                15 * (1 + random.nextInt(8)); // 15-120 minuti
            final secondEnd = secondStart.add(
              Duration(minutes: secondDurationMinutes),
            );

            final clientId2 = ((generated + 1) % 3) + 1;
            appointments.add(
              Appointment(
                id: appointmentId++,
                bookingId: currentBookingId,
                businessId: business.id,
                locationId: locationId,
                staffId: seed.staffId,
                serviceId: seed.serviceId,
                serviceVariantId: seed.serviceVariantId,
                clientId: clientId2,
                clientName: clientBaseName,
                serviceName: '${seed.serviceName} (Follow-up)',
                startTime: secondStart,
                endTime: secondEnd,
                price: seed.basePrice + generated,
              ),
            );
            generated++;
          }
        }
      }
    }

    return appointments;
  }
*/

  /// Restituisce gli appointments associati a un booking specifico,
  /// ordinati per orario di inizio.
  List<Appointment> getByBookingId(int bookingId) {
    return state.where((a) => a.bookingId == bookingId).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  void moveAppointment({
    required int appointmentId,
    required int newStaffId,
    required DateTime newStart,
    required DateTime newEnd,
  }) async {
    // Arrotonda gli orari a multipli di 5 minuti
    final roundedStart = _roundToNearestFiveMinutes(newStart);
    final duration = newEnd.difference(newStart);
    final roundedEnd = roundedStart.add(duration);

    state = [
      for (final appt in state)
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
    await Future.delayed(Duration.zero);
  }

  Appointment _applyResizeToAppointment(
    Appointment appt, {
    required int staffId,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    final oldTotalMinutes = appt.endTime.difference(appt.startTime).inMinutes;
    final newTotalMinutes = endTime.difference(startTime).inMinutes;
    final oldExtra = appt.extraMinutes ?? 0;
    final hasExtra = appt.extraMinutesType != null && oldExtra > 0;
    final isBlockedExtra = appt.extraMinutesType == ExtraMinutesType.blocked;
    final baseMinutes =
        hasExtra && isBlockedExtra ? (oldTotalMinutes - oldExtra) : oldTotalMinutes;

    int newExtra = oldExtra;
    ExtraMinutesType? newExtraType = appt.extraMinutesType;

    if (hasExtra && isBlockedExtra) {
      if (newTotalMinutes <= baseMinutes) {
        newExtra = 0;
        newExtraType = null;
      } else {
        newExtra = newTotalMinutes - baseMinutes;
      }
    }

    return appt.copyWith(
      staffId: staffId,
      startTime: startTime,
      endTime: endTime,
      extraMinutes: newExtra,
      extraMinutesType: newExtraType,
    );
  }

  void deleteAppointment(int appointmentId) {
    int? relatedBookingId;
    for (final appt in state) {
      if (appt.id == appointmentId) {
        relatedBookingId = appt.bookingId;
        break;
      }
    }

    state = [
      for (final appt in state)
        if (appt.id != appointmentId) appt,
    ];

    if (relatedBookingId != null) {
      ref.read(bookingsProvider.notifier).removeIfEmpty(relatedBookingId);
    }
  }

  /// Aggiunge un nuovo appuntamento generando id e bookingId
  Appointment addAppointment({
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
  }) {
    final business = ref.read(currentBusinessProvider);
    final location = ref.read(currentLocationProvider);

    // Arrotonda gli orari a multipli di 5 minuti
    final roundedStart = _roundToNearestFiveMinutes(start);
    final duration = end.difference(start);
    final roundedEnd = roundedStart.add(duration);

    final nextId = state.isEmpty
        ? 1
        : state.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
    final nextBookingId =
        bookingId ??
        (state.isEmpty
            ? 100000
            : state.map((e) => e.bookingId).reduce((a, b) => a > b ? a : b) +
                  1);

    final appt = Appointment(
      id: nextId,
      bookingId: nextBookingId,
      businessId: business.id,
      locationId: location.id,
      staffId: staffId,
      serviceId: serviceId,
      serviceVariantId: serviceVariantId,
      clientId: clientId,
      clientName: clientName,
      serviceName: serviceName,
      startTime: roundedStart,
      endTime: roundedEnd,
      price: price,
      extraMinutes: extraMinutes,
      extraMinutesType: extraMinutesType,
    );

    state = [...state, appt];
    // ensure booking metadata exists
    ref
        .read(bookingsProvider.notifier)
        .ensureBooking(
          bookingId: nextBookingId,
          businessId: business.id,
          locationId: location.id,
          clientId: clientId,
          customerName: clientName,
        );
    return appt;
  }

  /// Aggiorna un appuntamento esistente (match per id)
  void updateAppointment(Appointment updated) {
    // Arrotonda gli orari a multipli di 5 minuti
    final roundedStart = _roundToNearestFiveMinutes(updated.startTime);
    final duration = updated.endTime.difference(updated.startTime);
    final roundedEnd = roundedStart.add(duration);
    final roundedAppointment = updated.copyWith(
      startTime: roundedStart,
      endTime: roundedEnd,
    );

    state = [
      for (final appt in state)
        if (appt.id == updated.id) roundedAppointment else appt,
    ];
  }

  /// Aggiorna il cliente di tutti gli appuntamenti di una prenotazione.
  void updateClientForBooking({
    required int bookingId,
    required int? clientId,
    required String clientName,
  }) {
    state = [
      for (final appt in state)
        if (appt.bookingId == bookingId)
          appt.copyWith(clientId: clientId, clientName: clientName)
        else
          appt,
    ];
  }

  /// Duplica un appuntamento assegnando un nuovo id e bookingId
  Appointment duplicateAppointment(
    Appointment original, {
    bool intoSameBooking = true,
  }) {
    final nextId = state.isEmpty
        ? 1
        : state.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
    final nextBookingId = intoSameBooking
        ? original.bookingId
        : (state.isEmpty
              ? 100000
              : state.map((e) => e.bookingId).reduce((a, b) => a > b ? a : b) +
                    1);

    final copy = original.copyWith(
      id: nextId,
      bookingId: nextBookingId,
      clientName: original.clientName,
      serviceName: original.serviceName,
    );
    state = [...state, copy];

    if (!intoSameBooking) {
      ref
          .read(bookingsProvider.notifier)
          .ensureBooking(
            bookingId: nextBookingId,
            businessId: original.businessId,
            locationId: original.locationId,
            clientId: original.clientId,
            customerName: original.clientName,
          );
    }
    return copy;
  }

  /// Cancella tutti gli appuntamenti appartenenti a una prenotazione.
  void deleteByBooking(int bookingId) {
    state = [
      for (final appt in state)
        if (appt.bookingId != bookingId) appt,
    ];
  }

  /// Crea rapidamente una prenotazione per un client con valori di default
  /// - Usa la sede corrente e la data corrente dell'agenda
  /// - Sceglie la prima variante servizio disponibile per la sede
  /// - Sceglie il primo staff idoneo per quel servizio
  /// - Orario: prossimo slot di 15 minuti a partire da adesso (limitato al giorno corrente)
  /// Restituisce l'appuntamento creato.
  Appointment? createQuickBookingForClient(int clientId) {
    final clientsById = ref.read(clientsByIdProvider);
    final client = clientsById[clientId];
    if (client == null) return null;

    final business = ref.read(currentBusinessProvider);
    final location = ref.read(currentLocationProvider);
    final agendaDate = ref.read(agendaDateProvider);
    final variants = ref.read(serviceVariantsProvider);
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

    // Genera id
    final nextId = state.isEmpty
        ? 1
        : state.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
    final nextBookingId = state.isEmpty
        ? 100000
        : state.map((e) => e.bookingId).reduce((a, b) => a > b ? a : b) + 1;

    final appt = Appointment(
      id: nextId,
      bookingId: nextBookingId,
      businessId: business.id,
      locationId: location.id,
      staffId: staffId,
      serviceId: variant.serviceId,
      serviceVariantId: variant.id,
      clientId: client.id,
      clientName: client.name,
      serviceName: '',
      startTime: start,
      endTime: end,
      price: variant.price,
    );

    state = [...state, appt];
    ref
        .read(bookingsProvider.notifier)
        .ensureBooking(
          bookingId: nextBookingId,
          businessId: business.id,
          locationId: location.id,
          clientId: client.id,
          customerName: client.name,
        );
    return appt;
  }
}

final appointmentsProvider =
    NotifierProvider<AppointmentsNotifier, List<Appointment>>(
      AppointmentsNotifier.new,
    );

final appointmentsForCurrentLocationProvider = Provider<List<Appointment>>((
  ref,
) {
  final location = ref.watch(currentLocationProvider);
  final currentDate = ref.watch(agendaDateProvider);
  final dayStart = DateUtils.dateOnly(currentDate);
  final dayEnd = dayStart.add(const Duration(days: 1));
  final appointments = ref.watch(appointmentsProvider);
  return [
    for (final appt in appointments)
      if (appt.locationId == location.id &&
          !appt.endTime.isBefore(dayStart) &&
          appt.startTime.isBefore(dayEnd))
        appt,
  ];
});
