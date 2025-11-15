import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/models/staff.dart';
import '../../../domain/config/layout_config.dart';
import '../../../providers/agenda_interaction_lock_provider.dart';
import '../../../providers/agenda_providers.dart';
import '../../../providers/agenda_scroll_provider.dart';
import '../../../providers/appointment_providers.dart';
import '../../../providers/drag_layer_link_provider.dart';
import '../../../providers/is_resizing_provider.dart';
import '../../../providers/layout_config_provider.dart';
import '../helper/responsive_layout.dart';
import 'agenda_staff_body.dart';
import 'components/agenda_staff_header.dart';

class MultiStaffDayView extends ConsumerStatefulWidget {
  final List<Staff> staffList;
  final double initialScrollOffset;
  final ValueChanged<double>? onScrollOffsetChanged;
  final ValueChanged<ScrollController>? onVerticalControllerChanged;

  const MultiStaffDayView({
    super.key,
    required this.staffList,
    required this.initialScrollOffset,
    this.onScrollOffsetChanged,
    this.onVerticalControllerChanged,
  });

  @override
  ConsumerState<MultiStaffDayView> createState() => _MultiStaffDayViewState();
}

class _MultiStaffDayViewState extends ConsumerState<MultiStaffDayView> {
  // Auto scroll durante il drag
  Timer? _autoScrollTimer;
  static const double _scrollEdgeMargin = 100;
  static const double _scrollSpeed = 20;
  static const Duration _scrollInterval = Duration(milliseconds: 50);
  static const double _autoScrollActivationThreshold = 16;

  late final ProviderSubscription<Offset?> _dragSub;
  late final ProviderSubscription<LayoutConfig> _layoutSub;

  final ScrollController _headerHCtrl = ScrollController();
  bool _isSyncing = false;
  Offset? _initialDragPosition;
  bool _autoScrollArmed = false;

  ScrollController? _bodyHorizontalCtrl;
  ScrollController? _verticalCtrl;
  List<int>? _staffSignature;

  late final DragBodyBoxNotifier _dragBodyNotifier;

  Timer? _syncDebounce;

  final GlobalKey _bodyKey = GlobalKey();
  final GlobalKey _headerKey = GlobalKey();

  late final Object _scrollIdentity = Object();
  AgendaScrollKey get _scrollKey => AgendaScrollKey(
    identity: _scrollIdentity,
    staff: widget.staffList,
    date: DateTime.now(),
    initialOffset: widget.initialScrollOffset,
  );

  @override
  void initState() {
    super.initState();
    _dragBodyNotifier = ref.read(dragBodyBoxProvider.notifier);

    // Listener drag → auto scroll verticale
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

    // Listener layoutConfig → solo quando cambiano dimensioni rilevanti
    _layoutSub = ref.listenManual<LayoutConfig>(layoutConfigProvider, (
      prev,
      next,
    ) {
      if (prev == null ||
          prev.headerHeight != next.headerHeight ||
          prev.slotHeight != next.slotHeight ||
          prev.hourColumnWidth != next.hourColumnWidth) {
        _scheduleSyncUpdate();
      }
    });

    // Prima inizializzazione
    _scheduleSyncUpdate();
  }

