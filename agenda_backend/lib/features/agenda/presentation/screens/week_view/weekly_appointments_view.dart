import 'package:agenda_backend/app/providers/form_factor_provider.dart';
import 'package:agenda_backend/core/l10n/date_time_formats.dart';
import 'package:agenda_backend/core/l10n/l10_extension.dart';
import 'package:agenda_backend/core/models/appointment.dart';
import 'package:agenda_backend/core/models/availability_exception.dart';
import 'package:agenda_backend/core/models/class_event.dart';
import 'package:agenda_backend/core/models/staff.dart';
import 'package:agenda_backend/core/models/staff_planning.dart'
    show StaffPlanning;
import 'package:agenda_backend/core/utils/color_utils.dart';
import 'package:agenda_backend/core/widgets/app_buttons.dart';
import 'package:agenda_backend/features/agenda/domain/staff_filter_mode.dart';
import 'package:agenda_backend/features/agenda/mappers/appointments_by_day.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/week_view/single_staff_weekly_timeline.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/widgets/appointment_card_base.dart';
import 'package:agenda_backend/features/agenda/presentation/widgets/appointment_dialog.dart';
import 'package:agenda_backend/features/agenda/providers/appointment_providers.dart';
import 'package:agenda_backend/features/agenda/providers/agenda_display_settings_provider.dart';
import 'package:agenda_backend/features/agenda/providers/business_providers.dart';
import 'package:agenda_backend/features/agenda/providers/date_range_provider.dart';
import 'package:agenda_backend/features/agenda/providers/location_providers.dart';
import 'package:agenda_backend/features/agenda/providers/staff_filter_providers.dart';
import 'package:agenda_backend/features/agenda/providers/tenant_time_provider.dart';
import 'package:agenda_backend/features/agenda/providers/weekly_appointments_provider.dart';
import 'package:agenda_backend/features/agenda/utils/week_range.dart';
import 'package:agenda_backend/features/business/providers/location_closures_provider.dart';
import 'package:agenda_backend/features/class_events/providers/class_events_providers.dart';
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
    final weeklyClassEventsAsync = ref.watch(
      classEventsForLocationWeekProvider((
        weekStart: weekRange.start,
        locationId: location.id,
        businessId: business.id,
      )),
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
              classEvents: weeklyClassEventsAsync.value ?? const [],
              staffList: staffList,
              staffFilterMode: staffFilterMode,
              autoScrollRequestId: autoScrollRequestId,
              autoScrollTargetDate: autoScrollTargetDate,
            ),
            loading: () => previousResult != null
                ? _WeeklyAppointmentsBody(
                    weekRange: weekRange,
                    appointments: previousResult.appointments,
                    classEvents: weeklyClassEventsAsync.value ?? const [],
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
    required this.classEvents,
    required this.staffList,
    required this.staffFilterMode,
    required this.autoScrollRequestId,
    required this.autoScrollTargetDate,
  });

  final WeekRange weekRange;
  final List<Appointment> appointments;
  final List<ClassEvent> classEvents;
  final List<Staff> staffList;
  final StaffFilterMode staffFilterMode;
  final int autoScrollRequestId;
  final DateTime? autoScrollTargetDate;
  static const double _daySpacing = 12;
  static const double _defaultDayColumnWidth = 280;
  static const double _emptyDayColumnWidth = 104;
  static const double _maxDesktopDayColumnWidth = 380;
  static const double _maxDesktopEmptyDayColumnWidth = 180;
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

