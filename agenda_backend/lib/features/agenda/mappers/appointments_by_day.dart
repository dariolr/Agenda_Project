import 'package:flutter/material.dart';

import '../../../core/models/appointment.dart';
import '../utils/week_range.dart';

Map<DateTime, List<Appointment>> mapAppointmentsByDay(
  List<Appointment> appointments, {
  required WeekRange weekRange,
}) {
  final byDay = <DateTime, List<Appointment>>{
    for (final day in weekRange.days) DateUtils.dateOnly(day): <Appointment>[],
  };

  for (final appointment in appointments) {
    final dayKey = DateUtils.dateOnly(appointment.startTime);
    final bucket = byDay[dayKey];
    if (bucket == null) continue;
    bucket.add(appointment);
  }

  for (final entries in byDay.values) {
    entries.sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  return byDay;
}
