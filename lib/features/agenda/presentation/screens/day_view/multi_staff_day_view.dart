import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/models/staff.dart';
import '../../../../../core/widgets/no_scrollbar_behavior.dart';
import '../../../domain/config/layout_config.dart';
import '../../../providers/agenda_providers.dart'; // 👈 dragPositionProvider
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
  late final ProviderSubscription<Offset?> _dragSub;

  // Configurazione auto-scroll
  static const double _scrollEdgeMargin = 100; // distanza dai bordi
  static const double _scrollSpeed = 20; // pixel per tick
  static const Duration _scrollInterval = Duration(milliseconds: 50);

  @override
  void initState() {
    super.initState();

    // 🔹 Ascolta la posizione del drag per avviare/interrompere auto-scroll
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

      // 🔼 Scroll verso l’alto
      if (localPos.dy < _scrollEdgeMargin && currentOffset > 0) {
        newOffset = (currentOffset - _scrollSpeed).clamp(0, maxScrollExtent);
      }
      // 🔽 Scroll verso il basso
      else if (localPos.dy > viewHeight - _scrollEdgeMargin &&
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

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Header con nomi staff
            Material(
              elevation: 3,
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: LayoutConfig.headerHeight,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withOpacity(0.35),
                      width: 1.2,
                    ),
                  ),
                ),
                child: StaffHeaderRow(
                  staffList: widget.staffList,
                  scrollController: scrollState.horizontalScrollCtrl,
                  columnWidth: layout.columnWidth,
                  hourColumnWidth: hourWidth,
                ),
              ),
            ),

            // 🔹 Corpo principale scrollabile
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
                            child: SingleChildScrollView(
                              controller: scrollState.horizontalScrollCtrl,
                              scrollDirection: Axis.horizontal,
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
                        ],
                      ),

                      // 🔴 Riga rossa del tempo corrente (aggiornamento isolato)
                      CurrentTimeLine(hourColumnWidth: hourWidth),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
