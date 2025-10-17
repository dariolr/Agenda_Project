import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/models/staff.dart';
import '../../../../../core/widgets/no_scrollbar_behavior.dart';
import '../../../domain/config/layout_config.dart';
import '../../../providers/agenda_providers.dart';
import '../../../providers/agenda_scroll_provider.dart';
import '../../../providers/appointment_providers.dart';
import '../../../providers/layout_config_provider.dart';
import '../widgets/agenda_dividers.dart';
import '../widgets/current_time_line.dart';
import 'hour_column.dart';
import 'responsive_layout.dart';
import 'staff_column.dart';
import 'staff_header_row.dart';

class MultiStaffDayView extends ConsumerStatefulWidget {
  final List<Staff> staffList;

  const MultiStaffDayView({super.key, required this.staffList});

  @override
  ConsumerState<MultiStaffDayView> createState() => _MultiStaffDayViewState();
}

class _MultiStaffDayViewState extends ConsumerState<MultiStaffDayView> {
  Timer? _autoScrollTimer;
  Timer? _centerTimer;
  late final ProviderSubscription<Offset?> _dragSub;

  // 🔗 Controller orizzontale dedicato all'header
  final ScrollController _headerHCtrl = ScrollController();
  bool _isSyncing = false;

  static const double _scrollEdgeMargin = 100;
  static const double _scrollSpeed = 20;
  static const Duration _scrollInterval = Duration(milliseconds: 50);

  @override
  void initState() {
    super.initState();

    // Auto-scroll verticale durante il drag
    _dragSub = ref.listenManual<Offset?>(dragPositionProvider, (
      previous,
      next,
    ) {
      if (next != null) {
        _startAutoScroll();
      } else {
        _stopAutoScroll();
      }
    });

    // Centra la riga rossa all’avvio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerCurrentTimeLine();
      _setupHorizontalSync(); // <- dopo che i widget hanno un controller attaccato
    });

    // Riesegui il centramento ogni 5 minuti
    _centerTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _centerCurrentTimeLine();
    });
  }

  void _setupHorizontalSync() {
    final bodyCtrl = ref
        .read(agendaScrollProvider(widget.staffList))
        .horizontalScrollCtrl;

    // allinea offset iniziale
    if (_headerHCtrl.hasClients && bodyCtrl.hasClients) {
      _headerHCtrl.jumpTo(bodyCtrl.offset);
    }

    // listener body -> header
    bodyCtrl.addListener(() {
      if (_isSyncing) return;
      if (!_headerHCtrl.hasClients) return;
      _isSyncing = true;
      _headerHCtrl.jumpTo(bodyCtrl.offset);
      _isSyncing = false;
    });

    // listener header -> body
    _headerHCtrl.addListener(() {
      if (_isSyncing) return;
      if (!bodyCtrl.hasClients) return;
      _isSyncing = true;
      bodyCtrl.jumpTo(_headerHCtrl.offset);
      _isSyncing = false;
    });
  }

  void _centerCurrentTimeLine() {
    final scrollState = ref.read(agendaScrollProvider(widget.staffList));
    final verticalCtrl = scrollState.verticalScrollCtrl;
    if (!verticalCtrl.hasClients) return;

    final now = DateTime.now();
    final minutesSinceMidnight = now.hour * 60 + now.minute;
    final slotHeight = LayoutConfig.slotHeight;
    final offset =
        (minutesSinceMidnight / LayoutConfig.minutesPerSlot) * slotHeight;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final viewHeight = renderBox.size.height;
    final availableHeight = viewHeight - LayoutConfig.headerHeight;

    const double bias = 0.4;
    final targetOffset = (offset - availableHeight * bias).clamp(
      0.0,
      verticalCtrl.position.maxScrollExtent,
    );
    verticalCtrl.jumpTo(targetOffset);
  }

  void _startAutoScroll() {
    if (_autoScrollTimer != null) return;
    _autoScrollTimer = Timer.periodic(_scrollInterval, (_) {
      if (!mounted) return;

      final dragPos = ref.read(dragPositionProvider);
      if (dragPos == null) {
        _stopAutoScroll();
        return;
      }

      final scrollState = ref.read(agendaScrollProvider(widget.staffList));
      final verticalCtrl = scrollState.verticalScrollCtrl;
      if (!verticalCtrl.hasClients) return;

      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final localPos = renderBox.globalToLocal(dragPos);
      final viewHeight = renderBox.size.height;
      final maxScrollExtent = verticalCtrl.position.maxScrollExtent;
      final currentOffset = verticalCtrl.offset;

      double? newOffset;
      if (localPos.dy < _scrollEdgeMargin && currentOffset > 0) {
        newOffset = (currentOffset - _scrollSpeed).clamp(0, maxScrollExtent);
      } else if (localPos.dy > viewHeight - _scrollEdgeMargin &&
          currentOffset < maxScrollExtent) {
        newOffset = (currentOffset + _scrollSpeed).clamp(0, maxScrollExtent);
      }
      if (newOffset != null && newOffset != currentOffset) {
        verticalCtrl.jumpTo(newOffset);
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  @override
  void dispose() {
    _dragSub.close();
    _stopAutoScroll();
    _centerTimer?.cancel();
    _headerHCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appointments = ref.watch(appointmentsProvider);
    final scrollState = ref.watch(agendaScrollProvider(widget.staffList));
    final layout = ResponsiveLayout.of(
      context,
      staffCount: widget.staffList.length,
    );
    final slotHeight = ref.watch(layoutConfigProvider);

    final totalContentHeight = LayoutConfig.totalSlots * slotHeight;
    final hourWidth = LayoutConfig.hourColumnWidth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HEADER: scroll orizzontale con controller dedicato, sincronizzato al body
        Material(
          elevation: 3,
          child: SizedBox(
            height: LayoutConfig.headerHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Colonna orari fissa
                SizedBox(width: hourWidth),

                // 🔹 Sezione staff scrollabile orizzontalmente
                Expanded(
                  child: ScrollConfiguration(
                    behavior: const NoScrollbarBehavior(),
                    child: SingleChildScrollView(
                      controller: _headerHCtrl,
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: StaffHeaderRow(
                        staffList: widget.staffList,
                        scrollController: _headerHCtrl,
                        columnWidth: layout.columnWidth,
                        hourColumnWidth: hourWidth,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // BODY
        Expanded(
          child: ScrollConfiguration(
            behavior: const NoScrollbarBehavior(),
            child: SingleChildScrollView(
              controller: scrollState.verticalScrollCtrl,
              physics: const ClampingScrollPhysics(),
              child: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: hourWidth, child: const HourColumn()),
                      AgendaVerticalDivider(height: totalContentHeight),
                      Expanded(
                        child: ScrollConfiguration(
                          behavior: const NoScrollbarBehavior(),
                          child: SingleChildScrollView(
                            controller: scrollState
                                .horizontalScrollCtrl, // <- controller body
                            scrollDirection: Axis.horizontal,
                            physics: const ClampingScrollPhysics(),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: widget.staffList.asMap().entries.map((
                                entry,
                              ) {
                                final index = entry.key;
                                final staff = entry.value;
                                final isLast =
                                    index == widget.staffList.length - 1;
                                final staffAppointments = appointments
                                    .where((a) => a.staffId == staff.id)
                                    .toList();

                                return StaffColumn(
                                  staff: staff,
                                  appointments: staffAppointments,
                                  columnWidth: layout.columnWidth,
                                  showRightBorder:
                                      widget.staffList.length > 1 && !isLast,
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  CurrentTimeLine(hourColumnWidth: hourWidth),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
