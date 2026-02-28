/// Report data models for appointment statistics.
library;

import 'package:flutter/foundation.dart';

/// Summary metrics for the report.
@immutable
class ReportSummary {
  const ReportSummary({
    required this.totalAppointments,
    required this.totalBookings,
    required this.totalRevenue,
    required this.totalDurationMinutes,
    required this.uniqueClients,
    required this.cancelledCount,
    required this.onlineCount,
    required this.manualCount,
    required this.availableMinutes,
    required this.occupancyPercentage,
    required this.cashCents,
    required this.cardCents,
    required this.voucherCents,
    required this.otherCents,
    required this.discountCents,
    required this.paidCents,
    required this.dueCents,
  });

  final int totalAppointments;
  final int totalBookings;
  final double totalRevenue;
  final int totalDurationMinutes;
  final int uniqueClients;
  final int cancelledCount;
  final int onlineCount;
  final int manualCount;
  final int availableMinutes;
  final double occupancyPercentage;
  final int cashCents;
  final int cardCents;
  final int voucherCents;
  final int otherCents;
  final int discountCents;
  final int paidCents;
  final int dueCents;

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      totalAppointments: json['total_appointments'] as int? ?? 0,
      totalBookings: json['total_bookings'] as int? ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      totalDurationMinutes: json['total_duration_minutes'] as int? ?? 0,
      uniqueClients: json['unique_clients'] as int? ?? 0,
      cancelledCount: json['cancelled_count'] as int? ?? 0,
      onlineCount: json['online_count'] as int? ?? 0,
      manualCount: json['manual_count'] as int? ?? 0,
      availableMinutes: json['available_minutes'] as int? ?? 0,
      occupancyPercentage:
          (json['occupancy_percentage'] as num?)?.toDouble() ?? 0.0,
      cashCents: json['cash_cents'] as int? ?? 0,
      cardCents: json['card_cents'] as int? ?? 0,
      voucherCents: json['voucher_cents'] as int? ?? 0,
      otherCents: json['other_cents'] as int? ?? 0,
      discountCents: json['discount_cents'] as int? ?? 0,
      paidCents: json['paid_cents'] as int? ?? 0,
      dueCents: json['due_cents'] as int? ?? 0,
    );
  }

  /// Returns total hours worked.
  double get totalHours => totalDurationMinutes / 60.0;

  /// Returns total available hours.
  double get availableHours => availableMinutes / 60.0;

  /// Returns average revenue per appointment.
  double get avgRevenuePerAppointment =>
      totalAppointments > 0 ? totalRevenue / totalAppointments : 0.0;
}

/// Staff breakdown row.
@immutable
class StaffReportRow {
  const StaffReportRow({
    required this.staffId,
    required this.staffName,
    this.staffColor,
    required this.appointments,
    required this.revenue,
    required this.durationMinutes,
  });

  final int staffId;
  final String staffName;
  final String? staffColor;
  final int appointments;
  final double revenue;
  final int durationMinutes;

  factory StaffReportRow.fromJson(Map<String, dynamic> json) {
    return StaffReportRow(
      staffId: json['staff_id'] as int,
      staffName: json['staff_name'] as String? ?? 'Unknown',
      staffColor: json['staff_color'] as String?,
      appointments: json['appointments'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: json['duration_minutes'] as int? ?? 0,
    );
  }

  double get hours => durationMinutes / 60.0;
  double get avgRevenue => appointments > 0 ? revenue / appointments : 0.0;
}

/// Location breakdown row.
@immutable
class LocationReportRow {
  const LocationReportRow({
    required this.locationId,
    required this.locationName,
    required this.appointments,
    required this.revenue,
    required this.durationMinutes,
    required this.cashCents,
    required this.cardCents,
    required this.voucherCents,
    required this.otherCents,
    required this.discountCents,
    required this.paidCents,
    required this.dueCents,
  });

  final int locationId;
  final String locationName;
  final int appointments;
  final double revenue;
  final int durationMinutes;
  final int cashCents;
  final int cardCents;
  final int voucherCents;
  final int otherCents;
  final int discountCents;
  final int paidCents;
  final int dueCents;

  factory LocationReportRow.fromJson(Map<String, dynamic> json) {
    return LocationReportRow(
      locationId: json['location_id'] as int,
      locationName: json['location_name'] as String? ?? 'Unknown',
      appointments: json['appointments'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      cashCents: json['cash_cents'] as int? ?? 0,
      cardCents: json['card_cents'] as int? ?? 0,
      voucherCents: json['voucher_cents'] as int? ?? 0,
      otherCents: json['other_cents'] as int? ?? 0,
      discountCents: json['discount_cents'] as int? ?? 0,
      paidCents: json['paid_cents'] as int? ?? 0,
      dueCents: json['due_cents'] as int? ?? 0,
    );
  }

  double get hours => durationMinutes / 60.0;
}

/// Service breakdown row.
@immutable
class ServiceReportRow {
  const ServiceReportRow({
    required this.serviceId,
    required this.serviceName,
    this.categoryName,
    required this.appointments,
    required this.revenue,
    required this.avgDurationMinutes,
  });

