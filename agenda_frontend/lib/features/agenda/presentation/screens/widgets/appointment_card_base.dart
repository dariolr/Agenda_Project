import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/models/appointment.dart';
import 'appointment_card_interactive.dart';

/// Wrapper unico che istanzia la versione interattiva
/// per entrambi i form factor (desktop e mobile).
class AppointmentCard extends ConsumerWidget {
  final Appointment appointment;
  final Color color;
  final double? columnWidth;
  final double? columnOffset;
  final bool expandToLeft;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.color,
    this.columnWidth,
    this.columnOffset,
    this.expandToLeft = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppointmentCardInteractive(
      appointment: appointment,
      color: color,
      columnWidth: columnWidth,
      columnOffset: columnOffset,
      expandToLeft: expandToLeft,
    );
  }
}
