import 'package:agenda_backend/core/l10n/l10_extension.dart';
import 'package:agenda_backend/core/models/availability_exception.dart';
import 'package:agenda_backend/core/models/appointment.dart';
import 'package:agenda_backend/core/models/staff.dart';
import 'package:agenda_backend/core/models/staff_planning.dart'
    show StaffPlanning;
import 'package:agenda_backend/core/utils/color_utils.dart';
import 'package:agenda_backend/core/widgets/app_buttons.dart';
import 'package:agenda_backend/app/providers/form_factor_provider.dart';
import 'package:agenda_backend/features/business/providers/location_closures_provider.dart';
import 'package:agenda_backend/features/agenda/domain/staff_filter_mode.dart';
import 'package:agenda_backend/features/agenda/mappers/appointments_by_day.dart';
import 'package:agenda_backend/features/agenda/providers/appointment_providers.dart';
import 'package:agenda_backend/features/agenda/providers/business_providers.dart';
import 'package:agenda_backend/features/agenda/providers/date_range_provider.dart';
import 'package:agenda_backend/features/agenda/providers/layout_config_provider.dart';
import 'package:agenda_backend/features/agenda/providers/location_providers.dart';
import 'package:agenda_backend/features/agenda/providers/staff_filter_providers.dart';
import 'package:agenda_backend/features/agenda/providers/tenant_time_provider.dart';
import 'package:agenda_backend/features/agenda/providers/weekly_appointments_provider.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/widgets/appointment_card_base.dart';
import 'package:agenda_backend/features/agenda/presentation/widgets/appointment_dialog.dart';
import 'package:agenda_backend/features/agenda/utils/week_range.dart';
import 'package:agenda_backend/features/services/providers/services_provider.dart';
import 'package:agenda_backend/features/staff/providers/availability_exceptions_provider.dart';
import 'package:agenda_backend/features/staff/providers/staff_planning_provider.dart';
import 'package:agenda_backend/features/staff/providers/staff_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class WeeklyAppointmentsView extends ConsumerWidget {
  const WeeklyAppointmentsView({
    super.key,
    required this.staffList,
    required this.staffFilterMode,
    required this.autoScrollRequestId,
    required this.autoScrollTargetDate,
  });

  final List<Staff> staffList;
  final StaffFilterMode staffFilterMode;
  final int autoScrollRequestId;
  final DateTime? autoScrollTargetDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(currentLocationProvider);
    if (location.id <= 0) {
      return const SizedBox.shrink();
    }

    final business = ref.watch(currentBusinessProvider);
    if (business.id <= 0) {
      return const SizedBox.shrink();
    }

    final anchorDate = ref.watch(agendaDateProvider);
    final timezone = ref.watch(effectiveTenantTimezoneProvider);
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final weekRange = computeWeekRange(
      anchorDate,
      timezone,
      localeTag: localeTag,
    );
    final request = WeeklyAppointmentsRequest(
      weekStart: weekRange.start,
      locationId: location.id,
      businessId: business.id,
    );
    final weeklyAppointmentsAsync = ref.watch(
      weeklyAppointmentsProvider(request),
    );
    final previousResult = weeklyAppointmentsAsync.maybeWhen(
      data: (result) => result,
      orElse: () => null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: weeklyAppointmentsAsync.when(
            data: (result) => _WeeklyAppointmentsBody(
              weekRange: weekRange,
              appointments: result.appointments,
              staffList: staffList,
              staffFilterMode: staffFilterMode,
              autoScrollRequestId: autoScrollRequestId,
              autoScrollTargetDate: autoScrollTargetDate,
            ),
            loading: () =>
                previousResult != null
                    ? _WeeklyAppointmentsBody(
                        weekRange: weekRange,
                        appointments: previousResult.appointments,
                        staffList: staffList,
                        staffFilterMode: staffFilterMode,
                        autoScrollRequestId: autoScrollRequestId,
                        autoScrollTargetDate: autoScrollTargetDate,
                      )
                    : const Center(child: CircularProgressIndicator()),
            error: (_, __) => _WeeklyAppointmentsError(request: request),
          ),
        ),
      ],
    );
  }
}

class _WeeklyAppointmentsBody extends ConsumerStatefulWidget {
  const _WeeklyAppointmentsBody({
    required this.weekRange,
    required this.appointments,
    required this.staffList,
    required this.staffFilterMode,
    required this.autoScrollRequestId,
    required this.autoScrollTargetDate,
  });

