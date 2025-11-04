import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/models/staff.dart';
import '../../../../../core/widgets/no_scrollbar_behavior.dart';
import '../../../providers/agenda_providers.dart';
import '../../../providers/agenda_scroll_provider.dart';
import '../../../providers/appointment_providers.dart';
import '../../../providers/drag_layer_link_provider.dart';
import '../../../providers/is_resizing_provider.dart'; // 👈 nuovo import
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
  final ScrollController _headerHCtrl = ScrollController();
  bool _isSyncing = false;
  Offset? _initialDragPosition;
  bool _autoScrollArmed = false;
  ScrollController? _bodyHorizontalCtrl;
  List<int>? _staffSignature;

  static const double _scrollEdgeMargin = 100;
  static const double _scrollSpeed = 20;
  static const Duration _scrollInterval = Duration(milliseconds: 50);
  static const double _autoScrollActivationThreshold = 16;

  final GlobalKey _bodyKey = GlobalKey(); // registrazione RenderBox body

  @override
  void initState() {
    super.initState();

    _dragSub = ref.listenManual<Offset?>(dragPositionProvider, (prev, next) {
      if (next != null) {
        if (prev == null) {
          _initialDragPosition = next;
          _autoScrollArmed = false;
        }
        _startAutoScroll();
      } else {
        _initialDragPosition = null;
        _autoScrollArmed = false;
        _stopAutoScroll();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerBodyBox();
      _centerCurrentTimeLine();
      _setupHorizontalSync(force: true);
    });
  }

  void _registerBodyBox() {
    final box = _bodyKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      ref.read(dragBodyBoxProvider.notifier).set(box);
    }
  }

  void _setupHorizontalSync({bool force = false}) {
    final newSignature = widget.staffList.map((s) => s.id).toList();
    if (!force && _staffSignature != null && listEquals(_staffSignature, newSignature)) {
      return;
    }
    _staffSignature = newSignature;

    final bodyCtrl = ref
        .read(agendaScrollProvider(widget.staffList))
        .horizontalScrollCtrl;

    if (!force && identical(_bodyHorizontalCtrl, bodyCtrl)) {
      return;
    }

    _bodyHorizontalCtrl?.removeListener(_onBodyHorizontalScroll);
    _headerHCtrl.removeListener(_onHeaderHorizontalScroll);

    _bodyHorizontalCtrl = bodyCtrl;

    _bodyHorizontalCtrl?.addListener(_onBodyHorizontalScroll);
    _headerHCtrl.addListener(_onHeaderHorizontalScroll);

    if (_headerHCtrl.hasClients && _bodyHorizontalCtrl!.hasClients) {
      _headerHCtrl.jumpTo(_bodyHorizontalCtrl!.offset);
    }
  }

  void _onBodyHorizontalScroll() {
    final bodyCtrl = _bodyHorizontalCtrl;
    if (_isSyncing || bodyCtrl == null) return;
    if (!bodyCtrl.hasClients || !_headerHCtrl.hasClients) return;

    _isSyncing = true;
    _headerHCtrl.jumpTo(bodyCtrl.offset);
    _isSyncing = false;
  }

  void _onHeaderHorizontalScroll() {
    final bodyCtrl = _bodyHorizontalCtrl;
    if (_isSyncing || bodyCtrl == null) return;
    if (!bodyCtrl.hasClients || !_headerHCtrl.hasClients) return;

    _isSyncing = true;
    bodyCtrl.jumpTo(_headerHCtrl.offset);
    _isSyncing = false;
  }

  void _centerCurrentTimeLine() {
    final scrollState = ref.read(agendaScrollProvider(widget.staffList));
    final verticalCtrl = scrollState.verticalScrollCtrl;
    if (!verticalCtrl.hasClients) return;

    final now = DateTime.now();
    final minutes = now.hour * 60 + now.minute;
    final config = ref.read(layoutConfigProvider);
    final offset = (minutes / config.minutesPerSlot) * config.slotHeight;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final viewHeight = renderBox.size.height;
    final availableHeight = viewHeight - config.headerHeight;

    const bias = 0.4;
    final target = (offset - availableHeight * bias).clamp(
      0.0,
      verticalCtrl.position.maxScrollExtent,
    );
    verticalCtrl.jumpTo(target);
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

      if (!_autoScrollArmed && _initialDragPosition != null) {
        final deltaY = (dragPos.dy - _initialDragPosition!.dy).abs();
        if (deltaY < _autoScrollActivationThreshold) return;
        _autoScrollArmed = true;
      }

      final scrollState = ref.read(agendaScrollProvider(widget.staffList));
      final verticalCtrl = scrollState.verticalScrollCtrl;
      if (!verticalCtrl.hasClients) return;

      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final localPos = renderBox.globalToLocal(dragPos);
      final viewHeight = renderBox.size.height;
      final maxExtent = verticalCtrl.position.maxScrollExtent;
      final current = verticalCtrl.offset;

      double? newOffset;
      if (localPos.dy < _scrollEdgeMargin && current > 0) {
        newOffset = (current - _scrollSpeed).clamp(0, maxExtent);
      } else if (localPos.dy > viewHeight - _scrollEdgeMargin &&
          current < maxExtent) {
        newOffset = (current + _scrollSpeed).clamp(0, maxExtent);
      }

      if (newOffset != null && newOffset != current) {
        verticalCtrl.jumpTo(newOffset);
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _initialDragPosition = null;
    _autoScrollArmed = false;
  }

  @override
  void dispose() {
    _dragSub.close();
    _stopAutoScroll();
    _bodyHorizontalCtrl?.removeListener(_onBodyHorizontalScroll);
    _headerHCtrl.removeListener(_onHeaderHorizontalScroll);
    _headerHCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MultiStaffDayView oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _setupHorizontalSync(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final appointments = ref.watch(appointmentsForCurrentLocationProvider);
        final scrollState = ref.watch(agendaScrollProvider(widget.staffList));
        final layoutConfig = ref.watch(layoutConfigProvider);
        final availableWidth = constraints.hasBoundedWidth && constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final layout = ResponsiveLayout.of(
          context,
          staffCount: widget.staffList.length,
          config: layoutConfig,
          availableWidth: availableWidth,
        );
        final totalHeight = layoutConfig.totalHeight;
        final hourW = layoutConfig.hourColumnWidth;
        final headerHeight = layoutConfig.headerHeight;
        final link = ref.watch(dragLayerLinkProvider);

        // 🔹 blocca scroll se stiamo ridimensionando
        final isResizing = ref.watch(isResizingProvider);

        // Aggiorna periodicamente il bodyBox (in caso di resize)
        WidgetsBinding.instance.addPostFrameCallback((_) => _registerBodyBox());

        return Stack(
          children: [
            // BODY scrollabile con leader
            Positioned.fill(
              top: headerHeight,
              child: CompositedTransformTarget(
                key: _bodyKey,
                link: link,
                child: ScrollConfiguration(
                  behavior: const NoScrollbarBehavior(),
                  child: SingleChildScrollView(
                    controller: scrollState.verticalScrollCtrl,
                    // 👇 blocco dinamico scroll verticale
                    physics: isResizing
                        ? const NeverScrollableScrollPhysics()
                        : const ClampingScrollPhysics(),
                    child: Stack(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: hourW, child: const HourColumn()),
                            AgendaVerticalDivider(
                              height: totalHeight,
                              thickness: 1,
                            ),
                            Expanded(
                              child: ScrollConfiguration(
                                behavior: const NoScrollbarBehavior(),
                                child: SingleChildScrollView(
                                  controller: scrollState.horizontalScrollCtrl,
                                  scrollDirection: Axis.horizontal,
                                  physics: const ClampingScrollPhysics(),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children:
                                        widget.staffList.asMap().entries.map((e) {
                                      final i = e.key;
                                      final s = e.value;
                                      final last =
                                          i == widget.staffList.length - 1;
                                      final staffAppts = appointments
                                          .where((a) => a.staffId == s.id)
                                          .toList();

                                      return StaffColumn(
                                        staff: s,
                                        appointments: staffAppts,
                                        columnWidth: layout.columnWidth,
                                        showRightBorder:
                                            widget.staffList.length > 1 && !last,
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        CurrentTimeLine(hourColumnWidth: hourW),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // HEADER staff
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: headerHeight,
              child: Material(
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.3),
                surfaceTintColor: Colors.transparent,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0x1F000000), width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: hourW),
                      AgendaVerticalDivider(
                        height: totalHeight,
                        thickness: 1,
                        color: widget.staffList.isEmpty
                            ? Colors.transparent
                            : widget.staffList.first.color.withOpacity(0.10),
                      ),
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
                              hourColumnWidth: hourW,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
