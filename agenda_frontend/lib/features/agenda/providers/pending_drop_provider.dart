import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dati di un drop in attesa di conferma.
@immutable
class PendingDropData {
  final int appointmentId;
  final int originalStaffId;
  final DateTime originalStart;
  final DateTime originalEnd;
  final int newStaffId;
  final DateTime newStart;
  final DateTime newEnd;

  const PendingDropData({
    required this.appointmentId,
    required this.originalStaffId,
    required this.originalStart,
    required this.originalEnd,
    required this.newStaffId,
    required this.newStart,
    required this.newEnd,
  });
}

/// Notifier per gestire lo stato di un drop in attesa di conferma.
class PendingDropNotifier extends Notifier<PendingDropData?> {
  @override
  PendingDropData? build() => null;

  void setPending(PendingDropData data) {
    state = data;
  }

  void clear() {
    state = null;
  }

  bool get hasPending => state != null;
}

/// Provider per lo stato di drop in attesa di conferma.
final pendingDropProvider =
    NotifierProvider<PendingDropNotifier, PendingDropData?>(
      PendingDropNotifier.new,
    );

/// Provider per verificare se un appuntamento specifico ha un drop pendente.
final isAppointmentPendingDropProvider = Provider.family<bool, int>((
  ref,
  appointmentId,
) {
  final pending = ref.watch(pendingDropProvider);
  return pending?.appointmentId == appointmentId;
});