  final int serviceId;
  final String serviceName;
  final String? categoryName;
  final int appointments;
  final double revenue;
  final int avgDurationMinutes;

  factory ServiceReportRow.fromJson(Map<String, dynamic> json) {
    return ServiceReportRow(
      serviceId: json['service_id'] as int,
      serviceName: json['service_name'] as String? ?? 'Unknown',
      categoryName: json['category_name'] as String?,
      appointments: json['appointments'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      avgDurationMinutes: json['avg_duration_minutes'] as int? ?? 0,
    );
  }
}

/// Day of week breakdown row.
@immutable
class DayOfWeekReportRow {
  const DayOfWeekReportRow({
    required this.dayOfWeek,
    required this.appointments,
    required this.revenue,
  });

  /// 1 = Sunday, 2 = Monday, ..., 7 = Saturday (MySQL DAYOFWEEK)
  final int dayOfWeek;
  final int appointments;
  final double revenue;

  factory DayOfWeekReportRow.fromJson(Map<String, dynamic> json) {
    return DayOfWeekReportRow(
      dayOfWeek: json['day_of_week'] as int,
      appointments: json['appointments'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Returns ISO weekday (1 = Monday, 7 = Sunday).
  int get isoWeekday {
    // MySQL: 1=Sun, 2=Mon, ..., 7=Sat
    // ISO: 1=Mon, ..., 7=Sun
    return dayOfWeek == 1 ? 7 : dayOfWeek - 1;
  }
}

/// Period breakdown row (daily/weekly/monthly).
@immutable
class PeriodReportRow {
  const PeriodReportRow({
    required this.periodStart,
    required this.appointments,
    required this.revenue,
    required this.durationMinutes,
  });

  final DateTime periodStart;
  final int appointments;
  final double revenue;
  final int durationMinutes;

  factory PeriodReportRow.fromJson(Map<String, dynamic> json) {
    return PeriodReportRow(
      periodStart: DateTime.parse(json['period_start'] as String),
      appointments: json['appointments'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: json['duration_minutes'] as int? ?? 0,
    );
  }

  double get hours => durationMinutes / 60.0;
}

/// Hour breakdown row.
@immutable
class HourReportRow {
  const HourReportRow({
    required this.hour,
    required this.appointments,
    required this.revenue,
  });

  final int hour;
  final int appointments;
  final double revenue;

  factory HourReportRow.fromJson(Map<String, dynamic> json) {
    return HourReportRow(
      hour: json['hour'] as int,
      appointments: json['appointments'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Period breakdown with granularity info.
@immutable
class PeriodBreakdown {
  const PeriodBreakdown({required this.granularity, required this.data});

  /// 'day', 'week', or 'month'
  final String granularity;
  final List<PeriodReportRow> data;

  factory PeriodBreakdown.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    return PeriodBreakdown(
      granularity: json['granularity'] as String? ?? 'day',
      data: dataList
          .map((e) => PeriodReportRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Filter parameters used for the report.
@immutable
class ReportFilters {
  const ReportFilters({
    required this.startDate,
    required this.endDate,
    required this.locationIds,
    required this.staffIds,
    required this.serviceIds,
    required this.statuses,
  });

  final DateTime startDate;
  final DateTime endDate;
  final List<int> locationIds;
  final List<int> staffIds;
  final List<int> serviceIds;
  final List<String> statuses;

  factory ReportFilters.fromJson(Map<String, dynamic> json) {
    return ReportFilters(
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      locationIds:
          (json['location_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      staffIds:
          (json['staff_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      serviceIds:
          (json['service_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      statuses:
          (json['statuses'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

/// Complete report response.
@immutable
class AppointmentsReport {
  const AppointmentsReport({
    required this.summary,
    required this.byStaff,
    required this.byLocation,
    required this.byService,
    required this.byDayOfWeek,
    required this.byPeriod,
    required this.byHour,
    required this.filters,
  });

  final ReportSummary summary;
  final List<StaffReportRow> byStaff;
  final List<LocationReportRow> byLocation;
  final List<ServiceReportRow> byService;
  final List<DayOfWeekReportRow> byDayOfWeek;
  final PeriodBreakdown byPeriod;
  final List<HourReportRow> byHour;
  final ReportFilters filters;

  factory AppointmentsReport.fromJson(Map<String, dynamic> json) {
    return AppointmentsReport(
      summary: ReportSummary.fromJson(json['summary'] as Map<String, dynamic>),
      byStaff: (json['by_staff'] as List<dynamic>)
          .map((e) => StaffReportRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      byLocation: (json['by_location'] as List<dynamic>)
          .map((e) => LocationReportRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      byService: (json['by_service'] as List<dynamic>)
          .map((e) => ServiceReportRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      byDayOfWeek: (json['by_day_of_week'] as List<dynamic>)
          .map((e) => DayOfWeekReportRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      byPeriod: PeriodBreakdown.fromJson(
        json['by_period'] as Map<String, dynamic>,
      ),
      byHour: (json['by_hour'] as List<dynamic>)
          .map((e) => HourReportRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      filters: ReportFilters.fromJson(json['filters'] as Map<String, dynamic>),
    );
  }
}

// ============================================================================
// WORK HOURS REPORT MODELS
// ============================================================================

/// Summary for work hours report.
@immutable
class WorkHoursSummary {
  const WorkHoursSummary({
    required this.totalScheduledMinutes,
    required this.totalWorkedMinutes,
    required this.totalBlockedMinutes,
    required this.totalExceptionOffMinutes,
    required this.totalAvailableMinutes,
    required this.overallUtilizationPercentage,
  });

  final int totalScheduledMinutes;
  final int totalWorkedMinutes;
  final int totalBlockedMinutes;
  final int totalExceptionOffMinutes;
  final int totalAvailableMinutes;
  final double overallUtilizationPercentage;

  factory WorkHoursSummary.fromJson(Map<String, dynamic> json) {
    return WorkHoursSummary(
      totalScheduledMinutes: json['total_scheduled_minutes'] as int? ?? 0,
      totalWorkedMinutes: json['total_worked_minutes'] as int? ?? 0,
      totalBlockedMinutes: json['total_blocked_minutes'] as int? ?? 0,
      totalExceptionOffMinutes:
          json['total_exception_off_minutes'] as int? ?? 0,
      totalAvailableMinutes: json['total_available_minutes'] as int? ?? 0,
      overallUtilizationPercentage:
          (json['overall_utilization_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Returns total scheduled hours.
  double get totalScheduledHours => totalScheduledMinutes / 60.0;

  /// Returns total worked hours.
  double get totalWorkedHours => totalWorkedMinutes / 60.0;

  /// Returns total blocked hours.
  double get totalBlockedHours => totalBlockedMinutes / 60.0;

  /// Returns total exception off hours (ferie, malattia, ecc.).
  double get totalExceptionOffHours => totalExceptionOffMinutes / 60.0;

  /// Returns total available hours (scheduled - blocked).
  double get totalAvailableHours => totalAvailableMinutes / 60.0;
}

/// Staff row for work hours report.
@immutable
class StaffWorkHoursRow {
  const StaffWorkHoursRow({
    required this.staffId,
    required this.staffName,
    this.staffColor,
    required this.scheduledMinutes,
    required this.workedMinutes,
    required this.blockedMinutes,
    required this.exceptionOffMinutes,
    required this.availableMinutes,
    required this.utilizationPercentage,
  });

  final int staffId;
  final String staffName;
  final String? staffColor;
  final int scheduledMinutes;
  final int workedMinutes;
  final int blockedMinutes;
  final int exceptionOffMinutes;
  final int availableMinutes;
  final double utilizationPercentage;

  factory StaffWorkHoursRow.fromJson(Map<String, dynamic> json) {
    return StaffWorkHoursRow(
      staffId: json['staff_id'] as int,
      staffName: json['staff_name'] as String? ?? 'Unknown',
      staffColor: json['staff_color'] as String?,
      scheduledMinutes: json['scheduled_minutes'] as int? ?? 0,
      workedMinutes: json['worked_minutes'] as int? ?? 0,
      blockedMinutes: json['blocked_minutes'] as int? ?? 0,
      exceptionOffMinutes: json['exception_off_minutes'] as int? ?? 0,
      availableMinutes: json['available_minutes'] as int? ?? 0,
      utilizationPercentage:
          (json['utilization_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  double get scheduledHours => scheduledMinutes / 60.0;
  double get workedHours => workedMinutes / 60.0;
  double get blockedHours => blockedMinutes / 60.0;
  double get exceptionOffHours => exceptionOffMinutes / 60.0;
  double get availableHours => availableMinutes / 60.0;
}

/// Complete work hours report response.
@immutable
class WorkHoursReport {
  const WorkHoursReport({
    required this.summary,
    required this.byStaff,
    required this.filters,
  });

  final WorkHoursSummary summary;
  final List<StaffWorkHoursRow> byStaff;
  final ReportFilters filters;

  factory WorkHoursReport.fromJson(Map<String, dynamic> json) {
    return WorkHoursReport(
      summary: WorkHoursSummary.fromJson(
        json['summary'] as Map<String, dynamic>,
      ),
      byStaff: (json['by_staff'] as List<dynamic>)
          .map((e) => StaffWorkHoursRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      filters: ReportFilters.fromJson(json['filters'] as Map<String, dynamic>),
    );
  }
}
