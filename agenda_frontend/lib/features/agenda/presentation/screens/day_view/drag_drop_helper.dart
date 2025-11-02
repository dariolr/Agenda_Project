import 'package:flutter/material.dart';

import '/core/models/appointment.dart';
import '../../../domain/config/layout_config.dart';

class DropComputationParams {
  const DropComputationParams({
    required this.appointment,
    required this.layoutConfig,
    required this.columnHeight,
    required this.localPointer,
    required this.dragOffsetY,
    required this.draggedCardHeightPx,
    required this.previewTimes,
  });

  final Appointment appointment;
  final LayoutConfig layoutConfig;
  final double columnHeight;
  final Offset localPointer;
  final double dragOffsetY;
  final double draggedCardHeightPx;
  final (DateTime, DateTime)? previewTimes;
}

class DropComputationResult {
  const DropComputationResult({
    required this.newStart,
    required this.newEnd,
  });

  final DateTime newStart;
  final DateTime newEnd;
}

DropComputationResult computeDropResult(DropComputationParams params) {
  final layoutConfig = params.layoutConfig;
  final slotHeight = layoutConfig.slotHeight;
  final minutesPerSlot = layoutConfig.minutesPerSlot;

  final maxYStartPx =
      (params.columnHeight - params.draggedCardHeightPx)
          .clamp(0, params.columnHeight)
          .toDouble();
  final clampedLocalDy =
      params.localPointer.dy.clamp(0.0, params.columnHeight.toDouble());
  final effectiveDy =
      (clampedLocalDy - params.dragOffsetY).clamp(0.0, maxYStartPx).toDouble();

  final rawTop = params.localPointer.dy - params.dragOffsetY;
  final rawBottom = rawTop + params.draggedCardHeightPx;
  final isAboveBounds = rawTop < 0;
  final isBelowBounds = rawBottom > params.columnHeight;

  final appointment = params.appointment;
  final duration = appointment.endTime.difference(appointment.startTime);
  final durationMinutes = duration.inMinutes;

  final baseDate = DateTime(
    appointment.startTime.year,
    appointment.startTime.month,
    appointment.startTime.day,
  );

  DateTime newStart;
  DateTime newEnd;

  final previewTimes = params.previewTimes;
  if (previewTimes != null) {
    newStart = previewTimes.$1;
    newEnd = previewTimes.$2;
  } else {
    final minutesFromTop =
        (effectiveDy / slotHeight) * minutesPerSlot;
    double roundedMinutes = (minutesFromTop / 5).round() * 5;

    const totalMinutes = LayoutConfig.hoursInDay * 60; // 1440
    final maxStartMinutesNum =
        (totalMinutes - durationMinutes).clamp(0, totalMinutes);

    int startMinutes = roundedMinutes.toInt();
    final maxStartMinutes = maxStartMinutesNum.toInt();

    if (startMinutes > maxStartMinutes) startMinutes = maxStartMinutes;
    if (startMinutes < 0) startMinutes = 0;

    final endMinutes =
        (startMinutes + durationMinutes).clamp(0, totalMinutes).toInt();

    newStart = baseDate.add(Duration(minutes: startMinutes));

    final rawEnd = baseDate.add(Duration(minutes: endMinutes));
    final dayBoundary = baseDate.add(const Duration(days: 1));
    newEnd = rawEnd.isAfter(dayBoundary) ? dayBoundary : rawEnd;
  }

  if (isAboveBounds) {
    newStart = baseDate;
    final cappedEnd =
        baseDate.add(Duration(minutes: durationMinutes));
    final dayEnd = baseDate.add(const Duration(days: 1));
    newEnd = cappedEnd.isBefore(dayEnd) ? cappedEnd : dayEnd;
  }

  if (isBelowBounds) {
    final dayEnd = baseDate.add(const Duration(days: 1));
    newEnd = dayEnd;
    final candidateStart =
        dayEnd.subtract(Duration(minutes: durationMinutes));
    newStart = candidateStart.isAfter(baseDate)
        ? candidateStart
        : baseDate;
  }

  return DropComputationResult(
    newStart: newStart,
    newEnd: newEnd,
  );
}
