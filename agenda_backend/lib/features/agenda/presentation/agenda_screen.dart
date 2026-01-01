import 'dart:async';

import 'package:agenda_backend/core/l10n/l10_extension.dart';
import 'package:agenda_backend/core/widgets/no_scrollbar_behavior.dart';
import 'package:agenda_backend/features/agenda/domain/staff_filter_mode.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/day_view/agenda_day.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/day_view/components/hour_column.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/widgets/agenda_dividers.dart';
import 'package:agenda_backend/features/agenda/providers/appointment_providers.dart';
import 'package:agenda_backend/features/agenda/providers/is_resizing_provider.dart';
import 'package:agenda_backend/features/agenda/providers/layout_config_provider.dart';
import 'package:agenda_backend/features/agenda/providers/staff_filter_providers.dart';
import 'package:agenda_backend/features/clients/providers/clients_providers.dart';
import 'package:agenda_backend/features/services/providers/services_provider.dart';
import 'package:agenda_backend/features/staff/providers/staff_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/agenda_scroll_request_provider.dart';
import '../providers/date_range_provider.dart';
import '../providers/location_providers.dart';

class AgendaScreen extends ConsumerStatefulWidget {
  const AgendaScreen({super.key, this.initialClientId});

  /// Se valorizzato, crea automaticamente una prenotazione rapida per il client.
  final int? initialClientId;

  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  final ScrollController _hourColumnController = ScrollController();
  final AgendaDayController _timelineController = AgendaDayController();
  late final ProviderSubscription<AgendaScrollRequest?> _scrollRequestSub;
  Timer? _pollingTimer;

  /// Intervallo polling: 10 secondi in debug, 5 minuti in produzione
  static const _pollingIntervalDebug = Duration(seconds: 10);
  static const _pollingIntervalProd = Duration(minutes: 5);

  double? _pendingHourOffset;
  bool _pendingApplyScheduled = false;
  bool _quickBookingTriggered = false;

  // 🔹 offset verticale "master" della giornata (usato anche dalla CurrentTimeLine)
  double _verticalOffset = 0;

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _scrollRequestSub.close();
    _timelineController.dispose();
    _hourColumnController.dispose();
    super.dispose();
  }

  void _handleMasterScroll(double offset) {
    // aggiorna l'offset usato dalla CurrentTimeLine
    if (mounted) {
      setState(() {
        _verticalOffset = offset;
      });
    }

    // sincronizza lo scroll della colonna oraria con la timeline
    if (!_hourColumnController.hasClients) {
      _pendingHourOffset = offset;
      _schedulePendingApply();
      return;
    }

    final position = _hourColumnController.position;
    final target = offset.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    if ((position.pixels - target).abs() < 0.5) {
      return;
    }

    _hourColumnController.jumpTo(target);
  }

  void _applyPendingOffset() {
    if (!mounted || _pendingHourOffset == null) return;

    if (!_hourColumnController.hasClients) {
      _schedulePendingApply();
      return;
    }

    final position = _hourColumnController.position;
    final target = _pendingHourOffset!.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    _hourColumnController.jumpTo(target);
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

    // Ricarica tutti i dati principali dal DB quando si entra nell'agenda
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(allStaffProvider.notifier).refresh();
      ref.read(locationsProvider.notifier).refresh();
      ref.read(servicesProvider.notifier).refresh();
      ref.read(clientsProvider.notifier).refresh();
      // Gli appuntamenti vengono ricaricati automaticamente quando cambia la data
      // grazie al watch su agendaDateProvider in AppointmentsNotifier.build()
    });

    // Polling automatico per aggiornare gli appuntamenti
    // Debug: ogni 10 secondi, Produzione: ogni 5 minuti
    final interval = kDebugMode ? _pollingIntervalDebug : _pollingIntervalProd;
    _pollingTimer = Timer.periodic(interval, (_) {
      if (!mounted) return;
      // Ricarica solo gli appuntamenti (dati che cambiano più frequentemente)
      ref.invalidate(appointmentsProvider);
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
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final staffList = ref.watch(filteredStaffProvider);
    final staffFilterMode = ref.watch(staffFilterModeProvider);
    final hasStaff = staffList.isNotEmpty;
    final isResizing = ref.watch(isResizingProvider);
    final layoutConfig = ref.watch(layoutConfigProvider);

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
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      offset: const Offset(3, 0),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: SizedBox(
                  width: hourColumnWidth,
                  height: layoutConfig.headerHeight,
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

    return Stack(
      children: [
        Positioned.fill(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: hasStaff
                    ? mainRow
                    : Center(
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
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
