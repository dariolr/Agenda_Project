import 'package:agenda_backend/core/services/tenant_time_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeekRange {
  const WeekRange({
    required this.start,
    required this.end,
    required this.days,
    required this.label,
  });

  final DateTime start;
  final DateTime end;
  final List<DateTime> days;
  final String label;

  DateTime get endExclusive =>
      DateUtils.dateOnly(end).add(const Duration(days: 1));
}

WeekRange computeWeekRange(
  DateTime anchor,
  String timezone, {
  String? localeTag,
}) {
  final localAnchor = TenantTimeService.assumeTenantLocal(anchor, timezone);
  final anchorDate = DateUtils.dateOnly(localAnchor);
  final daysFromMonday = (anchorDate.weekday - DateTime.monday) % 7;
  final start = DateUtils.dateOnly(
    anchorDate.subtract(Duration(days: daysFromMonday)),
  );
  final endExclusive = start.add(const Duration(days: 7));
  final end = endExclusive.subtract(const Duration(milliseconds: 1));
  final days = List<DateTime>.generate(
    7,
    (index) => DateUtils.dateOnly(start.add(Duration(days: index))),
  );

  final locale = localeTag ?? Intl.getCurrentLocale();
  final label = _buildWeekRangeLabel(start, end, locale);

  return WeekRange(start: start, end: end, days: days, label: label);
}

String _buildWeekRangeLabel(DateTime start, DateTime end, String localeTag) {
  final sameYear = start.year == end.year;
  final sameMonth = sameYear && start.month == end.month;

  if (sameMonth) {
    final from = DateFormat('d', localeTag).format(start);
    final to = DateFormat('d MMM y', localeTag).format(end);
    return '$from-$to';
  }

  if (sameYear) {
    final from = DateFormat('d MMM', localeTag).format(start);
    final to = DateFormat('d MMM y', localeTag).format(end);
    return '$from - $to';
  }

  final from = DateFormat('d MMM y', localeTag).format(start);
  final to = DateFormat('d MMM y', localeTag).format(end);
  return '$from - $to';
}
