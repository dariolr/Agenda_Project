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
    final todaySeen = prefs.getAgendaTodaySeenDate(
      businessId,
      locationId: locationId,
    );
    final hasSeenToday = todaySeen != null && DateUtils.isSameDay(todaySeen, today);
    if (!hasSeenToday) {
      // Prima apertura del giorno: mostra oggi immediatamente.
      prefs.setAgendaTodaySeenDate(
        businessId,
        locationId: locationId,
        date: today,
      );
      prefs.setAgendaDate(
        businessId,
        locationId: locationId,
        date: today,
      );
      return today;
    }

    final saved = prefs.getAgendaDate(businessId, locationId: locationId);
    if (saved == null) {
      return today;
    }

    final savedDate = DateUtils.dateOnly(saved);
    return savedDate;
  }

  void set(DateTime date) {
    final next = DateUtils.dateOnly(date);
    state = next;
    _save(next);
  }

  void nextDay() {
    final next = _addCalendarDays(state, 1);
    state = next;
    _save(next);
  }

  void nextWeek() {
    final next = _addCalendarDays(state, 7);
    state = next;
    _save(next);
  }

  void previousDay() {
    final next = _addCalendarDays(state, -1);
    state = next;
    _save(next);
  }

  void previousWeek() {
    final next = _addCalendarDays(state, -7);
    state = next;
    _save(next);
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
    final next = DateUtils.dateOnly(DateTime(targetYear, targetMonth, safeDay));
    state = next;
    _save(next);
  }

  void setToday() {
    final today = DateUtils.dateOnly(ref.read(tenantTodayProvider));
    state = today;
    _save(today);
  }

  DateTime _addCalendarDays(DateTime date, int deltaDays) {
    final d = DateUtils.dateOnly(date);
    return DateUtils.dateOnly(DateTime(d.year, d.month, d.day + deltaDays));
  }

  void _save(DateTime date) {
    final businessId = ref.read(currentBusinessIdProvider);
    final locationId = ref.read(currentLocationIdProvider);
    if (businessId <= 0 || locationId <= 0) return;
    final prefs = ref.read(preferencesServiceProvider);
    prefs.setAgendaDate(
      businessId,
      locationId: locationId,
      date: date,
    );
    final today = ref.read(tenantTodayProvider);
    if (DateUtils.isSameDay(date, today)) {
      prefs.setAgendaTodaySeenDate(
        businessId,
        locationId: locationId,
        date: today,
      );
    }
  }
}

final agendaDateProvider = NotifierProvider<AgendaDateNotifier, DateTime>(
  AgendaDateNotifier.new,
);