  void _scheduleSyncUpdate() {
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      _registerBodyBox();
      _setupHorizontalSync(force: true);
    });
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

      // dragPos è in coordinate BODY-LOCAL (DragBodyBox)
      final dragPos = ref.read(dragPositionProvider);
      if (dragPos == null) {
        _stopAutoScroll();
        return;
      }

      final bodyBox = ref.read(dragBodyBoxProvider);
      if (bodyBox == null || !bodyBox.attached) {
        return;
      }

      if (!_autoScrollArmed && _initialDragPosition != null) {
        final deltaX = (dragPos.dx - _initialDragPosition!.dx).abs();
        final deltaY = (dragPos.dy - _initialDragPosition!.dy).abs();
        final maxDelta = deltaX > deltaY ? deltaX : deltaY;
        if (maxDelta < _autoScrollActivationThreshold) return;
        _autoScrollArmed = true;
      }

      final scrollState = ref.read(agendaScrollProvider(_scrollKey));
      final verticalCtrl = scrollState.verticalScrollCtrl;
      final horizontalCtrl = scrollState.horizontalScrollCtrl;
      if (!verticalCtrl.hasClients && !horizontalCtrl.hasClients) return;

      // dragPos è già in coordinate locali del bodyBox
      final localPos = dragPos;
      final viewHeight = bodyBox.size.height;
      final viewWidth = bodyBox.size.width;

      // ─────────────────────────────────────────
      // Auto scroll verticale (comportamento esistente)
      // ─────────────────────────────────────────
      if (verticalCtrl.hasClients) {
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
      }

      // ─────────────────────────────────────────
      // Auto scroll orizzontale per raggiungere colonne nascoste
      // ─────────────────────────────────────────
      if (horizontalCtrl.hasClients) {
        final maxHorizontal = horizontalCtrl.position.maxScrollExtent;
        final currentX = horizontalCtrl.offset;

        // Usiamo una soglia relativa alla larghezza visibile,
        // per renderlo affidabile anche con layout molto larghi.
        const double edgeFraction = 0.18; // ~18% ai lati
        final double leftEdge = viewWidth * edgeFraction;
        final double rightEdge = viewWidth * (1 - edgeFraction);

        double? newOffsetX;
        if (localPos.dx < leftEdge && currentX > 0) {
          newOffsetX = (currentX - _scrollSpeed).clamp(0, maxHorizontal);
        } else if (localPos.dx > rightEdge &&
            currentX < maxHorizontal) {
          newOffsetX = (currentX + _scrollSpeed).clamp(0, maxHorizontal);
        }

        if (newOffsetX != null && newOffsetX != currentX) {
          horizontalCtrl.jumpTo(newOffsetX);
        }
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
    _layoutSub.close();
    _stopAutoScroll();
    _syncDebounce?.cancel();

    _bodyHorizontalCtrl?.removeListener(_onBodyHorizontalScroll);
    _headerHCtrl.removeListener(_onHeaderHorizontalScroll);
    _verticalCtrl?.removeListener(_onVerticalScrollChanged);

    _clearBodyBox();

    _headerHCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MultiStaffDayView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ogni cambio staffList/date → resync orizzontale
    _scheduleSyncUpdate();

    // stesso comportamento di prima per isPrimary
    // quando smette di essere primary: pulisce il body
    _clearBodyBox();
  }

  @override
  Widget build(BuildContext context) {
    final appointments = ref.watch(appointmentsForCurrentLocationProvider);
    final scrollState = ref.watch(agendaScrollProvider(_scrollKey));
    final layoutConfig = ref.watch(layoutConfigProvider);
    // Evaluate the interaction lock once here for the current visible group
    final isInteractionLocked = ref.watch(agendaDayScrollLockProvider);

    final verticalCtrl = scrollState.verticalScrollCtrl;
    if (_verticalCtrl != verticalCtrl) {
      _verticalCtrl?.removeListener(_onVerticalScrollChanged);
      _verticalCtrl = verticalCtrl;
      _verticalCtrl?.addListener(_onVerticalScrollChanged);
      widget.onVerticalControllerChanged?.call(verticalCtrl);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
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
        final LayerLink? link = ref.watch(dragLayerLinkProvider);

        final isResizing = ref.watch(isResizingProvider);

        return Stack(
          children: [
            // BODY scrollabile
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
                isInteractionLocked: isInteractionLocked,
              ),
            ),
            // HEADER staff
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: headerHeight,
              child: KeyedSubtree(
                key: _headerKey,
                child: AgendaStaffHeader(
                  staffList: widget.staffList,
                  hourColumnWidth: hourW,
                  totalHeight: totalHeight,
                  headerHeight: headerHeight,
                  columnWidth: layout.columnWidth,
                  scrollController: _headerHCtrl,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
