import 'package:agenda_backend/app/providers/form_factor_provider.dart';
import 'package:agenda_backend/core/l10n/date_time_formats.dart';
import 'package:agenda_backend/core/l10n/l10_extension.dart';
import 'package:agenda_backend/core/models/appointment.dart';
import 'package:agenda_backend/core/models/class_event.dart';
import 'package:agenda_backend/core/models/staff.dart';
import 'package:agenda_backend/core/utils/color_utils.dart';
import 'package:agenda_backend/core/widgets/app_dialogs.dart';
import 'package:agenda_backend/core/widgets/feedback_dialog.dart';
import 'package:agenda_backend/core/widgets/no_scrollbar_behavior.dart';
import 'package:agenda_backend/app/widgets/staff_circle_avatar.dart';
import 'package:agenda_backend/features/agenda/domain/config/agenda_theme.dart';
import 'package:agenda_backend/features/agenda/domain/config/layout_config.dart';
import 'package:agenda_backend/features/agenda/providers/agenda_scroll_request_provider.dart';
import 'package:agenda_backend/features/agenda/providers/agenda_display_settings_provider.dart';
import 'package:agenda_backend/features/agenda/providers/appointment_providers.dart';
import 'package:agenda_backend/features/agenda/providers/booking_reschedule_provider.dart';
import 'package:agenda_backend/features/agenda/providers/drag_layer_link_provider.dart';
import 'package:agenda_backend/features/agenda/providers/drag_offset_provider.dart';
import 'package:agenda_backend/features/agenda/providers/drag_session_provider.dart';
import 'package:agenda_backend/features/agenda/providers/dragged_card_size_provider.dart';
import 'package:agenda_backend/features/agenda/providers/initial_scroll_provider.dart';
import 'package:agenda_backend/features/agenda/providers/layout_config_provider.dart';
import 'package:agenda_backend/features/agenda/providers/pending_drop_provider.dart';
import 'package:agenda_backend/features/agenda/providers/staff_slot_availability_provider.dart';
import 'package:agenda_backend/features/agenda/providers/temp_drag_time_provider.dart';
import 'package:agenda_backend/features/agenda/providers/tenant_time_provider.dart';
import 'package:agenda_backend/features/agenda/providers/time_blocks_provider.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/day_view/components/hour_column.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/helper/layout_geometry_helper.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/widgets/agenda_dividers.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/widgets/appointment_card_base.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/widgets/hover_slot.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/widgets/time_block_widget.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/widgets/unavailable_slot_pattern.dart';
import 'package:agenda_backend/features/agenda/presentation/utils/multi_service_move_guard.dart';
import 'package:agenda_backend/features/agenda/presentation/widgets/booking_dialog.dart';
import 'package:agenda_backend/features/agenda/utils/week_range.dart';
import 'package:agenda_backend/features/auth/providers/current_business_user_provider.dart';
import 'package:agenda_backend/features/services/providers/services_provider.dart';
import 'package:agenda_backend/features/staff/providers/staff_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/models/time_block.dart';

