import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/models/staff.dart';
import '../../../providers/agenda_providers.dart';
import '../../../providers/agenda_scroll_provider.dart';
import '../../../providers/appointment_providers.dart';
import '../../../providers/drag_layer_link_provider.dart';
import '../../../providers/is_resizing_provider.dart'; // 👈 nuovo import
import '../../../providers/layout_config_provider.dart';
import 'agenda_staff_body.dart';
import 'agenda_staff_header.dart';
import 'responsive_layout.dart';

class MultiStaffDayView extends ConsumerStatefulWidget {
  final List<Staff> staffList;
  final DateTime date;
  final double initialScrollOffset;
  final ValueChanged<double>? onScrollOffsetChanged;

  const MultiStaffDayView({
    super.key,
    required this.staffList,
    required this.date,
    required this.initialScrollOffset,
    this.onScrollOffsetChanged,
  });

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
  ScrollController? _verticalCtrl;
  bool _hasCenteredCurrentTime = false;

  AgendaScrollKey get _scrollKey => AgendaScrollKey(
    staff: widget.staffList,
    date: widget.date,
    initialOffset: widget.initialScrollOffset,
  );

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
    if (!force &&
        _staffSignature != null &&
        listEquals(_staffSignature, newSignature)) {
      return;
    }
    _staffSignature = newSignature;

    final bodyCtrl = ref
        .read(agendaScrollProvider(_scrollKey))
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

  void _onVerticalScrollChanged() {
    final controller = _verticalCtrl;
    if (controller == null) return;
    widget.onScrollOffsetChanged?.call(controller.offset);
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

      final scrollState = ref.read(agendaScrollProvider(_scrollKey));
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
    _verticalCtrl?.removeListener(_onVerticalScrollChanged);
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
    if (!DateUtils.isSameDay(oldWidget.date, widget.date) ||
        oldWidget.initialScrollOffset != widget.initialScrollOffset) {
      _hasCenteredCurrentTime = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final appointments = ref.watch(appointmentsForCurrentLocationProvider);
        final scrollState = ref.watch(agendaScrollProvider(_scrollKey));
        final verticalCtrl = scrollState.verticalScrollCtrl;
        if (_verticalCtrl != verticalCtrl) {
          _verticalCtrl?.removeListener(_onVerticalScrollChanged);
          _verticalCtrl = verticalCtrl;
          _verticalCtrl?.addListener(_onVerticalScrollChanged);
        }
        final layoutConfig = ref.watch(layoutConfigProvider);
        final availableWidth =
            constraints.hasBoundedWidth && constraints.maxWidth.isFinite
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

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _hasCenteredCurrentTime) {
            return;
          }
          final now = DateTime.now();
          if (!DateUtils.isSameDay(widget.date, now)) {
            _hasCenteredCurrentTime = true;
            return;
          }
          final expectedOffset = (now.hour * 60 + now.minute) /
              layoutConfig.minutesPerSlot *
              layoutConfig.slotHeight;
          if ((widget.initialScrollOffset - expectedOffset).abs() >
              layoutConfig.slotHeight) {
            _hasCenteredCurrentTime = true;
            return;
          }
          final controller = _verticalCtrl;
          if (controller == null || !controller.hasClients) {
            return;
          }
          final position = controller.position;
          if (!position.haveDimensions) {
            return;
          }
          final viewport = position.viewportDimension;
          if (viewport <= 0) {
            return;
          }
          final target = (expectedOffset - viewport / 2)
              .clamp(0.0, position.maxScrollExtent);
          if ((controller.offset - target).abs() > 1) {
            controller.jumpTo(target);
          }
          _hasCenteredCurrentTime = true;
        });

        return Stack(
          children: [
            // BODY scrollabile con leader
            Positioned.fill(
              top: headerHeight,
              child: AgendaStaffBody(
                verticalController: scrollState.verticalScrollCtrl,
                horizontalController: scrollState.horizontalScrollCtrl,
                staffList: widget.staffList,
                appointments: appointments,
                layoutConfig: layoutConfig,
                availableWidth: availableWidth,
                isResizing: isResizing,
                dragLayerLink: link,
                bodyKey: _bodyKey,
              ),
            ),

            // HEADER staff
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: headerHeight,
              child: AgendaStaffHeader(
                staffList: widget.staffList,
                hourColumnWidth: hourW,
                totalHeight: totalHeight,
                headerHeight: headerHeight,
                columnWidth: layout.columnWidth,
                scrollController: _headerHCtrl,
              ),
            ),
          ],
        );
      },
    );
  }
}
