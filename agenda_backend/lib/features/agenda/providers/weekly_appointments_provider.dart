import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/appointment.dart';
import '../../auth/providers/auth_provider.dart';
import 'bookings_provider.dart';
import 'bookings_repository_provider.dart';

class WeeklyAppointmentsRequest {
  const WeeklyAppointmentsRequest({
    required this.weekStart,
    required this.locationId,
    required this.businessId,
  });

  final DateTime weekStart;
  final int locationId;
  final int businessId;

  WeeklyAppointmentsRequest normalized() {
    return WeeklyAppointmentsRequest(
      weekStart: DateUtils.dateOnly(weekStart),
      locationId: locationId,
      businessId: businessId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeeklyAppointmentsRequest &&
        DateUtils.isSameDay(other.weekStart, weekStart) &&
        other.locationId == locationId &&
        other.businessId == businessId;
  }

  @override
  int get hashCode => Object.hash(
    weekStart.year,
    weekStart.month,
    weekStart.day,
    locationId,
    businessId,
  );
}

class WeeklyAppointmentsResult {
  const WeeklyAppointmentsResult({
    required this.appointments,
    required this.bookingIds,
  });

  final List<Appointment> appointments;
  final Set<int> bookingIds;
}

final weeklyAppointmentsProvider =
    FutureProvider.family<WeeklyAppointmentsResult, WeeklyAppointmentsRequest>((
      ref,
      rawRequest,
    ) async {
      final authState = ref.watch(authProvider);
      if (!authState.isAuthenticated) {
        return const WeeklyAppointmentsResult(appointments: [], bookingIds: {});
      }

      final request = rawRequest.normalized();
      if (request.locationId <= 0 || request.businessId <= 0) {
        return const WeeklyAppointmentsResult(appointments: [], bookingIds: {});
      }

      final repository = ref.watch(bookingsRepositoryProvider);
      final results = await Future.wait(
        List.generate(7, (index) {
          final date = request.weekStart.add(Duration(days: index));
          return repository.getAppointmentsWithMetadata(
            locationId: request.locationId,
            businessId: request.businessId,
            date: date,
          );
        }),
      );

      final appointmentsById = <int, Appointment>{};
      final bookingIds = <int>{};
      final bookingsNotifier = ref.read(bookingsProvider.notifier);

      for (final result in results) {
        for (final entry in result.bookingMetadata.entries) {
          final metadata = entry.value;
          bookingIds.add(metadata.id);
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

        for (final appointment in result.appointments) {
          appointmentsById[appointment.id] = appointment;
        }
      }

      final appointments = appointmentsById.values.toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      return WeeklyAppointmentsResult(
        appointments: appointments,
        bookingIds: bookingIds,
      );
    });