  final WeekRange weekRange;
  final List<Appointment> appointments;
  final List<Staff> staffList;
  final StaffFilterMode staffFilterMode;
  final int autoScrollRequestId;
  final DateTime? autoScrollTargetDate;
  static const double _daySpacing = 12;
  static const double _defaultDayColumnWidth = 280;
  static const double _emptyDayColumnWidth = 104;
  static const int _planningSlotMinutes = StaffPlanning.planningStepMinutes;
  static const int _planningTotalSlots = (24 * 60) ~/ _planningSlotMinutes;

  @override
  ConsumerState<_WeeklyAppointmentsBody> createState() =>
      _WeeklyAppointmentsBodyState();

  List<Staff> resolveEffectiveStaffList(WidgetRef ref) {
    if (staffFilterMode != StaffFilterMode.onDutyTeam || staffList.isNotEmpty) {
      return staffList;
    }

    final allStaff = ref.watch(staffForCurrentLocationProvider);
    return [
      for (final staff in allStaff)
        if (_hasAnyAvailabilityInWeek(ref, staff.id)) staff,
    ];
  }

  bool _hasAnyAvailabilityInWeek(WidgetRef ref, int staffId) {
    for (final day in weekRange.days) {
      if (_hasAvailabilityForDay(ref, staffId: staffId, day: day)) {
        return true;
      }
    }
    return false;
  }

  bool _hasAvailabilityForDay(
    WidgetRef ref, {
    required int staffId,
    required DateTime day,
  }) {
    if (ref.watch(isDateClosedProvider(day))) {
      return false;
    }

    ref.watch(ensureStaffPlanningLoadedProvider(staffId));

    final baseSlots = ref.watch(
      planningSlotsForDateProvider((staffId: staffId, date: day)),
    );
    if (baseSlots == null) {
      return false;
    }

    var finalSlots = Set<int>.from(baseSlots);
    final exceptions = ref.watch(
      exceptionsForStaffOnDateProvider((staffId: staffId, date: day)),
    );

    for (final exception in exceptions) {
      final exceptionSlots = exception.toSlotIndices(
        minutesPerSlot: _planningSlotMinutes,
        totalSlotsPerDay: _planningTotalSlots,
      );
      if (exception.type == AvailabilityExceptionType.available) {
        finalSlots = finalSlots.union(exceptionSlots);
      } else {
        finalSlots = finalSlots.difference(exceptionSlots);
      }
    }

    return finalSlots.isNotEmpty;
  }
}

class _WeeklyAppointmentsBodyState extends ConsumerState<_WeeklyAppointmentsBody> {
  late final ScrollController _weekColumnsController;
  int _lastHandledAutoScrollRequestId = 0;

  @override
  void initState() {
    super.initState();
    _weekColumnsController = ScrollController();
  }

