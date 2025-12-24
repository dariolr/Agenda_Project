import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/appointment.dart';

@immutable
class AgendaScrollRequest {
  const AgendaScrollRequest(this.appointment);

  final Appointment appointment;

  DateTime get date => DateUtils.dateOnly(appointment.startTime);
}

class AgendaScrollRequestNotifier extends Notifier<AgendaScrollRequest?> {
  @override
  AgendaScrollRequest? build() => null;

  void request(Appointment appointment) {
    state = AgendaScrollRequest(appointment);
  }

  void clear() => state = null;
}

final agendaScrollRequestProvider =
    NotifierProvider<AgendaScrollRequestNotifier, AgendaScrollRequest?>(
      AgendaScrollRequestNotifier.new,
    );
