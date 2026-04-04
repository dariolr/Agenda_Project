import 'dart:async';

import 'package:agenda_backend/app/providers/global_loading_provider.dart';
import 'package:agenda_backend/core/l10n/l10_extension.dart';
import 'package:agenda_backend/core/widgets/no_scrollbar_behavior.dart';
import 'package:agenda_backend/features/agenda/domain/staff_filter_mode.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/day_view/agenda_day.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/day_view/components/hour_column.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/week_view/weekly_appointments_view.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/widgets/agenda_dividers.dart';
import 'package:agenda_backend/core/widgets/app_buttons.dart';
import 'package:agenda_backend/features/agenda/providers/agenda_display_settings_provider.dart';
import 'package:agenda_backend/features/agenda/providers/agenda_bootstrap_provider.dart';
import 'package:agenda_backend/features/agenda/providers/appointment_providers.dart';
import 'package:agenda_backend/features/agenda/providers/booking_reschedule_capability_provider.dart';
import 'package:agenda_backend/features/agenda/providers/booking_reschedule_provider.dart';
import 'package:agenda_backend/features/agenda/providers/business_providers.dart';
import 'package:agenda_backend/features/agenda/providers/calendar_view_mode_provider.dart';
import 'package:agenda_backend/features/agenda/providers/is_resizing_provider.dart';
import 'package:agenda_backend/features/agenda/providers/layout_config_provider.dart';
import 'package:agenda_backend/features/agenda/providers/staff_filter_providers.dart';
import 'package:agenda_backend/features/agenda/providers/tenant_time_provider.dart';
import 'package:agenda_backend/features/agenda/providers/weekly_appointments_provider.dart';
import 'package:agenda_backend/features/agenda/utils/week_range.dart';
import 'package:agenda_backend/features/services/providers/services_provider.dart';
import 'package:agenda_backend/features/staff/providers/availability_exceptions_provider.dart';
import 'package:agenda_backend/features/staff/providers/staff_planning_provider.dart';
import 'package:agenda_backend/features/staff/providers/staff_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/agenda_scroll_request_provider.dart';
import '../providers/date_range_provider.dart';
import '../providers/initial_scroll_provider.dart';
import '../providers/location_providers.dart';

class AgendaScreen extends ConsumerStatefulWidget {
  const AgendaScreen({super.key, this.initialClientId});

  /// Se valorizzato, crea automaticamente una prenotazione rapida per il client.
  final int? initialClientId;

  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  final ScrollController _hourColumnController = ScrollController(
    keepScrollOffset: false,
  );
  final AgendaDayController _timelineController = AgendaDayController();
  late final ProviderSubscription<AgendaScrollRequest?> _scrollRequestSub;
  late final ProviderSubscription<int> _locationSub;
  late final ProviderSubscription<bool> _initialScrollSub;
  Timer? _pollingTimer;

  /// Intervallo polling: 10 secondi in debug, 5 minuti in produzione
  static const _pollingIntervalDebug = Duration(seconds: 10);
  static const _pollingIntervalProd = Duration(minutes: 5);

  double? _pendingHourOffset;
  bool _pendingApplyScheduled = false;
  bool _quickBookingTriggered = false;

  // 🔹 offset verticale "master" della giornata (usato anche dalla CurrentTimeLine)
  double _verticalOffset = 0;

  // 🔹 Flag per distinguere polling automatico da altre operazioni
  bool _isPolling = false;
  bool _agendaViewportReady = false;
  int _weekAutoScrollRequestId = 0;
  DateTime? _weekAutoScrollTargetDate;
  String? _exceptionsLoadKey;
  bool _didApplyInitialEmptyStaffFilterFallback = false;