typedef WeekDayColumn = ({
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
  final GlobalKey _bodyKey = GlobalKey();
  late final DragBodyBoxNotifier _dragBodyNotifier;

  @override
  void initState() {
    super.initState();
    _dragBodyNotifier = ref.read(dragBodyBoxProvider.notifier);
    _headerHorizontalController.addListener(_onHeaderHorizontalScroll);
    _bodyHorizontalController.addListener(_onBodyHorizontalScroll);
    _bodyVerticalController.addListener(_onBodyVerticalScroll);
    _hourColumnVerticalController.addListener(_onHourColumnVerticalScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerBodyBox();
    });
  }

  @override
  void dispose() {
    _clearBodyBox();
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
    final dragLayerLink = ref.watch(dragLayerLinkProvider);

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
          final minColumnWidth = formFactor == AppFormFactor.mobile
              ? 140.0
              : 180.0;
          final maxColumnWidth = formFactor == AppFormFactor.mobile
              ? 220.0
              : 280.0;
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
                                  for (
                                    var i = 0;
                                    i < widget.dayColumns.length;
                                    i++
                                  )
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
                        child: CompositedTransformTarget(
                          key: _bodyKey,
                          link: dragLayerLink,
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
                                            for (
                                              var i = 0;
                                              i < widget.dayColumns.length;
                                              i++
                                            )
                                              _SingleStaffWeekTimelineColumn(
                                                staffId: widget.staffId,
                                                day: widget.dayColumns[i].day,
                                                appointments: widget
                                                    .dayColumns[i]
                                                    .appointments,
                                                classEvents: widget
                                                    .dayColumns[i]
                                                    .classEvents,
                                                width: columnWidth,
                                                showRightBorder:
                                                    i <
                                                    widget.dayColumns.length -
                                                        1,
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

  void _registerBodyBox() {
    final box = _bodyKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      _dragBodyNotifier.set(box);
    }
  }

  void _clearBodyBox() {
    _dragBodyNotifier.scheduleClear();
  }

  void _maybeApplyInitialVerticalOffset(LayoutConfig layoutConfig) {
    if (_didApplyInitialVerticalOffset) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_bodyVerticalController.hasClients) return;

      final savedOffset = ref.read(agendaVerticalOffsetProvider);
      final now = ref.read(tenantNowProvider);
      final snappedHour = (now.hour - 1).clamp(0, 23);
      final fallbackOffset = layoutConfig.offsetForMinuteOfDay(
        snappedHour * 60,
      );
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
          (_bodyHorizontalController.position.viewportDimension - columnWidth) /
              2;
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
    _registerBodyBox();
    if (_isSyncingHorizontal || !_headerHorizontalController.hasClients) return;
    _isSyncingHorizontal = true;
    _headerHorizontalController.jumpTo(_bodyHorizontalController.offset);
    _isSyncingHorizontal = false;
  }

  void _onBodyVerticalScroll() {
    _registerBodyBox();
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

  static const List<Color> _weekdayAvatarColors = [
    Color(0xFF1E88E5), // Lun
    Color(0xFF00897B), // Mar
    Color(0xFF7CB342), // Mer
    Color(0xFFF4511E), // Gio
    Color(0xFF8E24AA), // Ven
    Color(0xFF3949AB), // Sab
    Color(0xFF6D4C41), // Dom
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final layoutConfig = ref.watch(layoutConfigProvider);
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final isToday = DateUtils.isSameDay(day, ref.watch(tenantTodayProvider));
    final dayAcronym = DateFormat('EEE', localeTag).format(day).toUpperCase();
    final avatarDefault = LayoutConfig.avatarSizeFor(context);
    final maxByHeader = layoutConfig.headerHeight * 0.55;
    final avatarSize = avatarDefault <= maxByHeader
        ? avatarDefault
        : maxByHeader;
    final avatarColor = _weekdayAvatarColors[(day.weekday - 1).clamp(0, 6)];

    return Container(
      width: width,
      height: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: layoutConfig.headerHeight * 0.08,
      ),
      decoration: BoxDecoration(
        gradient: isToday
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  avatarColor.withOpacity(0.008),
                  avatarColor.withOpacity(0.14),
                ],
              )
            : null,
        border: showRightBorder
            ? Border(
                right: BorderSide(
                  color: theme.dividerColor.withOpacity(0.25),
                  width: 1,
                ),
              )
            : null,
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StaffCircleAvatar(
                height: avatarSize,
                color: avatarColor,
                isHighlighted: isToday,
                initials: dayAcronym,
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('d MMMM', localeTag).format(day),
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
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
  double get _contentWidth =>
      (width - (showRightBorder ? 1.0 : 0.0)).clamp(0.0, double.infinity);

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
        ref
            .watch(
              timeBlocksForStaffOnDateProvider((staffId: staffId, date: day)),
            )
            .value ??
        const <TimeBlock>[];

    final geometry = _buildGeometry(layoutConfig);
    final appointmentColors = _resolveAppointmentColors(context, ref);

    final content = Container(
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
                          backgroundColor:
                              AgendaTheme.unavailableBackgroundColor(
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
          for (final block in timeBlocks) _buildTimeBlock(block, layoutConfig),
        ],
      ),
    );

    if (!canManageBookings) {
      return content;
    }

    return DragTarget<Appointment>(
      onWillAcceptWithDetails: (_) => true,
      onMove: (details) {
        _updateDragPreviewTime(context, ref, details);
      },
      onLeave: (_) {
        ref.read(tempDragTimeProvider.notifier).clear();
      },
      onAcceptWithDetails: (details) async {
        ref.read(tempDragTimeProvider.notifier).clear();
        await _handleAppointmentDrop(context, ref, details);
      },
      builder: (_, __, ___) => content,
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

  Map<int, Color> _resolveAppointmentColors(
    BuildContext context,
    WidgetRef ref,
  ) {
    final useServiceColors = ref.watch(
      effectiveUseServiceColorsForAppointmentsProvider,
    );
    final firstStaffId = appointments.isEmpty
        ? null
        : appointments.first.staffId;
    final staff = ref
        .watch(staffForCurrentLocationProvider)
        .cast<Staff?>()
        .firstWhere((entry) => entry?.id == firstStaffId, orElse: () => null);
    final fallbackColor =
        staff?.color ?? Theme.of(context).colorScheme.primary.withOpacity(0.8);

    final colors = <int, Color>{};
    if (!useServiceColors) {
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
    final contentWidth = _contentWidth;
    final fullWidth = contentWidth - padding * 2;
    final cardLeft = contentWidth * eventGeometry.leftFraction + padding;
    final cardWidth = (contentWidth * eventGeometry.widthFraction - padding * 2)
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
    final contentWidth = _contentWidth;
    final cardLeft = contentWidth * eventGeometry.leftFraction + padding;
    final cardWidth = (contentWidth * eventGeometry.widthFraction - padding * 2)
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
          style:
              theme.textTheme.bodySmall?.copyWith(color: foreground) ??
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
    final clampedStartMinutes = startMinutes.clamp(
      0,
      LayoutConfig.hoursInDay * 60,
    );
    final clampedEndMinutes = endMinutes.clamp(0, LayoutConfig.hoursInDay * 60);

    if (clampedEndMinutes <= clampedStartMinutes) {
      return const SizedBox.shrink();
    }

    final padding = LayoutConfig.columnInnerPadding;
    final cardWidth = (_contentWidth - padding * 2)
        .clamp(0.0, double.infinity)
        .toDouble();
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
      child: TimeBlockWidget(block: block, height: height, width: cardWidth),
    );
  }

  Future<void> _handleSlotTap(
    BuildContext context,
    WidgetRef ref,
    DateTime dt,
  ) async {
    final rescheduleSession = ref.read(bookingRescheduleSessionProvider);
    if (rescheduleSession != null) {
      if (rescheduleSession.items.isEmpty) {
        ref.read(bookingRescheduleSessionProvider.notifier).clear();
        if (context.mounted) {
          await FeedbackDialog.showError(
            context,
            title: context.l10n.errorTitle,
            message: context.l10n.bookingRescheduleMissingBooking,
          );
        }
        return;
      }

      final targetStart = DateTime(
        dt.year,
        dt.month,
        dt.day,
        dt.hour,
        dt.minute,
      );
      final l10n = context.l10n;
      final targetDateStr = DtFmt.longDate(context, targetStart);
      final targetTimeStr = DtFmt.hm(
        context,
        targetStart.hour,
        targetStart.minute,
      );
      final staffName =
          ref
              .read(staffForCurrentLocationProvider)
              .cast<Staff?>()
              .firstWhere((s) => s?.id == staffId, orElse: () => null)
              ?.displayName ??
          '-';

      final confirmed = await showConfirmDialog(
        context,
        title: Text(l10n.bookingRescheduleConfirmTitle),
        content: Text(
          l10n.bookingRescheduleConfirmMessage(
            targetDateStr,
            targetTimeStr,
            staffName,
          ),
        ),
        confirmLabel: l10n.actionConfirm,
        cancelLabel: l10n.actionCancel,
      );
      if (confirmed != true) return;

      final anchorId = rescheduleSession.anchorAppointmentId;
      final result = await ref
          .read(appointmentsProvider.notifier)
          .moveBookingByAnchor(
            session: rescheduleSession,
            targetStart: targetStart,
            targetStaffId: staffId,
          );

      if (!context.mounted) return;
      if (result != MoveBookingByAnchorResult.success) {
        final message = result == MoveBookingByAnchorResult.outOfTargetDay
            ? l10n.bookingRescheduleOutOfDayBlocked
            : l10n.bookingRescheduleMoveFailed;
        await FeedbackDialog.showError(
          context,
          title: l10n.errorTitle,
          message: message,
        );
        return;
      }

      ref.read(bookingRescheduleSessionProvider.notifier).clear();
      final refreshedAppointments = ref.read(appointmentsProvider).value ?? [];
      Appointment? movedAnchor;
      for (final appointment in refreshedAppointments) {
        if (appointment.id == anchorId) {
          movedAnchor = appointment;
          break;
        }
      }
      if (movedAnchor != null) {
        ref.read(agendaScrollRequestProvider.notifier).request(movedAnchor);
      }
      return;
    }

    showBookingDialog(
      context,
      ref,
      date: DateUtils.dateOnly(dt),
      time: TimeOfDay(hour: dt.hour, minute: dt.minute),
      initialStaffId: staffId,
    );
  }

  Future<void> _handleAppointmentDrop(
    BuildContext context,
    WidgetRef ref,
    DragTargetDetails<Appointment> details,
  ) async {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final dragOffsetY = ref.read(dragOffsetProvider) ?? 0.0;
    final dragOffsetX = ref.read(dragOffsetXProvider) ?? 0.0;
    final draggedCardHeightPx =
        ref.read(draggedCardSizeProvider)?.height ?? 50.0;
    final localPointer = box.globalToLocal(
      details.offset + Offset(dragOffsetX, dragOffsetY),
    );

    final layoutConfig = ref.read(layoutConfigProvider);
    final maxYStartPx = (box.size.height - draggedCardHeightPx)
        .clamp(0, box.size.height)
        .toDouble();
    final clampedLocalDy = localPointer.dy.clamp(
      0.0,
      box.size.height.toDouble(),
    );
    final effectiveDy = (clampedLocalDy - dragOffsetY)
        .clamp(0.0, maxYStartPx)
        .toDouble();

    final durationMinutes = details.data.endTime
        .difference(details.data.startTime)
        .inMinutes;
    const totalMinutes = LayoutConfig.hoursInDay * 60;
    var startMinutes =
        ((layoutConfig.minutesFromHeight(effectiveDy) / 5).round() * 5).toInt();
    final maxStartMinutes = (totalMinutes - durationMinutes).clamp(
      0,
      totalMinutes,
    );
    if (startMinutes < 0) startMinutes = 0;
    if (startMinutes > maxStartMinutes) startMinutes = maxStartMinutes;

    final targetDate = DateTime(day.year, day.month, day.day);
    final newStart = targetDate.add(Duration(minutes: startMinutes));
    final newEnd = newStart.add(Duration(minutes: durationMinutes));
    final dayBoundary = targetDate.add(const Duration(days: 1));
    final boundedEnd = newEnd.isAfter(dayBoundary) ? dayBoundary : newEnd;

    ref.read(dragSessionProvider.notifier).markHandled();

    final hasStaffChanged = details.data.staffId != staffId;
    final hasTimeChanged =
        details.data.startTime != newStart ||
        details.data.endTime != boundedEnd;
    if (!hasStaffChanged && !hasTimeChanged) {
      return;
    }

    final pendingData = PendingDropData(
      appointmentId: details.data.id,
      originalStaffId: details.data.staffId,
      originalStart: details.data.startTime,
      originalEnd: details.data.endTime,
      newStaffId: staffId,
      newStart: newStart,
      newEnd: boundedEnd,
    );
    ref.read(pendingDropProvider.notifier).setPending(pendingData);

    final l10n = context.l10n;
    final targetStaffName =
        ref
            .read(staffForCurrentLocationProvider)
            .cast<Staff?>()
            .firstWhere((s) => s?.id == staffId, orElse: () => null)
            ?.displayName ??
        '-';
    final isCrossDayMove = !DateUtils.isSameDay(
      details.data.startTime,
      newStart,
    );
    final targetDateLabel = DtFmt.longDate(context, newStart);
    final appointmentsNotifier = ref.read(appointmentsProvider.notifier);
    final bookingAppointments = appointmentsNotifier.getByBookingId(
      details.data.bookingId,
    );
    final isMultiService = isMultiServiceBooking(bookingAppointments);
    final moveWholeBooking = isMultiService && isCrossDayMove;
    final movedTimeLabel = DtFmt.hm(context, newStart.hour, newStart.minute);
    final confirmMessage = moveWholeBooking
        ? l10n.bookingRescheduleConfirmMessage(
            targetDateLabel,
            movedTimeLabel,
            targetStaffName,
          )
        : isCrossDayMove
        ? '${l10n.moveAppointmentConfirmMessage(movedTimeLabel, targetStaffName)}\n$targetDateLabel'
        : l10n.moveAppointmentConfirmMessage(movedTimeLabel, targetStaffName);
    final confirmed = await showConfirmDialog(
      context,
      title: Text(
        moveWholeBooking
            ? l10n.bookingRescheduleConfirmTitle
            : l10n.moveAppointmentConfirmTitle,
      ),
      content: Text(confirmMessage),
      confirmLabel: l10n.actionConfirm,
      cancelLabel: l10n.actionCancel,
    );
    ref.read(pendingDropProvider.notifier).clear();

    if (confirmed != true) return;
    if (!context.mounted) return;

    if (!moveWholeBooking) {
      appointmentsNotifier.moveAppointment(
        appointmentId: details.data.id,
        newStaffId: staffId,
        newStart: newStart,
        newEnd: boundedEnd,
      );
      return;
    }
    await moveWholeBookingFromAnchor(
      ref: ref,
      context: context,
      anchorAppointment: details.data,
      targetStart: newStart,
      targetStaffId: staffId,
      bookingAppointments: bookingAppointments,
    );
  }

  void _updateDragPreviewTime(
    BuildContext context,
    WidgetRef ref,
    DragTargetDetails<Appointment> details,
  ) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final layoutConfig = ref.read(layoutConfigProvider);
    final dragOffsetY = ref.read(dragOffsetProvider) ?? 0.0;
    final dragOffsetX = ref.read(dragOffsetXProvider) ?? 0.0;
    final draggedCardHeightPx =
        ref.read(draggedCardSizeProvider)?.height ?? 50.0;
    final localPointer = box.globalToLocal(
      details.offset + Offset(dragOffsetX, dragOffsetY),
    );

    final maxYStartPx = (box.size.height - draggedCardHeightPx)
        .clamp(0, box.size.height)
        .toDouble();
    final clampedLocalDy = localPointer.dy.clamp(
      0.0,
      box.size.height.toDouble(),
    );
    final effectiveDy = (clampedLocalDy - dragOffsetY)
        .clamp(0.0, maxYStartPx)
        .toDouble();

    final durationMinutes = details.data.endTime
        .difference(details.data.startTime)
        .inMinutes;
    const totalMinutes = LayoutConfig.hoursInDay * 60;
    var startMinutes =
        ((layoutConfig.minutesFromHeight(effectiveDy) / 5).round() * 5).toInt();
    final maxStartMinutes = (totalMinutes - durationMinutes).clamp(
      0,
      totalMinutes,
    );
    if (startMinutes < 0) startMinutes = 0;
    if (startMinutes > maxStartMinutes) startMinutes = maxStartMinutes;

    final targetDate = DateTime(day.year, day.month, day.day);
    final previewStart = targetDate.add(Duration(minutes: startMinutes));
    final rawPreviewEnd = previewStart.add(Duration(minutes: durationMinutes));
    final dayBoundary = targetDate.add(const Duration(days: 1));
    final previewEnd = rawPreviewEnd.isAfter(dayBoundary)
        ? dayBoundary
        : rawPreviewEnd;

    ref.read(tempDragTimeProvider.notifier).setTimes(previewStart, previewEnd);
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
            Expanded(child: Container(height: 1, color: Colors.redAccent)),
          ],
        ),
      ),
    );
  }
}

int _classEventLayoutId(int eventId) => -1000000 - eventId;
