import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/preferences_service.dart';
import 'business_providers.dart';
import 'location_providers.dart';
import 'tenant_time_provider.dart';

class AgendaDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final today = ref.watch(tenantTodayProvider);
    final businessId = ref.watch(currentBusinessIdProvider);
    final locationId = ref.watch(currentLocationIdProvider);
    if (businessId <= 0 || locationId <= 0) {
      return today;
    }

    final prefs = ref.watch(preferencesServiceProvider);
    final saved = prefs.getAgendaDate(businessId, locationId: locationId);
    if (saved == null) {
      return today;
    }

    final savedDate = DateUtils.dateOnly(saved);
    final yesterday = DateUtils.dateOnly(
      today.subtract(const Duration(days: 1)),
    );
    if (DateUtils.isSameDay(savedDate, yesterday)) {
      return today;
    }

    return savedDate;
  }

  void set(DateTime date) {
    final next = DateUtils.dateOnly(date);
    state = next;
    _save(next);
  }

  void nextDay() {
    final next = DateUtils.dateOnly(state.add(const Duration(days: 1)));
    state = next;
  }

  void nextWeek() {
    final next = DateUtils.dateOnly(state.add(const Duration(days: 7)));
    state = next;
  }

  void previousDay() {
    final next = DateUtils.dateOnly(state.subtract(const Duration(days: 1)));
    state = next;
  }

  void previousWeek() {
    final next = DateUtils.dateOnly(state.subtract(const Duration(days: 7)));
    state = next;
  }

  void nextMonth() => _shiftMonths(1);

  void previousMonth() => _shiftMonths(-1);

  void _shiftMonths(int delta) {
    final y = state.year;
    final m = state.month;
    final d = state.day;

    // Convert to absolute month index to avoid loop and off-by-one issues
    final abs = y * 12 + (m - 1) + delta;
    final targetYear = abs ~/ 12;
    final targetMonth = (abs % 12) + 1; // back to 1..12

    final dim = DateUtils.getDaysInMonth(targetYear, targetMonth);
    final int safeDay = d <= dim ? d : dim;
    state = DateUtils.dateOnly(DateTime(targetYear, targetMonth, safeDay));
  }

  void setToday() {
    final today = ref.read(tenantTodayProvider);
    state = today;
    _save(today);
  }

  void _save(DateTime date) {
    final businessId = ref.read(currentBusinessIdProvider);
    final locationId = ref.read(currentLocationIdProvider);
    if (businessId <= 0 || locationId <= 0) return;
    ref.read(preferencesServiceProvider).setAgendaDate(
      businessId,
      locationId: locationId,
      date: date,
    );
  }
}

final agendaDateProvider = NotifierProvider<AgendaDateNotifier, DateTime>(
  AgendaDateNotifier.new,
);
