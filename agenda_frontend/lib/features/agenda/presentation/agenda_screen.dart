import 'package:agenda_frontend/core/widgets/no_scrollbar_behavior.dart';
import 'package:agenda_frontend/features/agenda/presentation/screens/day_view/agenda_day_timeline.dart';
import 'package:agenda_frontend/features/agenda/presentation/screens/day_view/hour_column.dart';
import 'package:agenda_frontend/features/agenda/presentation/screens/widgets/agenda_dividers.dart';
import 'package:agenda_frontend/features/agenda/providers/is_resizing_provider.dart';
import 'package:agenda_frontend/features/agenda/providers/layout_config_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/staff_providers.dart';

class AgendaScreen extends ConsumerStatefulWidget {
  const AgendaScreen({super.key});

  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  final ScrollController _hourColumnController = ScrollController();
  final AgendaDayTimelineController _timelineController =
      AgendaDayTimelineController();
  double? _pendingHourOffset;
  bool _pendingApplyScheduled = false;
  bool _isSyncingFromMaster = false;

  @override
  void dispose() {
    //_pagerController.dispose();
    _timelineController.dispose();
    _hourColumnController.dispose();
    super.dispose();
  }

  void _handleMasterScroll(double offset) {
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
    if (!mounted) return;
    if (_pendingHourOffset == null) {
      return;
    }

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
    // ✅ Recupera la lista dello staff filtrata sulla location corrente
    final staffList = ref.watch(staffForCurrentLocationProvider);
    final isResizing = ref.watch(isResizingProvider);
    final layoutConfig = ref.watch(layoutConfigProvider);

    final hourColumnWidth = layoutConfig.hourColumnWidth;
    final totalHeight = layoutConfig.totalHeight;
    return SafeArea(
      // Passa la lista dello staff alla view
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
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
                      // mantiene l'assenza di scrollbar come prima
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
              AgendaVerticalDivider(height: totalHeight, thickness: 1),
              Expanded(
                child: AgendaDayTimeline(
                  staffList: staffList,
                  onVerticalOffsetChanged: _handleMasterScroll,
                  controller: _timelineController,
                ),
              ),
            ],
          ),
          //CurrentTimeLine(hourColumnWidth: hourColumnWidth),
        ],
      ),
    );
  }
}
