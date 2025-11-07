import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AgendaDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final initial = DateUtils.dateOnly(DateTime.now());
    debugPrint('[AgendaDateNotifier] build → $initial');
    return initial;
  }

  void set(DateTime date) {
    final next = DateUtils.dateOnly(date);
    debugPrint('[AgendaDateNotifier] set → $next');
    state = next;
  }

  void nextDay() {
    final next = DateUtils.dateOnly(state.add(const Duration(days: 1)));
    debugPrint('[AgendaDateNotifier] nextDay → $next');
    state = next;
  }

  void nextWeek() {
    final next = DateUtils.dateOnly(state.add(const Duration(days: 7)));
    debugPrint('[AgendaDateNotifier] nextWeek → $next');
    state = next;
  }

  void previousDay() {
    final next = DateUtils.dateOnly(state.subtract(const Duration(days: 1)));
    debugPrint('[AgendaDateNotifier] previousDay → $next');
    state = next;
  }

  void previousWeek() {
    final next = DateUtils.dateOnly(state.subtract(const Duration(days: 7)));
    debugPrint('[AgendaDateNotifier] previousWeek → $next');
    state = next;
  }

  void setToday() {
    final today = DateUtils.dateOnly(DateTime.now());
    debugPrint('[AgendaDateNotifier] setToday → $today');
    state = today;
  }
}

final agendaDateProvider = NotifierProvider<AgendaDateNotifier, DateTime>(
  AgendaDateNotifier.new,
);