class _WeeklyAppointmentsBodyState
    extends ConsumerState<_WeeklyAppointmentsBody> {
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
    final showCancelled = ref.watch(effectiveShowCancelledAppointmentsProvider);
    final filteredAppointments = [
      for (final appointment in widget.appointments)
        if (allowedStaffIds.contains(appointment.staffId) &&
            (showCancelled || !appointment.isCancelled))
          appointment,
    ];
    final filteredClassEvents = [
      for (final event in widget.classEvents)
        if (allowedStaffIds.contains(event.staffId) &&
            event.status.toUpperCase() != 'CANCELLED')
          event,
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
    final classEventsByDay = _mapClassEventsByDay(
      filteredClassEvents,
      weekRange: widget.weekRange,
    );
    final showStaffNameFooter = effectiveStaffList.length > 1;
    final dayColumns = [
      for (final day in widget.weekRange.days)
        (
          day: day,
          appointments: appointmentsByDay[day] ?? const <Appointment>[],
          classEvents: classEventsByDay[day] ?? const <ClassEvent>[],
        ),
    ];
    final visibleDayColumns = dayColumns;

    if (effectiveStaffList.length == 1) {
      return SingleStaffWeeklyTimeline(
        weekRange: widget.weekRange,
        dayColumns: visibleDayColumns,
        staffId: effectiveStaffList.first.id,
        autoScrollRequestId: widget.autoScrollRequestId,
        autoScrollTargetDate: widget.autoScrollTargetDate,
      );
    }

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
                ? ((constraints.maxWidth -
                              (_WeeklyAppointmentsBody._daySpacing * 3)) /
                          2)
                      .clamp(120.0, double.infinity)
                      .toDouble()
                : null;
            final resolvedColumnWidths = !isMobile
                ? _resolveDesktopColumnWidths(
                    columns: visibleDayColumns,
                    maxWidth: constraints.maxWidth,
                  )
                : null;
            _maybeAutoScrollToTargetDay(
              targetDate: widget.autoScrollTargetDate,
              visibleDayColumns: visibleDayColumns,
              isMobile: isMobile,
              mobileDayColumnWidth: mobileDayColumnWidth,
              resolvedColumnWidths: resolvedColumnWidths,
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
                      resolvedColumnWidths?[index] ??
                      (column.appointments.isEmpty && column.classEvents.isEmpty
                          ? _WeeklyAppointmentsBody._emptyDayColumnWidth
                          : _WeeklyAppointmentsBody._defaultDayColumnWidth),
                  child: _WeeklyDayColumn(
                    day: column.day,
                    appointments: column.appointments,
                    classEvents: column.classEvents,
                    showStaffNameFooter: showStaffNameFooter,
                  ),
                );
              },
            );
          }

          final emptyDaysCount = visibleDayColumns
              .where(
                (entry) =>
                    entry.appointments.isEmpty && entry.classEvents.isEmpty,
              )
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
                      classEvents: visibleDayColumns[i].classEvents,
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
                  width:
                      visibleDayColumns[i].appointments.isEmpty &&
                          visibleDayColumns[i].classEvents.isEmpty
                      ? _WeeklyAppointmentsBody._emptyDayColumnWidth
                      : nonEmptyDayWidth,
                  child: _WeeklyDayColumn(
                    day: visibleDayColumns[i].day,
                    appointments: visibleDayColumns[i].appointments,
                    classEvents: visibleDayColumns[i].classEvents,
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
    required List<
      ({
        DateTime day,
        List<Appointment> appointments,
        List<ClassEvent> classEvents,
      })
    >
    visibleDayColumns,
    required bool isMobile,
    required double? mobileDayColumnWidth,
    required List<double>? resolvedColumnWidths,
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

      final horizontalPadding = isMobile
          ? _WeeklyAppointmentsBody._daySpacing
          : 0.0;
      final previousWidth = List<double>.generate(targetIndex, (index) {
        if (mobileDayColumnWidth != null) {
          return mobileDayColumnWidth;
        }
        if (resolvedColumnWidths != null) {
          return resolvedColumnWidths[index];
        }
        return visibleDayColumns[index].appointments.isEmpty &&
                visibleDayColumns[index].classEvents.isEmpty
            ? _WeeklyAppointmentsBody._emptyDayColumnWidth
            : _WeeklyAppointmentsBody._defaultDayColumnWidth;
      }).fold<double>(0.0, (sum, width) => sum + width);
      final spacingBefore = _WeeklyAppointmentsBody._daySpacing * targetIndex;
      final rawOffset = horizontalPadding + previousWidth + spacingBefore;
      final offsetWithLeftMargin =
          rawOffset - _WeeklyAppointmentsBody._daySpacing;
      final position = _weekColumnsController.position;
      final clampedOffset = offsetWithLeftMargin.clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      _weekColumnsController.jumpTo(clampedOffset);
    });
  }

  List<double> _resolveDesktopColumnWidths({
    required List<
      ({
        DateTime day,
        List<Appointment> appointments,
        List<ClassEvent> classEvents,
      })
    >
    columns,
    required double maxWidth,
  }) {
    if (columns.isEmpty) {
      return const <double>[];
    }

    final baseWidths = [
      for (final column in columns)
        column.appointments.isEmpty && column.classEvents.isEmpty
            ? _WeeklyAppointmentsBody._emptyDayColumnWidth
            : _WeeklyAppointmentsBody._defaultDayColumnWidth,
    ];
    final spacing =
        _WeeklyAppointmentsBody._daySpacing *
        (columns.length - 1).clamp(0, 9999);
    final totalBaseWidth =
        baseWidths.fold<double>(0, (sum, w) => sum + w) + spacing;
    if (totalBaseWidth >= maxWidth) {
      return baseWidths;
    }

    final maxWidths = [
      for (final column in columns)
        column.appointments.isEmpty && column.classEvents.isEmpty
            ? _WeeklyAppointmentsBody._maxDesktopEmptyDayColumnWidth
            : _WeeklyAppointmentsBody._maxDesktopDayColumnWidth,
    ];
    final extraPerColumn = (maxWidth - totalBaseWidth) / columns.length;
    return List<double>.generate(columns.length, (index) {
      final expandedWidth = baseWidths[index] + extraPerColumn;
      return expandedWidth
          .clamp(baseWidths[index], maxWidths[index])
          .toDouble();
    });
  }
}

