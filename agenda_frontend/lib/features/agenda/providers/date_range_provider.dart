import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AgendaDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateUtils.dateOnly(DateTime.now());

  void set(DateTime date) => state = DateUtils.dateOnly(date);

  void nextDay() =>
      state = DateUtils.dateOnly(state.add(const Duration(days: 1)));

  void nextWeek() =>
      state = DateUtils.dateOnly(state.add(const Duration(days: 7)));
  void previousDay() =>
      state = DateUtils.dateOnly(state.subtract(const Duration(days: 1)));

  void previousWeek() =>
      state = DateUtils.dateOnly(state.subtract(const Duration(days: 7)));

  void setToday() => state = DateUtils.dateOnly(DateTime.now());
}

final agendaDateProvider = NotifierProvider<AgendaDateNotifier, DateTime>(
  AgendaDateNotifier.new,
);