  @override
  void dispose() {
    _weekColumnsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStaffList = widget.resolveEffectiveStaffList(ref);
    final allowedStaffIds = effectiveStaffList.map((staff) => staff.id).toSet();
    final filteredAppointments = [
      for (final appointment in widget.appointments)
        if (allowedStaffIds.contains(appointment.staffId)) appointment,
    ];

    if (effectiveStaffList.isEmpty) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.94),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.staffFilterMode == StaffFilterMode.onDutyTeam
                    ? context.l10n.agendaNoOnDutyTeamTitle
                    : context.l10n.agendaNoSelectedTeamTitle,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (widget.staffFilterMode != StaffFilterMode.allTeam) ...[
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    ref
                        .read(staffFilterModeProvider.notifier)
                        .set(StaffFilterMode.allTeam);
                  },
                  child: Text(context.l10n.agendaShowAllTeamButton),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final appointmentsByDay = mapAppointmentsByDay(
      filteredAppointments,
      weekRange: widget.weekRange,
    );
    final showStaffNameFooter = effectiveStaffList.length > 1;
    final dayColumns = [
      for (final day in widget.weekRange.days)
        (day: day, appointments: appointmentsByDay[day] ?? const <Appointment>[]),
    ];
    final visibleDayColumns = dayColumns;

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final formFactor = ref.watch(formFactorProvider);
          final useHorizontalCards =
              formFactor == AppFormFactor.desktop ||
              constraints.maxWidth < 1040;
          if (useHorizontalCards) {
            final isMobile = formFactor == AppFormFactor.mobile;
            final mobileDayColumnWidth = isMobile
                ? ((constraints.maxWidth - (_WeeklyAppointmentsBody._daySpacing * 3)) / 2)
                      .clamp(120.0, double.infinity)
                      .toDouble()
                : null;
            _maybeAutoScrollToTargetDay(
              targetDate: widget.autoScrollTargetDate,
              visibleDayColumns: visibleDayColumns,
              isMobile: isMobile,
              mobileDayColumnWidth: mobileDayColumnWidth,
            );
            return ListView.separated(
              controller: _weekColumnsController,
              scrollDirection: Axis.horizontal,
              padding: isMobile
                  ? const EdgeInsets.symmetric(
                      horizontal: _WeeklyAppointmentsBody._daySpacing,
                    )
                  : EdgeInsets.zero,
              itemCount: visibleDayColumns.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: _WeeklyAppointmentsBody._daySpacing),
              itemBuilder: (context, index) {
                final column = visibleDayColumns[index];
                return SizedBox(
                  width:
                      mobileDayColumnWidth ??
                      (column.appointments.isEmpty
                          ? _WeeklyAppointmentsBody._emptyDayColumnWidth
                          : _WeeklyAppointmentsBody._defaultDayColumnWidth),
                  child: _WeeklyDayColumn(
                    day: column.day,
                    appointments: column.appointments,
                    showStaffNameFooter: showStaffNameFooter,
                  ),
                );
              },
            );
          }

          final emptyDaysCount = visibleDayColumns
              .where((entry) => entry.appointments.isEmpty)
              .length;
          final nonEmptyDaysCount = visibleDayColumns.length - emptyDaysCount;
          final totalSpacing =
              _WeeklyAppointmentsBody._daySpacing *
              (visibleDayColumns.isNotEmpty ? visibleDayColumns.length - 1 : 0);
          final fixedEmptyWidth =
              _WeeklyAppointmentsBody._emptyDayColumnWidth * emptyDaysCount;
          final remainingWidth =
              constraints.maxWidth - totalSpacing - fixedEmptyWidth;

          if (nonEmptyDaysCount <= 0 || remainingWidth <= 0) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < visibleDayColumns.length; i++) ...[
                  if (i > 0)
                    const SizedBox(width: _WeeklyAppointmentsBody._daySpacing),
                  Expanded(
                    child: _WeeklyDayColumn(
                      day: visibleDayColumns[i].day,
                      appointments: visibleDayColumns[i].appointments,
                      showStaffNameFooter: showStaffNameFooter,
                    ),
                  ),
                ],
              ],
            );
          }

          final nonEmptyDayWidth = remainingWidth / nonEmptyDaysCount;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < visibleDayColumns.length; i++) ...[
                if (i > 0)
                  const SizedBox(width: _WeeklyAppointmentsBody._daySpacing),
                SizedBox(
                  width: visibleDayColumns[i].appointments.isEmpty
                      ? _WeeklyAppointmentsBody._emptyDayColumnWidth
                      : nonEmptyDayWidth,
                  child: _WeeklyDayColumn(
                    day: visibleDayColumns[i].day,
                    appointments: visibleDayColumns[i].appointments,
                    showStaffNameFooter: showStaffNameFooter,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _maybeAutoScrollToTargetDay({
    required DateTime? targetDate,
    required List<({DateTime day, List<Appointment> appointments})>
    visibleDayColumns,
    required bool isMobile,
    required double? mobileDayColumnWidth,
  }) {
    final requestId = widget.autoScrollRequestId;
    if (requestId <= 0 ||
        requestId == _lastHandledAutoScrollRequestId ||
        targetDate == null) {
      return;
    }

    final targetIndex = visibleDayColumns.indexWhere(
      (entry) => DateUtils.isSameDay(entry.day, targetDate),
    );
    if (targetIndex < 0) {
      return;
    }
    _lastHandledAutoScrollRequestId = requestId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_weekColumnsController.hasClients) {
        return;
      }

      final horizontalPadding =
          isMobile ? _WeeklyAppointmentsBody._daySpacing : 0.0;
      final previousWidth = List<double>.generate(targetIndex, (index) {
        if (mobileDayColumnWidth != null) {
          return mobileDayColumnWidth;
        }
        return visibleDayColumns[index].appointments.isEmpty
            ? _WeeklyAppointmentsBody._emptyDayColumnWidth
            : _WeeklyAppointmentsBody._defaultDayColumnWidth;
      }).fold<double>(0.0, (sum, width) => sum + width);
      final spacingBefore =
          _WeeklyAppointmentsBody._daySpacing * targetIndex;
      final rawOffset = horizontalPadding + previousWidth + spacingBefore;
      final offsetWithLeftMargin = rawOffset - _WeeklyAppointmentsBody._daySpacing;
      final position = _weekColumnsController.position;
      final clampedOffset = offsetWithLeftMargin.clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      _weekColumnsController.jumpTo(clampedOffset);
    });
  }
}

class _WeeklyDayColumn extends ConsumerStatefulWidget {
  const _WeeklyDayColumn({
    required this.day,
    required this.appointments,
    required this.showStaffNameFooter,
  });

  final DateTime day;
  final List<Appointment> appointments;
  final bool showStaffNameFooter;

  @override
  ConsumerState<_WeeklyDayColumn> createState() => _WeeklyDayColumnState();
}