class _WeeklyDayColumn extends ConsumerStatefulWidget {
  const _WeeklyDayColumn({
    required this.day,
    required this.appointments,
    required this.classEvents,
    required this.showStaffNameFooter,
  });

  final DateTime day;
  final List<Appointment> appointments;
  final List<ClassEvent> classEvents;
  final bool showStaffNameFooter;

  @override
  ConsumerState<_WeeklyDayColumn> createState() => _WeeklyDayColumnState();
}

class _WeeklyDayColumnState extends ConsumerState<_WeeklyDayColumn> {
  static const double _todayBadgeMinColumnWidth = 220;
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
    final today = ref.watch(tenantTodayProvider);
    final isTodayColumn = DateUtils.isSameDay(widget.day, today);
    final label = DateFormat('EEE d MMM', localeTag).format(widget.day);
    final borderColor = isTodayColumn
        ? theme.colorScheme.primary.withOpacity(0.72)
        : theme.dividerColor.withOpacity(0.24);
    final columnBackground = theme.colorScheme.primary.withOpacity(
      isTodayColumn ? 0.03 : 0.012,
    );

    final borderRadius = BorderRadius.circular(12);

    final borderWidth = isTodayColumn ? 1.6 : 1.0;

    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: columnBackground,
              borderRadius: borderRadius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final showTodayBadge =
                          isTodayColumn &&
                          constraints.maxWidth >= _todayBadgeMinColumnWidth;
                      return Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isTodayColumn
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                            ),
                          ),
                          if (showTodayBadge)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.12,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                context.l10n.agendaToday,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                Divider(height: 0.5, thickness: 0.5, color: borderColor),
                Expanded(
                  child:
                      widget.appointments.isEmpty && widget.classEvents.isEmpty
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
                          itemCount: _entries.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final entry = _entries[index];
                            return switch (entry) {
                              _WeeklyAgendaAppointmentEntry(
                                appointment: final appointment,
                              ) =>
                                _WeeklyAppointmentTile(
                                  day: widget.day,
                                  appointment: appointment,
                                  showStaffNameFooter:
                                      widget.showStaffNameFooter,
                                ),
                              _WeeklyAgendaClassEventEntry(
                                classEvent: final event,
                              ) =>
                                _WeeklyClassEventTile(
                                  classEvent: event,
                                  showStaffNameFooter:
                                      widget.showStaffNameFooter,
                                ),
                            };
                          },
                        ),
                ),
              ],
            ),
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                border: Border.all(color: borderColor, width: borderWidth),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_WeeklyAgendaEntry> get _entries {
    final entries = <_WeeklyAgendaEntry>[
      for (final appointment in widget.appointments)
        _WeeklyAgendaAppointmentEntry(appointment),
      for (final event in widget.classEvents)
        _WeeklyAgendaClassEventEntry(event),
    ];
    entries.sort((a, b) => a.start.compareTo(b.start));
    return entries;
  }
}

