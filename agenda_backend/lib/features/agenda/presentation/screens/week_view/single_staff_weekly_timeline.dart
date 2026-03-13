import 'package:agenda_backend/app/providers/form_factor_provider.dart';
import 'package:agenda_backend/core/l10n/date_time_formats.dart';
import 'package:agenda_backend/core/l10n/l10_extension.dart';
import 'package:agenda_backend/core/models/appointment.dart';
import 'package:agenda_backend/core/models/class_event.dart';
import 'package:agenda_backend/core/models/staff.dart';
import 'package:agenda_backend/core/utils/color_utils.dart';
import 'package:agenda_backend/core/widgets/no_scrollbar_behavior.dart';
import 'package:agenda_backend/features/agenda/domain/config/agenda_theme.dart';
import 'package:agenda_backend/features/agenda/domain/config/layout_config.dart';
import 'package:agenda_backend/features/agenda/providers/initial_scroll_provider.dart';
import 'package:agenda_backend/features/agenda/providers/layout_config_provider.dart';
import 'package:agenda_backend/features/agenda/providers/staff_slot_availability_provider.dart';
import 'package:agenda_backend/features/agenda/providers/tenant_time_provider.dart';
import 'package:agenda_backend/features/agenda/providers/time_blocks_provider.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/day_view/components/hour_column.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/helper/layout_geometry_helper.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/widgets/agenda_dividers.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/widgets/appointment_card_base.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/widgets/hover_slot.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/widgets/time_block_widget.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/widgets/unavailable_slot_pattern.dart';
import 'package:agenda_backend/features/agenda/presentation/widgets/booking_dialog.dart';
import 'package:agenda_backend/features/agenda/utils/week_range.dart';
import 'package:agenda_backend/features/auth/providers/current_business_user_provider.dart';
import 'package:agenda_backend/features/services/providers/services_provider.dart';
import 'package:agenda_backend/features/staff/providers/staff_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/models/time_block.dart';

typedef WeekDayColumn =
    ({
      DateTime day,
      List<Appointment> appointments,
      List<ClassEvent> classEvents,
    });

class SingleStaffWeeklyTimeline extends ConsumerStatefulWidget {
  const SingleStaffWeeklyTimeline({
    super.key,
    required this.weekRange,
    required this.dayColumns,
    required this.staffId,
    required this.autoScrollRequestId,
    required this.autoScrollTargetDate,
  });

  final WeekRange weekRange;
  final List<WeekDayColumn> dayColumns;
  final int staffId;
  final int autoScrollRequestId;
  final DateTime? autoScrollTargetDate;

  @override
  ConsumerState<SingleStaffWeeklyTimeline> createState() =>
      _SingleStaffWeeklyTimelineState();
}

