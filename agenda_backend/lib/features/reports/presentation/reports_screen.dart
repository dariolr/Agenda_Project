import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers/form_factor_provider.dart';
import '../../../app/widgets/staff_circle_avatar.dart';
import '../../../core/l10n/l10_extension.dart';
import '../../../core/models/service.dart';
import '../../../core/models/service_category.dart';
import '../../../core/models/staff.dart';
import '../../../core/widgets/feedback_dialog.dart';
import '../../agenda/providers/location_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../../services/providers/service_categories_provider.dart';
import '../../services/providers/services_provider.dart';
import '../../staff/providers/staff_providers.dart';
import '../domain/report_models.dart';
import '../providers/reports_filter_provider.dart';
import '../providers/reports_provider.dart';
import '../widgets/reports_header.dart';

/// Screen for viewing appointment reports.
/// Only accessible to admin/owner users.
/// Note: This screen is displayed inside ScaffoldWithNavigation,
/// so it should NOT have its own Scaffold/AppBar.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  final Set<int> _selectedLocationIds = {};
  final Set<int> _selectedStaffIds = {};
  final Set<int> _selectedServiceIds = {};
  Set<String> _selectedStatuses = {'confirmed'};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchReport();
    });
  }

  void _fetchReport() {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    // Get filter state from provider
    final filterState = ref.read(reportsFilterProvider);

    // Get current business ID
    final location = ref.read(currentLocationProvider);
    final businessId = location.businessId;

    final params = ReportParams(
      businessId: businessId,
      startDate: filterState.startDate,
      endDate: filterState.endDate,
      locationIds: _selectedLocationIds.toList(),
      staffIds: _selectedStaffIds.toList(),
      serviceIds: _selectedServiceIds.toList(),
      statuses: _selectedStatuses.toList(),
    );

    ref.read(reportsProvider.notifier).fetchReport(params);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reportState = ref.watch(reportsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Watch filter changes to refetch
    ref.listen(reportsFilterProvider, (prev, next) {
      if (prev != null &&
          (prev.startDate != next.startDate ||
              prev.endDate != next.endDate ||
              prev.selectedPreset != next.selectedPreset)) {
        _fetchReport();
      }
    });

    // Listen for errors
    ref.listen<ReportsState>(reportsProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        FeedbackDialog.showError(
          context,
          title: l10n.errorTitle,
          message: next.error!,
        );
      }
    });

    // No Scaffold here - shell provides it
    return Column(
      children: [
        // Header with period controls
        const ReportsHeader(),

        // Filters section
        _buildFiltersSection(context, colorScheme),

        // Content
        Expanded(
          child: reportState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : reportState.report == null
              ? Center(
                  child: Text(
                    l10n.reportsNoData,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : _buildReportContent(context, reportState.report!),
        ),
      ],
    );
  }

  Widget _buildFiltersSection(BuildContext context, ColorScheme colorScheme) {
    final l10n = context.l10n;
    final filterState = ref.watch(reportsFilterProvider);

    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter chips - show only if relevant
          Builder(
            builder: (context) {
              final locations = ref.watch(locationsProvider);
              final staff = ref.watch(allStaffProvider).value ?? [];
              final services = ref.watch(servicesProvider).value ?? [];

              final hasMultipleLocations = locations.length > 1;
              final hasMultipleStaff = staff.length > 1;
              final hasMultipleServices = services.length > 1;

              return Wrap(
                alignment: WrapAlignment.start,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (hasMultipleLocations)
                    _buildFilterChip(
                      context,
                      label: _selectedLocationIds.isEmpty
                          ? l10n.reportsFilterLocations
                          : '${l10n.reportsFilterLocations} (${_selectedLocationIds.length})',
                      selected: _selectedLocationIds.isNotEmpty,
                      onTap: () => _showLocationFilter(context),
                    ),
                  if (hasMultipleStaff)
                    _buildFilterChip(
                      context,
                      label: _selectedStaffIds.isEmpty
                          ? l10n.reportsFilterStaff
                          : '${l10n.reportsFilterStaff} (${_selectedStaffIds.length})',
                      selected: _selectedStaffIds.isNotEmpty,
                      onTap: () => _showStaffFilter(context),
                    ),
                  if (hasMultipleServices)
                    _buildFilterChip(
                      context,
                      label: _selectedServiceIds.isEmpty
                          ? l10n.reportsFilterServices
                          : '${l10n.reportsFilterServices} (${_selectedServiceIds.length})',
                      selected: _selectedServiceIds.isNotEmpty,
                      onTap: () => _showServiceFilter(context),
                    ),
                  _buildFilterChip(
                    context,
                    label: l10n.reportsFilterStatus,
                    selected: _selectedStatuses.length < 3,
                    onTap: () => _showStatusFilter(context),
                  ),
                ],
              );
            },
          ),

          // Full period toggle - show only on mobile/tablet (on desktop it's in AppBar)
          Builder(
            builder: (context) {
              final formFactor = ref.watch(formFactorProvider);
              final supportsFullPeriod =
                  filterState.selectedPreset != 'custom' &&
                  filterState.selectedPreset != 'today' &&
                  filterState.selectedPreset != 'last_month' &&
                  filterState.selectedPreset != 'last_3_months' &&
                  filterState.selectedPreset != 'last_6_months' &&
                  filterState.selectedPreset != 'last_year';

              if (!supportsFullPeriod || formFactor == AppFormFactor.desktop) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Switch(
                      value: filterState.useFullPeriod,
                      onChanged: (value) {
                        final notifier = ref.read(
                          reportsFilterProvider.notifier,
                        );
                        notifier.setFullPeriod(value);
                        notifier.applyPreset(filterState.selectedPreset);
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.reportsFullPeriodToggle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.onPrimaryContainer,
    );
  }

  void _showLocationFilter(BuildContext context) async {
    final locations = ref.read(locationsProvider);
    if (locations.isEmpty) return;

    final selected = await showDialog<Set<int>>(
      context: context,
      builder: (ctx) => _LocationFilterDialog(
        locations: locations,
        selected: _selectedLocationIds,
      ),
    );

    if (selected != null) {
      setState(
        () => _selectedLocationIds
          ..clear()
          ..addAll(selected),
      );
      _fetchReport();
    }
  }

  void _showStaffFilter(BuildContext context) async {
    final staff = ref.read(allStaffProvider).value ?? [];
    if (staff.isEmpty) return;

    final selected = await showDialog<Set<int>>(
      context: context,
      builder: (ctx) =>
          _StaffFilterDialog(staff: staff, selected: _selectedStaffIds),
    );

    if (selected != null) {
      setState(
        () => _selectedStaffIds
          ..clear()
          ..addAll(selected),
      );
      _fetchReport();
    }
  }

  void _showServiceFilter(BuildContext context) async {
    final services = ref.read(servicesProvider).value ?? [];
    final categories = ref.read(serviceCategoriesProvider);
    if (services.isEmpty) return;

    final selected = await showDialog<Set<int>>(
      context: context,
      builder: (ctx) => _ServiceFilterDialog(
        services: services,
        categories: categories,
        selected: _selectedServiceIds,
      ),
    );

    if (selected != null) {
      setState(
        () => _selectedServiceIds
          ..clear()
          ..addAll(selected),
      );
      _fetchReport();
    }
  }

  void _showStatusFilter(BuildContext context) async {
    final l10n = context.l10n;
    final allStatuses = {
      'confirmed': l10n.statusConfirmed,
      // 'completed': l10n.statusCompleted,
      'cancelled': l10n.statusCancelled,
    };

    final selected = await showDialog<Set<String>>(
      context: context,
      builder: (ctx) => _MultiSelectDialog<String>(
        title: l10n.reportsFilterStatus,
        items: allStatuses,
        selected: _selectedStatuses,
      ),
    );

    if (selected != null && selected.isNotEmpty) {
      setState(() => _selectedStatuses = selected);
      _fetchReport();
    }
  }

  Widget _buildReportContent(BuildContext context, AppointmentsReport report) {
    final filterState = ref.watch(reportsFilterProvider);

    // Determina quali sezioni mostrare in base al periodo selezionato
    final isSingleDay =
        filterState.selectedPreset == 'today' ||
        (filterState.startDate.year == filterState.endDate.year &&
            filterState.startDate.month == filterState.endDate.month &&
            filterState.startDate.day == filterState.endDate.day);

    // "Per Giorno della Settimana" non ha senso per un singolo giorno
    final showDayOfWeek = !isSingleDay;

    // "Per Periodo" non ha senso per un singolo giorno o per "oggi"
    final showPeriod = !isSingleDay;

    // "Per Operatore" non ha senso se filtrato per un solo staff
    final showByStaff =
        _selectedStaffIds.isEmpty || _selectedStaffIds.length > 1;

    // "Per Servizio" non ha senso se filtrato per un solo servizio
    final showByService =
        _selectedServiceIds.isEmpty || _selectedServiceIds.length > 1;

    // "Per Fascia Oraria" sempre utile tranne per periodi molto lunghi senza filtri
    final showByHour = true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          _buildSummaryCards(context, report.summary),
          const SizedBox(height: 24),

          // Breakdown sections
          if (showByStaff) ...[
            _buildBreakdownSection(
              context,
              title: context.l10n.reportsByStaff,
              child: _buildStaffTable(context, report.byStaff, report.summary),
            ),
            const SizedBox(height: 16),
          ],

          if (report.byLocation.length > 1) ...[
            _buildBreakdownSection(
              context,
              title: context.l10n.reportsByLocation,
              child: _buildLocationTable(
                context,
                report.byLocation,
                report.summary,
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (showByService) ...[
            _buildBreakdownSection(
              context,
              title: context.l10n.reportsByService,
              child: _buildServiceTable(
                context,
                report.byService,
                report.summary,
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (showDayOfWeek) ...[
            _buildBreakdownSection(
              context,
              title: context.l10n.reportsByDayOfWeek,
              child: _buildDayOfWeekTable(
                context,
                report.byDayOfWeek,
                report.summary,
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (showPeriod) ...[
            _buildBreakdownSection(
              context,
              title: context.l10n.reportsByPeriod,
              child: _buildPeriodTable(
                context,
                report.byPeriod,
                report.summary,
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (showByHour) ...[
            _buildBreakdownSection(
              context,
              title: context.l10n.reportsByHour,
              child: _buildHourTable(context, report.byHour, report.summary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, ReportSummary summary) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final currencyFormat = NumberFormat.currency(
      locale: locale,
      symbol: '€',
      decimalDigits: 2,
    );
    final numberFormat = NumberFormat.decimalPattern(locale);
    final percentFormat = NumberFormat.decimalPattern(locale);

    final cards = [
      _SummaryCardData(
        icon: Icons.event,
        label: l10n.reportsTotalAppointments,
        value: numberFormat.format(summary.totalAppointments),
        color: colorScheme.primary,
      ),
      _SummaryCardData(
        icon: Icons.euro,
        label: l10n.reportsTotalRevenue,
        value: currencyFormat.format(summary.totalRevenue),
        color: Colors.green,
      ),
      _SummaryCardData(
        icon: Icons.pie_chart,
        label: l10n.reportsOccupancyPercentage,
        value: '${percentFormat.format(summary.occupancyPercentage)}%',
        color: Colors.orange,
      ),
      _SummaryCardData(
        icon: Icons.people,
        label: l10n.reportsUniqueClients,
        value: numberFormat.format(summary.uniqueClients),
        color: Colors.purple,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800
            ? 4
            : constraints.maxWidth > 500
            ? 2
            : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            return _buildSummaryCard(context, card);
          },
        );
      },
    );
  }

  Widget _buildSummaryCard(BuildContext context, _SummaryCardData card) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: card.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(card.icon, color: card.color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  card.value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  card.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),
          child,
        ],
      ),
    );
  }

  Widget _buildStaffTable(
    BuildContext context,
    List<StaffReportRow> data,
    ReportSummary summary,
  ) {
    final l10n = context.l10n;

    final colorScheme = Theme.of(context).colorScheme;

    if (data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(l10n.reportsNoData),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: colorScheme.outline.withOpacity(0.2)),
              child: DataTable(
                dividerThickness: 0.2,
                horizontalMargin: 16,
                columns: [
                  DataColumn(label: Text(l10n.reportsColStaff)),
                  DataColumn(
                    label: Text(l10n.reportsColAppointments),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(l10n.reportsColRevenue),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(l10n.reportsColAvgRevenue),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(l10n.reportsColPercentage),
                    numeric: true,
                  ),
                ],
                rows: data.map((row) {
                  final percentage = summary.totalRevenue > 0
                      ? (row.revenue / summary.totalRevenue * 100)
                      : 0.0;
                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (row.staffColor != null)
                              Container(
                                width: 12,
                                height: 12,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: _parseColor(row.staffColor!),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            Text(row.staffName),
                          ],
                        ),
                      ),
                      DataCell(Text(row.appointments.toString())),
                      DataCell(Text('€${row.revenue.toStringAsFixed(2)}')),
                      DataCell(Text('€${row.avgRevenue.toStringAsFixed(2)}')),
                      DataCell(_buildPercentageBar(context, percentage)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationTable(
    BuildContext context,
    List<LocationReportRow> data,
    ReportSummary summary,
  ) {
    final l10n = context.l10n;

    final colorScheme = Theme.of(context).colorScheme;

    if (data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(l10n.reportsNoData),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: colorScheme.outline.withOpacity(0.2)),
              child: DataTable(
                dividerThickness: 0.2,
                horizontalMargin: 16,
                columns: [
                  DataColumn(label: Text(l10n.reportsColLocation)),
                  DataColumn(
                    label: Text(l10n.reportsColAppointments),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(l10n.reportsColRevenue),
                    numeric: true,
                  ),
                  DataColumn(label: Text(l10n.reportsColHours), numeric: true),
                  DataColumn(
                    label: Text(l10n.reportsColPercentage),
                    numeric: true,
                  ),
                ],
                rows: data.map((row) {
                  final percentage = summary.totalRevenue > 0
                      ? (row.revenue / summary.totalRevenue * 100)
                      : 0.0;
                  return DataRow(
                    cells: [
                      DataCell(Text(row.locationName)),
                      DataCell(Text(row.appointments.toString())),
                      DataCell(Text('€${row.revenue.toStringAsFixed(2)}')),
                      DataCell(Text('${row.hours.toStringAsFixed(1)}h')),
                      DataCell(_buildPercentageBar(context, percentage)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildServiceTable(
    BuildContext context,
    List<ServiceReportRow> data,
    ReportSummary summary,
  ) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    if (data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(l10n.reportsNoData),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: colorScheme.outline.withOpacity(0.2)),
              child: DataTable(
                dividerThickness: 0.2,
                horizontalMargin: 16,
                columns: [
                  DataColumn(label: Text(l10n.reportsColService)),
                  DataColumn(label: Text(l10n.reportsColCategory)),
                  DataColumn(
                    label: Text(l10n.reportsColAppointments),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(l10n.reportsColRevenue),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(l10n.reportsColPercentage),
                    numeric: true,
                  ),
                ],
                rows: data.map((row) {
                  final percentage = summary.totalAppointments > 0
                      ? (row.appointments / summary.totalAppointments * 100)
                      : 0.0;
                  return DataRow(
                    cells: [
                      DataCell(Text(row.serviceName)),
                      DataCell(Text(row.categoryName ?? '-')),
                      DataCell(Text(row.appointments.toString())),
                      DataCell(Text('€${row.revenue.toStringAsFixed(2)}')),
                      DataCell(_buildPercentageBar(context, percentage)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDayOfWeekTable(
    BuildContext context,
    List<DayOfWeekReportRow> data,
    ReportSummary summary,
  ) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    if (data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(l10n.reportsNoData),
      );
    }

    final dayNames = [
      l10n.dayMonday,
      l10n.dayTuesday,
      l10n.dayWednesday,
      l10n.dayThursday,
      l10n.dayFriday,
      l10n.daySaturday,
      l10n.daySunday,
    ];

    // Sort by ISO weekday
    final sortedData = List<DayOfWeekReportRow>.from(data)
      ..sort((a, b) => a.isoWeekday.compareTo(b.isoWeekday));

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: colorScheme.outline.withOpacity(0.2)),
              child: DataTable(
                dividerThickness: 0.2,
                horizontalMargin: 16,
                columns: [
                  DataColumn(label: Text(l10n.reportsColDay)),
                  DataColumn(
                    label: Text(l10n.reportsColAppointments),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(l10n.reportsColRevenue),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(l10n.reportsColPercentage),
                    numeric: true,
                  ),
                ],
                rows: sortedData.map((row) {
                  final dayName = dayNames[row.isoWeekday - 1];
                  final percentage = summary.totalAppointments > 0
                      ? (row.appointments / summary.totalAppointments * 100)
                      : 0.0;
                  return DataRow(
                    cells: [
                      DataCell(Text(dayName)),
                      DataCell(Text(row.appointments.toString())),
                      DataCell(Text('€${row.revenue.toStringAsFixed(2)}')),
                      DataCell(_buildPercentageBar(context, percentage)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPeriodTable(
    BuildContext context,
    PeriodBreakdown breakdown,
    ReportSummary summary,
  ) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final data = breakdown.data;

    if (data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(l10n.reportsNoData),
      );
    }

    final dateFormat = switch (breakdown.granularity) {
      'day' => DateFormat('dd/MM'),
      'week' => DateFormat('dd/MM'),
      'month' => DateFormat('MMM yyyy'),
      _ => DateFormat('dd/MM/yyyy'),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: colorScheme.outline.withOpacity(0.2)),
              child: DataTable(
                dividerThickness: 0.2,
                horizontalMargin: 16,
                columns: [
                  DataColumn(label: Text(l10n.reportsColPeriod)),
                  DataColumn(
                    label: Text(l10n.reportsColAppointments),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(l10n.reportsColRevenue),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(l10n.reportsColPercentage),
                    numeric: true,
                  ),
                ],
                rows: data.map((row) {
                  String periodLabel = dateFormat.format(row.periodStart);
                  if (breakdown.granularity == 'week') {
                    final endOfWeek = row.periodStart.add(
                      const Duration(days: 6),
                    );
                    periodLabel =
                        '${dateFormat.format(row.periodStart)} - ${dateFormat.format(endOfWeek)}';
                  }
                  final percentage = summary.totalAppointments > 0
                      ? (row.appointments / summary.totalAppointments * 100)
                      : 0.0;
                  return DataRow(
                    cells: [
                      DataCell(Text(periodLabel)),
                      DataCell(Text(row.appointments.toString())),
                      DataCell(Text('€${row.revenue.toStringAsFixed(2)}')),
                      DataCell(_buildPercentageBar(context, percentage)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHourTable(
    BuildContext context,
    List<HourReportRow> data,
    ReportSummary summary,
  ) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    if (data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(l10n.reportsNoData),
      );
    }

    // Sort by hour
    final sortedData = List<HourReportRow>.from(data)
      ..sort((a, b) => a.hour.compareTo(b.hour));

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: colorScheme.outline.withOpacity(0.2)),
              child: DataTable(
                dividerThickness: 0.2,
                horizontalMargin: 16,
                columns: [
                  DataColumn(label: Text(l10n.reportsColHour)),
                  DataColumn(
                    label: Text(l10n.reportsColAppointments),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(l10n.reportsColRevenue),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(l10n.reportsColPercentage),
                    numeric: true,
                  ),
                ],
                rows: sortedData.map((row) {
                  final hourLabel = '${row.hour.toString().padLeft(2, '0')}:00';
                  final percentage = summary.totalAppointments > 0
                      ? (row.appointments / summary.totalAppointments * 100)
                      : 0.0;
                  return DataRow(
                    cells: [
                      DataCell(Text(hourLabel)),
                      DataCell(Text(row.appointments.toString())),
                      DataCell(Text('€${row.revenue.toStringAsFixed(2)}')),
                      DataCell(_buildPercentageBar(context, percentage)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPercentageBar(BuildContext context, double percentage) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(colorScheme.primary),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('${percentage.toStringAsFixed(0)}%'),
      ],
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }
}

class _SummaryCardData {
  const _SummaryCardData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
}

// ============================================================================
// LOCATION FILTER DIALOG
// ============================================================================

class _LocationFilterDialog extends StatefulWidget {
  const _LocationFilterDialog({
    required this.locations,
    required this.selected,
  });

  final List<dynamic> locations;
  final Set<int> selected;

  @override
  State<_LocationFilterDialog> createState() => _LocationFilterDialogState();
}

class _LocationFilterDialogState extends State<_LocationFilterDialog> {
  late Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<int>.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(l10n.reportsFilterLocations),
      content: SizedBox(
        width: 350,
        height: 400,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selected = widget.locations
                          .map((l) => l.id as int)
                          .toSet();
                    });
                  },
                  child: Text(l10n.actionSelectAll),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _selected.clear());
                  },
                  child: Text(l10n.actionDeselectAll),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: widget.locations.length,
                itemBuilder: (context, index) {
                  final location = widget.locations[index];
                  final isSelected = _selected.contains(location.id);

                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(location.name),
                    subtitle: location.address != null
                        ? Text(
                            location.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selected.add(location.id);
                          } else {
                            _selected.remove(location.id);
                          }
                        });
                      },
                    ),
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selected.remove(location.id);
                        } else {
                          _selected.add(location.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: Text(l10n.actionApply),
        ),
      ],
    );
  }
}

// ============================================================================
// STAFF FILTER DIALOG - with avatar like in agenda
// ============================================================================

class _StaffFilterDialog extends StatefulWidget {
  const _StaffFilterDialog({required this.staff, required this.selected});

  final List<Staff> staff;
  final Set<int> selected;

  @override
  State<_StaffFilterDialog> createState() => _StaffFilterDialogState();
}

class _StaffFilterDialogState extends State<_StaffFilterDialog> {
  late Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<int>.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.reportsFilterStaff),
      content: SizedBox(
        width: 350,
        height: 400,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selected = widget.staff.map((s) => s.id).toSet();
                    });
                  },
                  child: Text(l10n.actionSelectAll),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _selected.clear());
                  },
                  child: Text(l10n.actionDeselectAll),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: widget.staff.length,
                itemBuilder: (context, index) {
                  final staff = widget.staff[index];
                  final isSelected = _selected.contains(staff.id);

                  return ListTile(
                    leading: StaffCircleAvatar(
                      height: 40,
                      color: staff.color,
                      isHighlighted: isSelected,
                      initials: staff.initials,
                    ),
                    title: Text(staff.displayName),
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selected.add(staff.id);
                          } else {
                            _selected.remove(staff.id);
                          }
                        });
                      },
                    ),
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selected.remove(staff.id);
                        } else {
                          _selected.add(staff.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: Text(l10n.actionApply),
        ),
      ],
    );
  }
}

// ============================================================================
// SERVICE FILTER DIALOG - organized by categories
// ============================================================================

class _ServiceFilterDialog extends StatefulWidget {
  const _ServiceFilterDialog({
    required this.services,
    required this.categories,
    required this.selected,
  });

  final List<Service> services;
  final List<ServiceCategory> categories;
  final Set<int> selected;

  @override
  State<_ServiceFilterDialog> createState() => _ServiceFilterDialogState();
}

class _ServiceFilterDialogState extends State<_ServiceFilterDialog> {
  late Set<int> _selected;
  final Set<int> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    _selected = Set<int>.from(widget.selected);
    // Expand categories that have selected services
    for (final service in widget.services) {
      if (_selected.contains(service.id)) {
        _expandedCategories.add(service.categoryId);
      }
    }
  }

  Map<int, List<Service>> _groupServicesByCategory() {
    final grouped = <int, List<Service>>{};
    for (final service in widget.services) {
      grouped.putIfAbsent(service.categoryId, () => []).add(service);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final groupedServices = _groupServicesByCategory();

    // Sort categories by sort_order
    final sortedCategories = widget.categories.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    // Get category IDs that have services
    final categoryIdsWithServices = groupedServices.keys.toSet();

    // Build list of items to display
    final displayItems = <_CategoryDisplayItem>[];
    for (final cat in sortedCategories) {
      if (categoryIdsWithServices.contains(cat.id)) {
        displayItems.add(_CategoryDisplayItem(id: cat.id, name: cat.name));
      }
    }
    // Add "Altro" category (id=0) if it exists
    if (categoryIdsWithServices.contains(0)) {
      displayItems.add(const _CategoryDisplayItem(id: 0, name: 'Altro'));
    }

    return AlertDialog(
      title: Text(l10n.reportsFilterServices),
      content: SizedBox(
        width: 400,
        height: 500,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selected = widget.services.map((s) => s.id).toSet();
                    });
                  },
                  child: Text(l10n.actionSelectAll),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _selected.clear());
                  },
                  child: Text(l10n.actionDeselectAll),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: displayItems.length,
                itemBuilder: (context, index) {
                  final categoryItem = displayItems[index];
                  final categoryId = categoryItem.id;
                  final categoryName = categoryItem.name;
                  final services = groupedServices[categoryId] ?? [];

                  if (services.isEmpty) return const SizedBox.shrink();

                  final isExpanded = _expandedCategories.contains(categoryId);
                  final selectedInCategory = services
                      .where((s) => _selected.contains(s.id))
                      .length;
                  final allSelectedInCategory =
                      selectedInCategory == services.length;
                  final someSelectedInCategory =
                      selectedInCategory > 0 && !allSelectedInCategory;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category header
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedCategories.remove(categoryId);
                            } else {
                              _expandedCategories.add(categoryId);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          color: colorScheme.surfaceContainerHighest
                              .withOpacity(0.5),
                          child: Row(
                            children: [
                              Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  categoryName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '$selectedInCategory/${services.length}',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Checkbox(
                                value: allSelectedInCategory
                                    ? true
                                    : someSelectedInCategory
                                    ? null
                                    : false,
                                tristate: true,
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true || checked == null) {
                                      // Select all in category
                                      for (final s in services) {
                                        _selected.add(s.id);
                                      }
                                    } else {
                                      // Deselect all in category
                                      for (final s in services) {
                                        _selected.remove(s.id);
                                      }
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Services list (if expanded)
                      if (isExpanded)
                        ...services.map((service) {
                          final isSelected = _selected.contains(service.id);
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.only(
                              left: 40,
                              right: 16,
                            ),
                            title: Text(service.name),
                            subtitle: service.price != null
                                ? Text(
                                    '€${service.price!.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  )
                                : null,
                            trailing: Checkbox(
                              value: isSelected,
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selected.add(service.id);
                                  } else {
                                    _selected.remove(service.id);
                                  }
                                });
                              },
                            ),
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selected.remove(service.id);
                                } else {
                                  _selected.add(service.id);
                                }
                              });
                            },
                          );
                        }),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: Text(l10n.actionApply),
        ),
      ],
    );
  }
}

class _CategoryDisplayItem {
  const _CategoryDisplayItem({required this.id, required this.name});
  final int id;
  final String name;
}

// ============================================================================
// GENERIC MULTI-SELECT DIALOG (for status filter)
// ============================================================================

/// Multi-select dialog for filters.
class _MultiSelectDialog<T> extends StatefulWidget {
  const _MultiSelectDialog({
    required this.title,
    required this.items,
    required this.selected,
  });

  final String title;
  final Map<T, String> items;
  final Set<T> selected;

  @override
  State<_MultiSelectDialog<T>> createState() => _MultiSelectDialogState<T>();
}

class _MultiSelectDialogState<T> extends State<_MultiSelectDialog<T>> {
  late Set<T> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<T>.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 300,
        height: 400,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selected = widget.items.keys.toSet();
                    });
                  },
                  child: Text(l10n.actionSelectAll),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selected.clear();
                    });
                  },
                  child: Text(l10n.actionDeselectAll),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: widget.items.entries.map((entry) {
                  return CheckboxListTile(
                    title: Text(entry.value),
                    value: _selected.contains(entry.key),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selected.add(entry.key);
                        } else {
                          _selected.remove(entry.key);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: Text(l10n.actionApply),
        ),
      ],
    );
  }
}