class _WeeklyAppointmentTile extends ConsumerWidget {
  const _WeeklyAppointmentTile({
    required this.day,
    required this.appointment,
    required this.showStaffNameFooter,
  });

  static const _tileHeight = 68.0;
  static const _tileHeightWhenPriceHidden = 60.0;
  static const _staffFooterHeight = 12.0;

  final DateTime day;
  final Appointment appointment;
  final bool showStaffNameFooter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _resolveAppointmentColor(context, ref, appointment);
    final staffName = _resolveStaffDisplayName(ref, appointment.staffId);
    final showPriceInCard = ref.watch(
      effectiveShowAppointmentPriceInCardProvider,
    );
    final cardTextScale = ref.watch(agendaCardTextScaleProvider);
    final effectiveHeightScale = cardTextScale > 1.0 ? cardTextScale : 1.0;
    final baseTileHeight = showPriceInCard
        ? _tileHeight
        : _tileHeightWhenPriceHidden;
    final tileHeight = baseTileHeight * effectiveHeightScale;
    final theme = Theme.of(context);
    final footerHeight = showStaffNameFooter ? _staffFooterHeight : 0.0;
    final cardBorderRadius = showStaffNameFooter
        ? const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          )
        : const BorderRadius.all(Radius.circular(8));

    return SizedBox(
      height: tileHeight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _handleTap(context, ref),
        child: Column(
          children: [
            SizedBox(
              height: tileHeight - footerHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AppointmentCard(
                        appointment: appointment,
                        color: color,
                        showExtraMinutesBand: false,
                        borderRadius: cardBorderRadius,
                        forceCompactPresentation: true,
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
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(6),
                  ),
                  border: Border(
                    left: BorderSide(color: color),
                    right: BorderSide(color: color),
                    bottom: BorderSide(color: color),
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    staffName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                      color:
                          ThemeData.estimateBrightnessForColor(color) ==
                              Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
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

    final useServiceColors = ref.watch(
      effectiveUseServiceColorsForAppointmentsProvider,
    );
    if (!useServiceColors) {
      return fallbackColor;
    }

    final variantsAsync = ref.watch(serviceVariantsProvider);
    final neutralServiceColor = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest;
    if (variantsAsync.isLoading && !variantsAsync.hasValue) {
      return neutralServiceColor;
    }

    final variants = variantsAsync.value ?? const [];
    final serviceColorMap = <int, Color>{};
    for (final variant in variants) {
      final colorHex = variant.colorHex;
      if (colorHex == null || colorHex.isEmpty) continue;
      serviceColorMap[variant.serviceId] = ColorUtils.fromHex(colorHex);
    }

    return serviceColorMap[currentAppointment.serviceId] ?? neutralServiceColor;
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

class _WeeklyClassEventTile extends ConsumerWidget {
  const _WeeklyClassEventTile({
    required this.classEvent,
    required this.showStaffNameFooter,
  });

  final ClassEvent classEvent;
  final bool showStaffNameFooter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.tertiaryContainer;
    final cardTextScale = ref.watch(agendaCardTextScaleProvider);
    final effectiveHeightScale = cardTextScale > 1.0 ? cardTextScale : 1.0;
    final tileHeight = _WeeklyAppointmentTile._tileHeight * effectiveHeightScale;
    final foreground =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : theme.colorScheme.onTertiaryContainer;
    final footerHeight = showStaffNameFooter
        ? _WeeklyAppointmentTile._staffFooterHeight
        : 0.0;
    final cardBorderRadius = showStaffNameFooter
        ? const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          )
        : const BorderRadius.all(Radius.circular(8));
    final startsAt =
        classEvent.startsAtLocal ?? classEvent.startsAtUtc.toLocal();
    final endsAt = classEvent.endsAtLocal ?? classEvent.endsAtUtc.toLocal();
    final timeLabel =
        '${DtFmt.hm(context, startsAt.hour, startsAt.minute)} - ${DtFmt.hm(context, endsAt.hour, endsAt.minute)}';
    final staffName = _resolveStaffDisplayName(ref, classEvent.staffId);

    return SizedBox(
      height: tileHeight,
      child: Column(
        children: [
          Container(
            height: tileHeight - footerHeight,
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: cardBorderRadius,
              border: Border.all(color: theme.colorScheme.tertiary),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.classEventsTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: foreground),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.classEventsCapacitySummary(
                    classEvent.confirmedCount,
                    classEvent.capacityTotal,
                    classEvent.waitlistCount,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: foreground,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (showStaffNameFooter)
            Container(
              height: _WeeklyAppointmentTile._staffFooterHeight,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(6),
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
                  color: foreground,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _resolveStaffDisplayName(WidgetRef ref, int staffId) {
    final staff = ref
        .watch(staffForCurrentLocationProvider)
        .cast<Staff?>()
        .firstWhere((entry) => entry?.id == staffId, orElse: () => null);
    return staff?.displayName ?? '-';
  }
}

Map<DateTime, List<ClassEvent>> _mapClassEventsByDay(
  List<ClassEvent> classEvents, {
  required WeekRange weekRange,
}) {
  final byDay = <DateTime, List<ClassEvent>>{
    for (final day in weekRange.days) DateUtils.dateOnly(day): <ClassEvent>[],
  };

  for (final event in classEvents) {
    final startsAt = event.startsAtLocal ?? event.startsAtUtc.toLocal();
    final dayKey = DateUtils.dateOnly(startsAt);
    final bucket = byDay[dayKey];
    if (bucket == null) continue;
    bucket.add(event);
  }

  for (final entries in byDay.values) {
    entries.sort((a, b) {
      final aStart = a.startsAtLocal ?? a.startsAtUtc.toLocal();
      final bStart = b.startsAtLocal ?? b.startsAtUtc.toLocal();
      return aStart.compareTo(bStart);
    });
  }

  return byDay;
}

sealed class _WeeklyAgendaEntry {
  const _WeeklyAgendaEntry();

  DateTime get start;
}

class _WeeklyAgendaAppointmentEntry extends _WeeklyAgendaEntry {
  const _WeeklyAgendaAppointmentEntry(this.appointment);

  final Appointment appointment;

  @override
  DateTime get start => appointment.startTime;
}

class _WeeklyAgendaClassEventEntry extends _WeeklyAgendaEntry {
  const _WeeklyAgendaClassEventEntry(this.classEvent);

  final ClassEvent classEvent;

  @override
  DateTime get start =>
      classEvent.startsAtLocal ?? classEvent.startsAtUtc.toLocal();
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
