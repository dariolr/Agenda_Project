import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tenant_time_provider.dart';

class AgendaDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    return ref.watch(tenantTodayProvider);
  }

  void set(DateTime date) {
    final next = DateUtils.dateOnly(date);
    state = next;
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
    state = ref.read(tenantTodayProvider);
  }
}

final agendaDateProvider = NotifierProvider<AgendaDateNotifier, DateTime>(
  AgendaDateNotifier.new,
);
