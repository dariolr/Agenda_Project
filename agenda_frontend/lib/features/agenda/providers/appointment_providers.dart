import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/appointment.dart';
import 'business_providers.dart';
import 'date_range_provider.dart';
import 'location_providers.dart';

class _StaffScheduleSeed {
  final int staffId;
  final List<int> locationIds;
  final int serviceId;
  final int serviceVariantId;
  final String serviceName;
  final double basePrice;

  const _StaffScheduleSeed({
    required this.staffId,
    required this.locationIds,
    required this.serviceId,
    required this.serviceVariantId,
    required this.serviceName,
    required this.basePrice,
  });
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

    const seeds = [
      _StaffScheduleSeed(
        staffId: 1,
        locationIds: [101],
        serviceId: 1,
        serviceVariantId: 1001,
        serviceName: 'Massaggio Relax',
        basePrice: 45,
      ),
      _StaffScheduleSeed(
        staffId: 2,
        locationIds: [102],
        serviceId: 1,
        serviceVariantId: 1002,
        serviceName: 'Trattamento Viso',
        basePrice: 48,
      ),
      _StaffScheduleSeed(
        staffId: 3,
        locationIds: [101, 102],
        serviceId: 2,
        serviceVariantId: 2001,
        serviceName: 'Massaggio Sportivo',
        basePrice: 60,
      ),
      _StaffScheduleSeed(
        staffId: 4,
        locationIds: [101],
        serviceId: 3,
        serviceVariantId: 3002,
        serviceName: 'Hair Styling',
        basePrice: 50,
      ),
      _StaffScheduleSeed(
        staffId: 5,
        locationIds: [102],
        serviceId: 4,
        serviceVariantId: 4002,
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
          final durationMinutes = 15 * (1 + random.nextInt(8)); // 15-120
          final start = dayDate.add(Duration(minutes: startMinute));
          final end = start.add(Duration(minutes: durationMinutes));

          final currentBookingId = bookingId++;
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

            appointments.add(
              Appointment(
                id: appointmentId++,
                bookingId: currentBookingId,
                businessId: business.id,
                locationId: locationId,
                staffId: seed.staffId,
                serviceId: seed.serviceId,
                serviceVariantId: seed.serviceVariantId,
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

  void moveAppointment({
    required int appointmentId,
    required int newStaffId,
    required DateTime newStart,
    required DateTime newEnd,
  }) async {
    state = [
      for (final appt in state)
        if (appt.id == appointmentId)
          appt.copyWith(
            staffId: newStaffId,
            startTime: newStart,
            endTime: newEnd,
          )
        else
          appt,
    ];
    await Future.delayed(Duration.zero);
  }

  void deleteAppointment(int appointmentId) {
    state = [
      for (final appt in state)
        if (appt.id != appointmentId) appt,
    ];
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