class _WeeklyDayColumnState extends ConsumerState<_WeeklyDayColumn> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final label = DateFormat('EEE d MMM', localeTag).format(widget.day);
    final borderColor = theme.dividerColor.withOpacity(0.24);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Divider(height: 0.5, thickness: 0.5, color: borderColor),
          Expanded(
            child: widget.appointments.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        context.l10n.clientAppointmentsEmpty,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: widget.appointments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final appointment = widget.appointments[index];
                      return _WeeklyAppointmentTile(
                        day: widget.day,
                        appointment: appointment,
                        showStaffNameFooter: widget.showStaffNameFooter,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyAppointmentTile extends ConsumerWidget {
  const _WeeklyAppointmentTile({
    required this.day,
    required this.appointment,
    required this.showStaffNameFooter,
  });

  static const _tileHeight = 62.0;
  static const _staffFooterHeight = 18.0;

  final DateTime day;
  final Appointment appointment;
  final bool showStaffNameFooter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _resolveAppointmentColor(context, ref, appointment);
    final staffName = _resolveStaffDisplayName(ref, appointment.staffId);
    final theme = Theme.of(context);
    final footerHeight = showStaffNameFooter ? _staffFooterHeight : 0.0;
    final cardBorderRadius = showStaffNameFooter
        ? const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          )
        : const BorderRadius.all(Radius.circular(8));

    return SizedBox(
      height: _tileHeight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _handleTap(context, ref),
        child: Column(
          children: [
            SizedBox(
              height: _tileHeight - footerHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AppointmentCard(
                        appointment: appointment,
                        color: color,
                        showExtraMinutesBand: false,
                        borderRadius: cardBorderRadius,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (showStaffNameFooter)
              Container(
                height: _staffFooterHeight,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(8),
                  ),
                  border: Border(
                    left: BorderSide(color: color),
                    right: BorderSide(color: color),
                    bottom: BorderSide(color: color),
                  ),
                ),
                child: Text(
                  staffName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color:
                        ThemeData.estimateBrightnessForColor(color) ==
                            Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _resolveAppointmentColor(
    BuildContext context,
    WidgetRef ref,
    Appointment currentAppointment,
  ) {
    final staff = ref
        .watch(staffForCurrentLocationProvider)
        .cast<Staff?>()
        .firstWhere(
          (entry) => entry?.id == currentAppointment.staffId,
          orElse: () => null,
        );
    final fallbackColor =
        staff?.color ?? Theme.of(context).colorScheme.primary.withOpacity(0.8);

    final layoutConfig = ref.watch(layoutConfigProvider);
    if (!layoutConfig.useServiceColorsForAppointments) {
      return fallbackColor;
    }

    final variantsAsync = ref.watch(serviceVariantsProvider);
    if (variantsAsync.isLoading && !variantsAsync.hasValue) {
      return Theme.of(context).colorScheme.primary;
    }

    final variants = variantsAsync.value ?? const [];
    final serviceColorMap = <int, Color>{};
    for (final variant in variants) {
      final colorHex = variant.colorHex;
      if (colorHex == null || colorHex.isEmpty) continue;
      serviceColorMap[variant.serviceId] = ColorUtils.fromHex(colorHex);
    }

    return serviceColorMap[currentAppointment.serviceId] ?? fallbackColor;
  }

  String _resolveStaffDisplayName(WidgetRef ref, int staffId) {
    final staff = ref
        .watch(staffForCurrentLocationProvider)
        .cast<Staff?>()
        .firstWhere((entry) => entry?.id == staffId, orElse: () => null);
    return staff?.displayName ?? '-';
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    await showAppointmentDialog(context, ref, initial: appointment);
    if (!context.mounted) return;

    ref.invalidate(appointmentsProvider);

    final location = ref.read(currentLocationProvider);
    final business = ref.read(currentBusinessProvider);
    if (location.id <= 0 || business.id <= 0) return;

    final anchorDate = ref.read(agendaDateProvider);
    final timezone = ref.read(effectiveTenantTimezoneProvider);
    final weekRange = computeWeekRange(anchorDate, timezone);
    ref.invalidate(
      weeklyAppointmentsProvider(
        WeeklyAppointmentsRequest(
          weekStart: weekRange.start,
          locationId: location.id,
          businessId: business.id,
        ),
      ),
    );
  }
}

class _WeeklyAppointmentsError extends ConsumerWidget {
  const _WeeklyAppointmentsError({required this.request});

  final WeeklyAppointmentsRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.agendaWeeklyLoadError, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          AppOutlinedActionButton(
            onPressed: () =>
                ref.invalidate(weeklyAppointmentsProvider(request)),
            child: Text(context.l10n.actionRetry),
          ),
        ],
      ),
    );
  }
}