class _SingleStaffWeeklyTimelineState
    extends ConsumerState<SingleStaffWeeklyTimeline> {
  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _bodyHorizontalController = ScrollController();
  final ScrollController _bodyVerticalController = ScrollController();
  final ScrollController _hourColumnVerticalController = ScrollController();

  bool _isSyncingHorizontal = false;
  bool _isSyncingVertical = false;
  bool _didApplyInitialVerticalOffset = false;
  int _lastHandledAutoScrollRequestId = 0;

  @override
  void initState() {
    super.initState();
    _headerHorizontalController.addListener(_onHeaderHorizontalScroll);
    _bodyHorizontalController.addListener(_onBodyHorizontalScroll);
    _bodyVerticalController.addListener(_onBodyVerticalScroll);
    _hourColumnVerticalController.addListener(_onHourColumnVerticalScroll);
  }

  @override
  void dispose() {
    _headerHorizontalController
      ..removeListener(_onHeaderHorizontalScroll)
      ..dispose();
    _bodyHorizontalController
      ..removeListener(_onBodyHorizontalScroll)
      ..dispose();
    _bodyVerticalController
      ..removeListener(_onBodyVerticalScroll)
      ..dispose();
    _hourColumnVerticalController
      ..removeListener(_onHourColumnVerticalScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layoutConfig = ref.watch(layoutConfigProvider);
    final formFactor = ref.watch(formFactorProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width;
          final hourColumnWidth = layoutConfig.hourColumnWidth;
          final bodyViewportWidth = (availableWidth - hourColumnWidth - 1)
              .clamp(0.0, double.infinity)
              .toDouble();
          final minColumnWidth =
              formFactor == AppFormFactor.mobile ? 140.0 : 180.0;
          final maxColumnWidth =
              formFactor == AppFormFactor.mobile ? 220.0 : 280.0;
          final baseColumnWidth = widget.dayColumns.isEmpty
              ? minColumnWidth
              : bodyViewportWidth / widget.dayColumns.length;
          final columnWidth = baseColumnWidth
              .clamp(minColumnWidth, maxColumnWidth)
              .toDouble();
          final totalContentWidth = columnWidth * widget.dayColumns.length;
          final today = ref.watch(tenantTodayProvider);
          final showCurrentTimeLine = widget.weekRange.days.any(
            (day) => DateUtils.isSameDay(day, today),
          );

          _maybeApplyInitialVerticalOffset(layoutConfig);
          _maybeAutoScrollToTargetDay(
            targetDate: widget.autoScrollTargetDate,
            columnWidth: columnWidth,
          );

          return DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Material(
                  elevation: 8,
                  shadowColor: Colors.black.withOpacity(0.3),
                  surfaceTintColor: Colors.transparent,
                  child: Row(
                    children: [
                      SizedBox(
                        width: hourColumnWidth,
                        height: layoutConfig.headerHeight,
                      ),
                      SizedBox(
                        height: layoutConfig.headerHeight,
                        child: AgendaVerticalDivider(
                          height: layoutConfig.headerHeight,
                          thickness: 1,
                        ),
                      ),
                      Expanded(
                        child: ScrollConfiguration(
                          behavior: const NoScrollbarBehavior(),
                          child: SingleChildScrollView(
                            controller: _headerHorizontalController,
                            scrollDirection: Axis.horizontal,
                            physics: const ClampingScrollPhysics(),
                            child: SizedBox(
                              width: totalContentWidth,
                              height: layoutConfig.headerHeight,
                              child: Row(
                                children: [
                                  for (var i = 0; i < widget.dayColumns.length; i++)
                                    _SingleStaffWeekHeaderCell(
                                      day: widget.dayColumns[i].day,
                                      width: columnWidth,
                                      showRightBorder:
                                          i < widget.dayColumns.length - 1,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: hourColumnWidth,
                        child: ScrollConfiguration(
                          behavior: const NoScrollbarBehavior(),
                          child: SingleChildScrollView(
                            controller: _hourColumnVerticalController,
                            physics: const NeverScrollableScrollPhysics(),
                            child: SizedBox(
                              width: hourColumnWidth,
                              child: const HourColumn(),
                            ),
                          ),
                        ),
                      ),
                      AgendaVerticalDivider(
                        height: layoutConfig.totalHeight,
                        thickness: 1,
                      ),
                      Expanded(
                        child: ScrollConfiguration(
                          behavior: const NoScrollbarBehavior(),
                          child: SingleChildScrollView(
                            controller: _bodyHorizontalController,
                            scrollDirection: Axis.horizontal,
                            physics: const ClampingScrollPhysics(),
                            child: SizedBox(
                              width: totalContentWidth,
                              child: SingleChildScrollView(
                                controller: _bodyVerticalController,
                                physics: const ClampingScrollPhysics(),
                                child: SizedBox(
                                  width: totalContentWidth,
                                  height: layoutConfig.totalHeight,
                                  child: Stack(
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          for (var i = 0;
                                              i < widget.dayColumns.length;
                                              i++)
                                            _SingleStaffWeekTimelineColumn(
                                              staffId: widget.staffId,
                                              day: widget.dayColumns[i].day,
                                              appointments:
                                                  widget.dayColumns[i].appointments,
                                              classEvents:
                                                  widget.dayColumns[i].classEvents,
                                              width: columnWidth,
                                              showRightBorder:
                                                  i < widget.dayColumns.length - 1,
                                            ),
                                        ],
                                      ),
                                      if (showCurrentTimeLine)
                                        _SingleStaffWeekCurrentTimeLine(
                                          weekDays: widget.weekRange.days,
                                          columnWidth: columnWidth,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _maybeApplyInitialVerticalOffset(LayoutConfig layoutConfig) {
    if (_didApplyInitialVerticalOffset) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_bodyVerticalController.hasClients) return;

      final savedOffset = ref.read(agendaVerticalOffsetProvider);
      final now = ref.read(tenantNowProvider);
      final snappedHour = (now.hour - 1).clamp(0, 23);
      final fallbackOffset = layoutConfig.offsetForMinuteOfDay(snappedHour * 60);
      final target = (savedOffset ?? fallbackOffset).clamp(
        _bodyVerticalController.position.minScrollExtent,
        _bodyVerticalController.position.maxScrollExtent,
      );

      _bodyVerticalController.jumpTo(target);
      if (_hourColumnVerticalController.hasClients) {
        _hourColumnVerticalController.jumpTo(target);
      }
      ref.read(agendaVerticalOffsetProvider.notifier).set(target);
      _didApplyInitialVerticalOffset = true;
    });
  }

  void _maybeAutoScrollToTargetDay({
    required DateTime? targetDate,
    required double columnWidth,
  }) {
    final requestId = widget.autoScrollRequestId;
    if (requestId <= 0 ||
        requestId == _lastHandledAutoScrollRequestId ||
        targetDate == null) {
      return;
    }

    final targetIndex = widget.dayColumns.indexWhere(
      (entry) => DateUtils.isSameDay(entry.day, targetDate),
    );
    if (targetIndex < 0) return;
    _lastHandledAutoScrollRequestId = requestId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_bodyHorizontalController.hasClients) return;

      final rawOffset = targetIndex * columnWidth;
      final centeredOffset =
          rawOffset -
          (_bodyHorizontalController.position.viewportDimension - columnWidth) / 2;
      final clampedOffset = centeredOffset.clamp(
        _bodyHorizontalController.position.minScrollExtent,
        _bodyHorizontalController.position.maxScrollExtent,
      );
      _bodyHorizontalController.jumpTo(clampedOffset);
      if (_headerHorizontalController.hasClients) {
        _headerHorizontalController.jumpTo(clampedOffset);
      }
    });
  }

  void _onHeaderHorizontalScroll() {
    if (_isSyncingHorizontal || !_bodyHorizontalController.hasClients) return;
    _isSyncingHorizontal = true;
    _bodyHorizontalController.jumpTo(_headerHorizontalController.offset);
    _isSyncingHorizontal = false;
  }

  void _onBodyHorizontalScroll() {
    if (_isSyncingHorizontal || !_headerHorizontalController.hasClients) return;
    _isSyncingHorizontal = true;
    _headerHorizontalController.jumpTo(_bodyHorizontalController.offset);
    _isSyncingHorizontal = false;
  }

  void _onBodyVerticalScroll() {
    if (_isSyncingVertical || !_hourColumnVerticalController.hasClients) return;
    _isSyncingVertical = true;
    _hourColumnVerticalController.jumpTo(_bodyVerticalController.offset);
    _isSyncingVertical = false;
    ref
        .read(agendaVerticalOffsetProvider.notifier)
        .set(_bodyVerticalController.offset);
  }

  void _onHourColumnVerticalScroll() {
    if (_isSyncingVertical || !_bodyVerticalController.hasClients) return;
    _isSyncingVertical = true;
    _bodyVerticalController.jumpTo(_hourColumnVerticalController.offset);
    _isSyncingVertical = false;
  }
}

class _SingleStaffWeekHeaderCell extends ConsumerWidget {
  const _SingleStaffWeekHeaderCell({
    required this.day,
    required this.width,
    required this.showRightBorder,
  });

  final DateTime day;
  final double width;
  final bool showRightBorder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final isToday = DateUtils.isSameDay(day, ref.watch(tenantTodayProvider));

    return Container(
      width: width,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: showRightBorder
            ? Border(
                right: BorderSide(
                  color: theme.dividerColor.withOpacity(0.25),
                  width: 1,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEE', localeTag).format(day).toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isToday ? theme.colorScheme.primary : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('d MMM', localeTag).format(day),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isToday ? theme.colorScheme.primary : null,
                  ),
                ),
              ],
            ),
          ),
          if (isToday)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.12),
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
      ),
    );
  }
}

class _SingleStaffWeekTimelineColumn extends ConsumerWidget {
  const _SingleStaffWeekTimelineColumn({
    required this.staffId,
    required this.day,
    required this.appointments,
    required this.classEvents,
    required this.width,
    required this.showRightBorder,
  });

  final int staffId;
  final DateTime day;
  final List<Appointment> appointments;
  final List<ClassEvent> classEvents;
  final double width;
  final bool showRightBorder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutConfig = ref.watch(layoutConfigProvider);
    final theme = Theme.of(context);
    final isToday = DateUtils.isSameDay(day, ref.watch(tenantTodayProvider));
    final slotHeight = layoutConfig.slotHeight;
    final totalSlots = layoutConfig.totalSlots;
    final slotsPerHour = 60 ~/ layoutConfig.minutesPerSlot;
    final unavailableRanges = ref.watch(
      unavailableSlotRangesForDateProvider((staffId: staffId, date: day)),
    );
    final canManageBookings = ref.watch(currentUserCanManageBookingsProvider);
    final timeBlocks =
        ref.watch(timeBlocksForStaffOnDateProvider((staffId: staffId, date: day)))
            .value ??
        const <TimeBlock>[];

    final geometry = _buildGeometry(layoutConfig);
    final appointmentColors = _resolveAppointmentColors(context, ref);

    return Container(
      width: width,
      height: layoutConfig.totalHeight,
      decoration: BoxDecoration(
        color: isToday
            ? theme.colorScheme.primary.withOpacity(0.025)
            : Colors.transparent,
        border: showRightBorder
            ? Border(
                right: BorderSide(
                  color: theme.dividerColor.withOpacity(0.25),
                  width: 1,
                ),
              )
            : null,
      ),
      child: Stack(
        children: [
          Column(
            children: List.generate(totalSlots, (index) {
              final isHourStart = (index + 1) % slotsPerHour == 0;
              return SizedBox(
                height: slotHeight,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: AgendaHorizontalDivider(
                    color: Colors.grey.withOpacity(isHourStart ? 0.5 : 0.2),
                    thickness: isHourStart ? 1 : 0.5,
                  ),
                ),
              );
            }),
          ),
          if (unavailableRanges.isNotEmpty)
            IgnorePointer(
              child: SizedBox(
                height: layoutConfig.totalHeight,
                width: double.infinity,
                child: Stack(
                  children: [
                    for (final range in unavailableRanges)
                      Positioned(
                        top: layoutConfig.heightForMinutes(
                          range.startIndex * layoutConfig.minutesPerSlot,
                        ),
                        left: 0,
                        right: 0,
                        child: UnavailableSlotRange(
                          slotCount: range.count,
                          slotHeight: slotHeight,
                          patternColor: AgendaTheme.unavailablePatternColor(
                            theme.colorScheme,
                          ),
                          backgroundColor: AgendaTheme.unavailableBackgroundColor(
                            theme.colorScheme,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          Column(
            children: List.generate(totalSlots, (index) {
              final slotTime = day.add(
                Duration(minutes: index * layoutConfig.minutesPerSlot),
              );
              if (!canManageBookings) {
                return SizedBox(height: slotHeight, width: double.infinity);
              }
              return LazyHoverSlot(
                slotTime: slotTime,
                height: slotHeight,
                colorPrimary1: theme.colorScheme.primary,
                onTap: (dt) => _handleSlotTap(context, ref, dt),
              );
            }),
          ),
          for (final appointment in appointments)
            _buildAppointment(
              context,
              appointment,
              layoutConfig,
              geometry,
              appointmentColors,
            ),
          for (final event in classEvents)
            _buildClassEvent(context, event, layoutConfig, geometry),
          for (final block in timeBlocks)
            _buildTimeBlock(block, layoutConfig),
        ],
      ),
    );
  }

  Map<int, EventGeometry> _buildGeometry(LayoutConfig layoutConfig) {
    final entries = <LayoutEntry>[
      for (final appointment in appointments)
        LayoutEntry(
          id: appointment.id,
          start: appointment.startTime,
          end: appointment.endTime,
        ),
      for (final event in classEvents)
        LayoutEntry(
          id: _classEventLayoutId(event.id),
          start: event.startsAtLocal ?? event.startsAtUtc.toLocal(),
          end: event.endsAtLocal ?? event.endsAtUtc.toLocal(),
        ),
    ];
    return computeLayoutGeometry(
      entries,
      useClusterMaxConcurrency: layoutConfig.useClusterMaxConcurrency,
    );
  }

  Map<int, Color> _resolveAppointmentColors(BuildContext context, WidgetRef ref) {
    final layoutConfig = ref.watch(layoutConfigProvider);
    final firstStaffId = appointments.isEmpty ? null : appointments.first.staffId;
    final staff = ref
        .watch(staffForCurrentLocationProvider)
        .cast<Staff?>()
        .firstWhere((entry) => entry?.id == firstStaffId, orElse: () => null);
    final fallbackColor =
        staff?.color ?? Theme.of(context).colorScheme.primary.withOpacity(0.8);

    final colors = <int, Color>{};
    if (!layoutConfig.useServiceColorsForAppointments) {
      for (final appointment in appointments) {
        colors[appointment.id] = fallbackColor;
      }
      return colors;
    }

    final variants = ref.watch(serviceVariantsProvider).value ?? const [];
    final serviceColorMap = <int, Color>{};
    for (final variant in variants) {
      final colorHex = variant.colorHex;
      if (colorHex == null || colorHex.isEmpty) continue;
      serviceColorMap[variant.serviceId] = ColorUtils.fromHex(colorHex);
    }

    for (final appointment in appointments) {
      colors[appointment.id] =
          serviceColorMap[appointment.serviceId] ?? fallbackColor;
    }
    return colors;
  }

  Widget _buildAppointment(
    BuildContext context,
    Appointment appointment,
    LayoutConfig layoutConfig,
    Map<int, EventGeometry> geometry,
    Map<int, Color> appointmentColors,
  ) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final startMinutes = appointment.startTime.difference(dayStart).inMinutes;
    final endMinutes = appointment.endTime.difference(dayStart).inMinutes;
    final top = layoutConfig.offsetForMinuteOfDay(startMinutes);
    final height = layoutConfig.heightForMinutes(endMinutes - startMinutes);
    final eventGeometry =
        geometry[appointment.id] ??
        const EventGeometry(leftFraction: 0, widthFraction: 1);
    final padding = LayoutConfig.columnInnerPadding;
    final fullWidth = width - padding * 2;
    final cardLeft = width * eventGeometry.leftFraction + padding;
    final cardWidth = (width * eventGeometry.widthFraction - padding * 2)
        .clamp(0.0, double.infinity)
        .toDouble();

    return Positioned(
      top: top,
      left: cardLeft,
      width: cardWidth,
      height: height,
      child: AppointmentCard(
        appointment: appointment,
        color:
            appointmentColors[appointment.id] ??
            Theme.of(context).colorScheme.primary,
        columnWidth: cardWidth,
        columnOffset: cardLeft,
        dragTargetWidth: fullWidth,
      ),
    );
  }

  Widget _buildClassEvent(
    BuildContext context,
    ClassEvent event,
    LayoutConfig layoutConfig,
    Map<int, EventGeometry> geometry,
  ) {
    final theme = Theme.of(context);
    final start = event.startsAtLocal ?? event.startsAtUtc.toLocal();
    final end = event.endsAtLocal ?? event.endsAtUtc.toLocal();
    final dayStart = DateTime(day.year, day.month, day.day);
    final startMinutes = start.difference(dayStart).inMinutes;
    final endMinutes = end.difference(dayStart).inMinutes;
    final top = layoutConfig.offsetForMinuteOfDay(startMinutes);
    final height = layoutConfig.heightForMinutes(endMinutes - startMinutes);
    final eventGeometry =
        geometry[_classEventLayoutId(event.id)] ??
        const EventGeometry(leftFraction: 0, widthFraction: 1);
    final padding = LayoutConfig.columnInnerPadding;
    final cardLeft = width * eventGeometry.leftFraction + padding;
    final cardWidth = (width * eventGeometry.widthFraction - padding * 2)
        .clamp(0.0, double.infinity)
        .toDouble();
    final color = theme.colorScheme.tertiaryContainer;
    final foreground =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? Colors.white
            : theme.colorScheme.onTertiaryContainer;

    return Positioned(
      top: top,
      left: cardLeft,
      width: cardWidth,
      height: height,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.tertiary),
        ),
        child: DefaultTextStyle(
          style: theme.textTheme.bodySmall?.copyWith(color: foreground) ??
              TextStyle(color: foreground),
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
                '${DtFmt.hm(context, start.hour, start.minute)} - ${DtFmt.hm(context, end.hour, end.minute)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                context.l10n.classEventsCapacitySummary(
                  event.confirmedCount,
                  event.capacityTotal,
                  event.waitlistCount,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeBlock(TimeBlock block, LayoutConfig layoutConfig) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final startMinutes = block.startTime.difference(dayStart).inMinutes;
    final endMinutes = block.endTime.difference(dayStart).inMinutes;
    final clampedStartMinutes = startMinutes.clamp(0, LayoutConfig.hoursInDay * 60);
    final clampedEndMinutes = endMinutes.clamp(0, LayoutConfig.hoursInDay * 60);

    if (clampedEndMinutes <= clampedStartMinutes) {
      return const SizedBox.shrink();
    }

    final padding = LayoutConfig.columnInnerPadding;
    final cardWidth = (width - padding * 2).clamp(0.0, double.infinity).toDouble();
    final top = layoutConfig.offsetForMinuteOfDay(clampedStartMinutes);
    final height = layoutConfig.heightForMinutes(
      clampedEndMinutes - clampedStartMinutes,
    );

    return Positioned(
      key: ValueKey('block_${block.id}_${day.toIso8601String()}'),
      top: top,
      left: padding,
      width: cardWidth,
      height: height,
      child: TimeBlockWidget(
        block: block,
        height: height,
        width: cardWidth,
      ),
    );
  }

  void _handleSlotTap(BuildContext context, WidgetRef ref, DateTime dt) {
    showBookingDialog(
      context,
      ref,
      date: DateUtils.dateOnly(dt),
      time: TimeOfDay(hour: dt.hour, minute: dt.minute),
      initialStaffId: staffId,
    );
  }
}

class _SingleStaffWeekCurrentTimeLine extends ConsumerWidget {
  const _SingleStaffWeekCurrentTimeLine({
    required this.weekDays,
    required this.columnWidth,
  });

  final List<DateTime> weekDays;
  final double columnWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(tenantTodayProvider);
    final todayIndex = weekDays.indexWhere(
      (day) => DateUtils.isSameDay(day, today),
    );
    if (todayIndex < 0) return const SizedBox.shrink();

    final layoutConfig = ref.watch(layoutConfigProvider);
    final now = ref.watch(tenantNowProvider);
    final top = layoutConfig.offsetForMinuteOfDay(now.hour * 60 + now.minute);
    final left = todayIndex * columnWidth;

    return Positioned(
      top: top,
      left: left,
      width: columnWidth,
      child: IgnorePointer(
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Container(height: 1, color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }
}

int _classEventLayoutId(int eventId) => -1000000 - eventId;