  void _ensureExceptionsLoadedForVisibleRange({
    required int businessId,
    required DateTime selectedDate,
    required CalendarViewMode calendarViewMode,
    required List<int> staffIds,
  }) {
    if (businessId <= 0 || staffIds.isEmpty) return;

    final targetDate = DateUtils.dateOnly(selectedDate);
    final rangeStart = calendarViewMode == CalendarViewMode.week
        ? targetDate.subtract(
            Duration(days: targetDate.weekday - DateTime.monday),
          )
        : targetDate;
    final rangeEnd = calendarViewMode == CalendarViewMode.week
        ? rangeStart.add(const Duration(days: 6))
        : rangeStart;

    final sortedStaffIds = [...staffIds]..sort();
    final key =
        '$businessId|${rangeStart.toIso8601String()}|${rangeEnd.toIso8601String()}|${sortedStaffIds.join(",")}';
    if (_exceptionsLoadKey == key) return;
    _exceptionsLoadKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        _loadExceptionsForRange(
          sortedStaffIds,
          fromDate: rangeStart,
          toDate: rangeEnd,
        ),
      );
    });
  }

  Future<void> _loadExceptionsForRange(
    List<int> staffIds, {
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final notifier = ref.read(availabilityExceptionsProvider.notifier);
    for (final staffId in staffIds) {
      try {
        await notifier.loadExceptionsForStaff(
          staffId,
          fromDate: fromDate,
          toDate: toDate,
        );
      } catch (_) {
        // Ignora errori puntuali: la UI continua a funzionare sui dati disponibili.
      }
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _scrollRequestSub.close();
    _locationSub.close();
    _initialScrollSub.close();
    _timelineController.dispose();
    _hourColumnController.dispose();
    super.dispose();
  }

  void _handleMasterScroll(double offset) {
    final initialScrollDone = ref.read(initialScrollDoneProvider);

    // sincronizza lo scroll della colonna oraria con la timeline
    if (!_hourColumnController.hasClients) {
      if (mounted) {
        setState(() {
          _verticalOffset = offset;
        });
      }
      _pendingHourOffset = offset;
      _schedulePendingApply();
      return;
    }

    final position = _hourColumnController.position;
    final target = offset.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    final canonicalOffset = target.toDouble();
    final needsTimelineCorrection = (offset - canonicalOffset).abs() >= 0.5;

    // Usa sempre l'offset canonico (clampato sulla colonna ore) come source of truth.
    if (mounted) {
      setState(() {
        _verticalOffset = canonicalOffset;
        if (initialScrollDone) {
          _agendaViewportReady = true;
        }
      });
    }

    if ((position.pixels - canonicalOffset).abs() >= 0.5) {
      _hourColumnController.jumpTo(canonicalOffset);
    }

    if (needsTimelineCorrection) {
      _timelineController.jumpTo(canonicalOffset);
    }
  }

  void _applyPendingOffset() {
    if (!mounted || _pendingHourOffset == null) return;
    final initialScrollDone = ref.read(initialScrollDoneProvider);

    if (!_hourColumnController.hasClients) {
      _schedulePendingApply();
      return;
    }

    final position = _hourColumnController.position;
    final target = _pendingHourOffset!.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    final canonicalOffset = target.toDouble();
    final needsTimelineCorrection =
        (_pendingHourOffset! - canonicalOffset).abs() >= 0.5;

    _hourColumnController.jumpTo(canonicalOffset);
    if (needsTimelineCorrection) {
      _timelineController.jumpTo(canonicalOffset);
    }
    if (mounted) {
      setState(() {
        _verticalOffset = canonicalOffset;
        if (initialScrollDone) {
          _agendaViewportReady = true;
        }
      });
    }
    _pendingHourOffset = null;
  }

  void _schedulePendingApply() {
    if (_pendingApplyScheduled) return;
    _pendingApplyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingApplyScheduled = false;
      if (!mounted) return;
      _applyPendingOffset();
    });
  }

  @override
  void initState() {
    super.initState();

    // NOTE: Non chiamiamo refresh() qui perché:
    // 1. I provider AsyncNotifier caricano i dati automaticamente nel build()
    // 2. Il refresh al cambio tab avviene in _refreshProvidersForTab()

    // Polling automatico per aggiornare gli appuntamenti
    // Debug: ogni 10 secondi, Produzione: ogni 5 minuti
    final interval = kDebugMode ? _pollingIntervalDebug : _pollingIntervalProd;
    _pollingTimer = Timer.periodic(interval, (_) {
      if (!mounted) return;
      // Ricarica solo gli appuntamenti (dati che cambiano più frequentemente)
      _isPolling = true;
      ref.invalidate(appointmentsProvider);
      _invalidateCurrentWeekAppointments();
    });

    _scrollRequestSub = ref.listenManual<AgendaScrollRequest?>(
      agendaScrollRequestProvider,
      (prev, next) {
        if (next == null) return;
        final currentDate = ref.read(agendaDateProvider);
        final targetDate = next.date;
        if (!DateUtils.isSameDay(currentDate, targetDate)) {
          ref.read(agendaDateProvider.notifier).set(targetDate);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ref
                .read(agendaScrollRequestProvider.notifier)
                .request(next.appointment);
          });
        }
      },
    );

    _initialScrollSub = ref.listenManual<bool>(initialScrollDoneProvider, (
      prev,
      next,
    ) {
      if (!mounted) return;
      if (!next) {
        if (_agendaViewportReady) {
          setState(() {
            _agendaViewportReady = false;
          });
        }
        return;
      }
      if (_hourColumnController.hasClients && !_agendaViewportReady) {
        setState(() {
          _agendaViewportReady = true;
        });
      }
    }, fireImmediately: true);

    _locationSub = ref.listenManual<int>(currentLocationIdProvider, (
      prev,
      next,
    ) {
      if (prev == null || prev == next) return;
      if (mounted && _agendaViewportReady) {
        setState(() {
          _agendaViewportReady = false;
        });
      }
      final session = ref.read(bookingRescheduleSessionProvider);
      if (session == null) return;
      ref.read(agendaDateProvider.notifier).set(session.originDate);
      ref.read(bookingRescheduleSessionProvider.notifier).clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;

    ref.listen<bool>(agendaBootstrapUnlockedProvider, (prev, next) {
      if (!next || _didApplyInitialEmptyStaffFilterFallback) return;

      final mode = ref.read(staffFilterModeProvider);
      final selectedIds = ref.read(selectedStaffIdsProvider);

      if (mode == StaffFilterMode.custom && selectedIds.isEmpty) {
        ref
            .read(staffFilterModeProvider.notifier)
            .set(StaffFilterMode.onDutyTeam);
      }

      _didApplyInitialEmptyStaffFilterFallback = true;
    });

    // Controlla se i dati sono ancora in caricamento
    final staffAsync = ref.watch(allStaffProvider);
    final locations = ref.watch(locationsProvider);
    final locationsLoaded = ref.watch(locationsLoadedProvider);
    final currentLocationId = ref.watch(currentLocationIdProvider);
    final appointmentsAsync = ref.watch(appointmentsProvider);
    final rescheduleSession = ref.watch(bookingRescheduleSessionProvider);
    final canUseBookingReschedule = ref.watch(canUseBookingRescheduleProvider);
    final currentBusinessId = ref.watch(currentBusinessIdProvider);
    final globalLoadingCount = ref.watch(globalLoadingProvider);
    final isGlobalLoading = globalLoadingCount > 0;

    // Ascolta cambi data per resettare il flag polling
    // (se l'utente cambia data durante il polling, deve mostrare loading)
    ref.listen(agendaDateProvider, (prev, next) {
      if (prev != null && !DateUtils.isSameDay(prev, next)) {
        _isPolling = false;
        if (_agendaViewportReady) {
          setState(() {
            _agendaViewportReady = false;
          });
        }

        final calendarMode = ref.read(calendarViewModeProvider);
        if (calendarMode == CalendarViewMode.week) {
          final prevMonday = DateUtils.dateOnly(
            prev.subtract(Duration(days: prev.weekday - DateTime.monday)),
          );
          final nextMonday = DateUtils.dateOnly(
            next.subtract(Duration(days: next.weekday - DateTime.monday)),
          );
          if (!DateUtils.isSameDay(prevMonday, nextMonday)) {
            setState(() {
              _weekAutoScrollRequestId++;
              _weekAutoScrollTargetDate = nextMonday;
            });
          }
        }
      }
    });

    ref.listen<bool>(canUseBookingRescheduleProvider, (prev, next) {
      if (next) return;
      final session = ref.read(bookingRescheduleSessionProvider);
      if (session == null) return;
      ref.read(bookingRescheduleSessionProvider.notifier).clear();
    });

    // Resetta il flag polling quando il caricamento finisce
    if (!appointmentsAsync.isLoading) {
      _isPolling = false;
    }

    // Stato "waiting" base (prerequisiti pagina)
    final hasLocations = locations.isNotEmpty;
    final isWaitingForBusiness = currentBusinessId <= 0;
    final isWaitingForLocations = !locationsLoaded;
    final isWaitingForLocationSelection =
        locationsLoaded && hasLocations && currentLocationId == 0;
    final isWaitingBaseData =
        isWaitingForBusiness ||
        (staffAsync.isLoading && !staffAsync.hasValue) ||
        isWaitingForLocations ||
        isWaitingForLocationSelection ||
        (appointmentsAsync.isLoading && !_isPolling && !staffAsync.hasValue);

    // Dati usati dalle condizioni di bootstrap iniziale
    final staffData = staffAsync.asData?.value;
    final appointmentsData = appointmentsAsync.asData?.value;
    final staffList = ref.watch(filteredStaffProvider);
    final staffInCurrentLocation = ref.watch(staffForCurrentLocationProvider);
    final staffPlannings = ref.watch(staffPlanningsProvider);
    final staffFilterMode = ref.watch(staffFilterModeProvider);
    final calendarViewMode = ref.watch(calendarViewModeProvider);
    final agendaDate = ref.watch(agendaDateProvider);
    final layoutConfig = ref.watch(layoutConfigProvider);
    final timezone = ref.watch(effectiveTenantTimezoneProvider);
    final hasStaff = staffList.isNotEmpty;
    final serviceVariantsAsync = ref.watch(serviceVariantsProvider);
    final serviceVariants = serviceVariantsAsync.value ?? const [];
    final useServiceColors = ref.watch(
      effectiveUseServiceColorsForAppointmentsProvider,
    );

    _ensureExceptionsLoadedForVisibleRange(
      businessId: currentBusinessId,
      selectedDate: agendaDate,
      calendarViewMode: calendarViewMode,
      staffIds: staffInCurrentLocation.map((s) => s.id).toList(),
    );

    var rescheduleModeHint = context.l10n.bookingRescheduleModeHint;
    if (rescheduleSession != null &&
        calendarViewMode == CalendarViewMode.week) {
      final visibleWeek = computeWeekRange(agendaDate, timezone);
      final visibleWeekStart = DateUtils.dateOnly(visibleWeek.start);
      final visibleWeekEnd = DateUtils.dateOnly(visibleWeek.end);
      final originDate = DateUtils.dateOnly(rescheduleSession.originDate);
      final isOriginInVisibleWeek =
          !originDate.isBefore(visibleWeekStart) &&
          !originDate.isAfter(visibleWeekEnd);
      rescheduleModeHint = isOriginInVisibleWeek
          ? context.l10n.bookingRescheduleModeHintWeekSame
          : context.l10n.bookingRescheduleModeHintWeekDifferent;
    }

    ref.listen<CalendarViewMode>(calendarViewModeProvider, (prev, next) {
      if (prev == CalendarViewMode.day && next == CalendarViewMode.week) {
        final selectedDay = DateUtils.dateOnly(ref.read(agendaDateProvider));
        if (!mounted) return;
        setState(() {
          _weekAutoScrollRequestId++;
          _weekAutoScrollTargetDate = selectedDay;
        });
      }
    });

    // Bootstrap iniziale: evita empty-state falsi durante i primi caricamenti
    final isInitialStaffLoad =
        staffAsync.isLoading && (staffData?.isEmpty ?? true);
    final isInitialAppointmentsLoad =
        appointmentsAsync.isLoading &&
        !_isPolling &&
        (appointmentsData?.isEmpty ?? true);
    final isPlanningBootstrapLoading =
        staffFilterMode == StaffFilterMode.onDutyTeam &&
        staffInCurrentLocation.isNotEmpty &&
        staffInCurrentLocation.any(
          (staff) =>
              !staffPlannings.containsKey(staff.id) &&
              ref.watch(ensureStaffPlanningLoadedProvider(staff.id)).isLoading,
        );
    final hasStaleVariantsForCurrentLocation =
        currentLocationId > 0 &&
        serviceVariants.isNotEmpty &&
        serviceVariants.any(
          (variant) => variant.locationId != currentLocationId,
        );
    final isServiceVariantsBootstrapLoading =
        useServiceColors &&
        (serviceVariantsAsync.isLoading || hasStaleVariantsForCurrentLocation);
    final isBootstrapLoading =
        isWaitingBaseData ||
        isInitialStaffLoad ||
        isInitialAppointmentsLoad ||
        isPlanningBootstrapLoading ||
        isServiceVariantsBootstrapLoading;
    final shouldShowNoStaffState = !hasStaff && !isBootstrapLoading;
    final shouldDeferAgendaPaint = hasStaff && !_agendaViewportReady;
    final isResizing = ref.watch(isResizingProvider);

    final hourColumnWidth = layoutConfig.hourColumnWidth;
    final totalHeight = layoutConfig.totalHeight;

    // Se arriviamo con un clientId e non abbiamo ancora creato la prenotazione rapida
    final initialClientId = widget.initialClientId;
    if (initialClientId != null && !_quickBookingTriggered) {
      // Usa addPostFrame per evitare rebuild loop
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _quickBookingTriggered = true;
        ref
            .read(appointmentsProvider.notifier)
            .createQuickBookingForClient(initialClientId);
      });
    }

    final hourColumnStack = SizedBox(
      width: hourColumnWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.3),
                surfaceTintColor: Colors.transparent,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0x1F000000), width: 0.5),
                    ),
                  ),
                  child: SizedBox(
                    width: hourColumnWidth,
                    height: layoutConfig.headerHeight,
                  ),
                ),
              ),
              Expanded(
                child: ScrollConfiguration(
                  behavior: const NoScrollbarBehavior(),
                  child: SingleChildScrollView(
                    controller: _hourColumnController,
                    scrollDirection: Axis.vertical,
                    physics: isResizing || hasStaff
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    child: SizedBox(
                      width: hourColumnWidth,
                      child: const HourColumn(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final mainRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasStaff) hourColumnStack,
        if (hasStaff)
          AgendaVerticalDivider(
            height: totalHeight,
            thickness: 1,
            fadeTopHeight: layoutConfig.headerHeight,
          ),
        Expanded(
          child: AgendaDay(
            staffList: staffList,
            onVerticalOffsetChanged: _handleMasterScroll,
            controller: _timelineController,
            hourColumnWidth: hourColumnWidth,
            currentTimeVerticalOffset: _verticalOffset,
          ),
        ),
      ],
    );

    final dayAgendaContent = Stack(
      children: [
        Positioned.fill(
          child: Offstage(offstage: shouldDeferAgendaPaint, child: mainRow),
        ),
        if (shouldDeferAgendaPaint)
          Positioned.fill(
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: isGlobalLoading
                  ? const SizedBox.shrink()
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),
        if (shouldShowNoStaffState)
          Positioned.fill(
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.94),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      staffFilterMode == StaffFilterMode.onDutyTeam
                          ? context.l10n.agendaNoOnDutyTeamTitle
                          : context.l10n.agendaNoSelectedTeamTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (staffFilterMode != StaffFilterMode.allTeam) ...[
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
            ),
          ),
      ],
    );

    final agendaContent = calendarViewMode == CalendarViewMode.day
        ? dayAgendaContent
        : WeeklyAppointmentsView(
            staffList: staffList,
            staffFilterMode: staffFilterMode,
            autoScrollRequestId: _weekAutoScrollRequestId,
            autoScrollTargetDate: _weekAutoScrollTargetDate,
          );

    return Stack(
      children: [
        Positioned.fill(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (rescheduleSession != null && canUseBookingReschedule)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  color: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer.withOpacity(0.18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          rescheduleModeHint,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 12),
                      AppOutlinedActionButton(
                        onPressed: () {
                          ref
                              .read(agendaDateProvider.notifier)
                              .set(rescheduleSession.originDate);
                          ref
                              .read(bookingRescheduleSessionProvider.notifier)
                              .clear();
                        },
                        child: Text(context.l10n.bookingRescheduleCancelAction),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: isBootstrapLoading
                    // Mostra loading indicator durante il caricamento
                    ? isGlobalLoading
                          ? const SizedBox.shrink()
                          : const Center(child: CircularProgressIndicator())
                    : !hasLocations
                    ? Center(
                        child: Text(
                          context.l10n.agendaNoLocations,
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      )
                    : agendaContent,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _invalidateCurrentWeekAppointments() {
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
