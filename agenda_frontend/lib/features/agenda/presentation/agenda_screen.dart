import 'package:agenda_frontend/core/widgets/no_scrollbar_behavior.dart';
import 'package:agenda_frontend/features/agenda/presentation/screens/day_view/agenda_day.dart';
import 'package:agenda_frontend/features/agenda/presentation/screens/day_view/components/hour_column.dart';
import 'package:agenda_frontend/features/agenda/presentation/screens/widgets/agenda_dividers.dart';
import 'package:agenda_frontend/features/agenda/providers/appointment_providers.dart';
import 'package:agenda_frontend/features/agenda/providers/is_resizing_provider.dart';
import 'package:agenda_frontend/features/agenda/providers/layout_config_provider.dart';
import 'package:agenda_frontend/features/agenda/providers/staff_filter_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  double? _pendingHourOffset;
  bool _pendingApplyScheduled = false;
  bool _isSyncingFromMaster = false;
  bool _quickBookingTriggered = false;

  // 🔹 offset verticale "master" della giornata (usato anche dalla CurrentTimeLine)
  double _verticalOffset = 0;

  @override
  void dispose() {
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

    _isSyncingFromMaster = true;
    try {
      _hourColumnController.jumpTo(target);
    } finally {
      _isSyncingFromMaster = false;
    }
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

  bool _handleHourColumnScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }
    if (_isSyncingFromMaster) {
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      final offset = notification.metrics.pixels;
      _timelineController.jumpTo(offset);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final staffList = ref.watch(filteredStaffProvider);
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
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _handleHourColumnScroll,
                    child: SingleChildScrollView(
                      controller: _hourColumnController,
                      scrollDirection: Axis.vertical,
                      physics: isResizing
                          ? const NeverScrollableScrollPhysics()
                          : null,
                      child: SizedBox(
                        width: hourColumnWidth,
                        child: const HourColumn(),
                      ),
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
        hourColumnStack,
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
            children: [Expanded(child: mainRow)],
          ),
        ),
      ],
    );
  }
}
