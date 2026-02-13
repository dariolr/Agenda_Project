import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/network_providers.dart';
import '../domain/report_models.dart';

/// Parameters for fetching a report.
class ReportParams {
  const ReportParams({
    required this.businessId,
    required this.startDate,
    required this.endDate,
    this.locationIds = const [],
    this.staffIds = const [],
    this.serviceIds = const [],
    this.statuses = const [
      'confirmed',
      'completed',
    ],
  });

  final int businessId;
  final DateTime startDate;
  final DateTime endDate;
  final List<int> locationIds;
  final List<int> staffIds;
  final List<int> serviceIds;
  final List<String> statuses;

  ReportParams copyWith({
    int? businessId,
    DateTime? startDate,
    DateTime? endDate,
    List<int>? locationIds,
    List<int>? staffIds,
    List<int>? serviceIds,
    List<String>? statuses,
  }) {
    return ReportParams(
      businessId: businessId ?? this.businessId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      locationIds: locationIds ?? this.locationIds,
      staffIds: staffIds ?? this.staffIds,
      serviceIds: serviceIds ?? this.serviceIds,
      statuses: statuses ?? this.statuses,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportParams &&
          runtimeType == other.runtimeType &&
          businessId == other.businessId &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          _listEquals(locationIds, other.locationIds) &&
          _listEquals(staffIds, other.staffIds) &&
          _listEquals(serviceIds, other.serviceIds) &&
          _listEquals(statuses, other.statuses);

  @override
  int get hashCode =>
      businessId.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      locationIds.hashCode ^
      staffIds.hashCode ^
      serviceIds.hashCode ^
      statuses.hashCode;

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// State for the reports screen.
class ReportsState {
  const ReportsState({
    this.params,
    this.report,
    this.isLoading = false,
    this.error,
  });

  final ReportParams? params;
  final AppointmentsReport? report;
  final bool isLoading;
  final String? error;

  ReportsState copyWith({
    ReportParams? params,
    AppointmentsReport? report,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearReport = false,
  }) {
    return ReportsState(
      params: params ?? this.params,
      report: clearReport ? null : (report ?? this.report),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier for reports state.
class ReportsNotifier extends Notifier<ReportsState> {
  @override
  ReportsState build() {
    return const ReportsState();
  }

  /// Sets the filter parameters and fetches the report.
  Future<void> fetchReport(ReportParams params) async {
    state = state.copyWith(params: params, isLoading: true, clearError: true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final dateFormat = DateFormat('yyyy-MM-dd');

      final queryParams = <String, dynamic>{
        'business_id': params.businessId.toString(),
        'start_date': dateFormat.format(params.startDate),
        'end_date': dateFormat.format(params.endDate),
        'status': params.statuses.join(','),
      };

      if (params.locationIds.isNotEmpty) {
        queryParams['location_ids[]'] = params.locationIds
            .map((e) => e.toString())
            .toList();
      }
      if (params.staffIds.isNotEmpty) {
        queryParams['staff_ids[]'] = params.staffIds
            .map((e) => e.toString())
            .toList();
      }
      if (params.serviceIds.isNotEmpty) {
        queryParams['service_ids[]'] = params.serviceIds
            .map((e) => e.toString())
            .toList();
      }

      final response = await apiClient.get(
        '/v1/reports/appointments',
        queryParameters: queryParams,
      );

      final report = AppointmentsReport.fromJson(response);
      state = state.copyWith(report: report, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refreshes the report using the last params.
  Future<void> refresh() async {
    final params = state.params;
    if (params != null) {
      await fetchReport(params);
    }
  }

  /// Clears the report.
  void clear() {
    state = const ReportsState();
  }
}

/// Provider for reports state.
final reportsProvider = NotifierProvider<ReportsNotifier, ReportsState>(
  ReportsNotifier.new,
);

// ============================================================================
// WORK HOURS REPORT
// ============================================================================

/// State for the work hours report.
class WorkHoursReportState {
  const WorkHoursReportState({
    this.params,
    this.report,
    this.isLoading = false,
    this.error,
  });

  final ReportParams? params;
  final WorkHoursReport? report;
  final bool isLoading;
  final String? error;

  WorkHoursReportState copyWith({
    ReportParams? params,
    WorkHoursReport? report,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearReport = false,
  }) {
    return WorkHoursReportState(
      params: params ?? this.params,
      report: clearReport ? null : (report ?? this.report),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier for work hours report state.
class WorkHoursReportNotifier extends Notifier<WorkHoursReportState> {
  @override
  WorkHoursReportState build() {
    return const WorkHoursReportState();
  }

  /// Fetches the work hours report.
  Future<void> fetchReport(ReportParams params) async {
    state = state.copyWith(params: params, isLoading: true, clearError: true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final dateFormat = DateFormat('yyyy-MM-dd');

      final queryParams = <String, dynamic>{
        'business_id': params.businessId.toString(),
        'start_date': dateFormat.format(params.startDate),
        'end_date': dateFormat.format(params.endDate),
      };

      if (params.locationIds.isNotEmpty) {
        queryParams['location_ids[]'] = params.locationIds
            .map((e) => e.toString())
            .toList();
      }
      if (params.staffIds.isNotEmpty) {
        queryParams['staff_ids[]'] = params.staffIds
            .map((e) => e.toString())
            .toList();
      }

      final response = await apiClient.get(
        '/v1/reports/work-hours',
        queryParameters: queryParams,
      );

      final report = WorkHoursReport.fromJson(response);
      state = state.copyWith(report: report, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refreshes the report using the last params.
  Future<void> refresh() async {
    final params = state.params;
    if (params != null) {
      await fetchReport(params);
    }
  }

  /// Clears the report.
  void clear() {
    state = const WorkHoursReportState();
  }
}

/// Provider for work hours report state.
final workHoursReportProvider =
    NotifierProvider<WorkHoursReportNotifier, WorkHoursReportState>(
      WorkHoursReportNotifier.new,
    );
