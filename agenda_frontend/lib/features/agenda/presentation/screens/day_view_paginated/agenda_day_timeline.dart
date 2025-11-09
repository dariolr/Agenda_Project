import 'package:agenda_frontend/features/agenda/presentation/screens/day_view_paginated/multi_staff_day_for_paging_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/models/staff.dart';
import '../../../domain/config/layout_config.dart';
import '../../../providers/agenda_interaction_lock_provider.dart';
import '../../../providers/date_range_provider.dart';
import '../../../providers/layout_config_provider.dart';

class AgendaDayTimelineController {
  _AgendaDayTimelineState? _state;
  double? _pendingOffset;

  void _attach(_AgendaDayTimelineState state) {
    _state = state;
    if (_pendingOffset != null) {
      state._jumpToExternalOffset(_pendingOffset!);
      _pendingOffset = null;
    }
  }

  void _detach(_AgendaDayTimelineState state) {
    if (_state == state) _state = null;
  }

  void jumpTo(double offset) {
    final state = _state;
    if (state == null) {
      _pendingOffset = offset;
      return;
    }
    state._jumpToExternalOffset(offset);
  }

  void dispose() {
    _state = null;
    _pendingOffset = null;
  }
}

class AgendaDayTimeline extends ConsumerStatefulWidget {
  const AgendaDayTimeline({
    super.key,
    required this.staffList,
    this.onVerticalOffsetChanged,
    this.controller,
  });

  final List<Staff> staffList;
  final ValueChanged<double>? onVerticalOffsetChanged;
  final AgendaDayTimelineController? controller;

  @override
  ConsumerState<AgendaDayTimeline> createState() => _AgendaDayTimelineState();
}

class _AgendaDayTimelineState extends ConsumerState<AgendaDayTimeline> {
  ScrollController? _timelineController;
  ScrollController? _centerVerticalController;

  late DateTime _centerDate;
  late List<DateTime> _windowDates;
  ProviderSubscription<DateTime>? _dateSubscription;

  double _viewportWidth = 0;
  double _currentScrollOffset = 0;
  double _lastScrollOffset = 0;

  bool _pendingRecentering = true;
  bool _isTransitioning = false;
  AxisDirection? _horizontalEdge;

  static const double _edgeThresholdFactor = 0.35;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _timelineController = ScrollController();

    _centerDate = DateUtils.dateOnly(ref.read(agendaDateProvider));
    _windowDates = _buildWindow(_centerDate);

    final layoutConfig = ref.read(layoutConfigProvider);
    _currentScrollOffset = _timelineOffsetForToday(layoutConfig);
    _lastScrollOffset = _currentScrollOffset;

    _dateSubscription = ref.listenManual<DateTime>(
      agendaDateProvider,
      _onExternalDateChanged,
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _dateSubscription?.close();
    _timelineController?.dispose();
    widget.controller?._detach(this);
    super.dispose();
  }

  void _onExternalDateChanged(DateTime? previous, DateTime next) {
    final normalized = DateUtils.dateOnly(next);
    if (DateUtils.isSameDay(normalized, _centerDate)) return;

    _lastScrollOffset = _currentScrollOffset;
    _updateCenter(normalized, _lastScrollOffset, recenterTimeline: true);
  }

  Future<void> _handleHorizontalEdge(AxisDirection direction) async {
    final controller = _timelineController;
    if (_isTransitioning ||
        controller == null ||
        !controller.hasClients ||
        _viewportWidth == 0) {
      return;
    }

    _isTransitioning = true;
    _horizontalEdge = direction;

    double target = _viewportWidth;
    int shift = 0;

    if (direction == AxisDirection.right) {
      target = _viewportWidth * 2;
      shift = 1;
    } else if (direction == AxisDirection.left) {
      target = 0;
      shift = -1;
    } else {
      _isTransitioning = false;
      return;
    }

    try {
      await controller.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } catch (_) {
      // ignora animazioni interrotte
    }

    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: 16));
    _shiftWindow(shift);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animateToCenter();
    });

    _isTransitioning = false;
  }

  void _handleDragEnd() {
    final controller = _timelineController;
    if (_isTransitioning ||
        controller == null ||
        !controller.hasClients ||
        _viewportWidth <= 0)
      return;

    final offset = controller.offset;
    final delta = offset - _viewportWidth;
    final fraction = delta / _viewportWidth;

    final atEdge =
        _horizontalEdge == AxisDirection.left ||
        _horizontalEdge == AxisDirection.right;

    if (!atEdge) {
      _animateToCenter();
      return;
    }

    if (fraction >= _edgeThresholdFactor) {
      _shiftWindow(1);
    } else if (fraction <= -_edgeThresholdFactor) {
      _shiftWindow(-1);
    } else {
      _animateToCenter();
    }
  }

  void _shiftWindow(int direction) {
    if (!mounted || _viewportWidth == 0) return;

    final nextCenter = DateUtils.addDaysToDate(_centerDate, direction);
    debugPrint('🔄 Cambio giorno da $_centerDate → $nextCenter');
    _lastScrollOffset = _currentScrollOffset;

    // ricrea controller per evitare doppi attach
    _timelineController?.dispose();
    _timelineController = ScrollController();

    _updateCenter(nextCenter, _lastScrollOffset, recenterTimeline: true);
    ref.read(agendaDateProvider.notifier).set(nextCenter);
  }

  void _updateCenter(
    DateTime newCenter,
    double inheritedOffset, {
    bool recenterTimeline = false,
  }) {
    setState(() {
      _centerDate = newCenter;
      _windowDates = _buildWindow(newCenter);
      _currentScrollOffset = inheritedOffset;
      _centerVerticalController = null;
    });

    widget.onVerticalOffsetChanged?.call(_currentScrollOffset);

    if (recenterTimeline) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final controller = _timelineController;
        if (mounted && controller != null && controller.hasClients) {
          controller.jumpTo(_viewportWidth);
        }
      });
    }
  }

  void _animateToCenter() {
    final controller = _timelineController;
    if (controller == null || !controller.hasClients || _viewportWidth == 0)
      return;

    try {
      controller.animateTo(
        _viewportWidth,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {
      // ignora se smontato
    }
  }

  void _handleCenterVerticalController(ScrollController controller) {
    if (_centerVerticalController == controller) return;
    _centerVerticalController = controller;

    final layoutConfig = ref.read(layoutConfigProvider);
    final initialOffset = _timelineOffsetForToday(layoutConfig);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !controller.hasClients) return;
      final target = (initialOffset - 200)
          .clamp(
            controller.position.minScrollExtent,
            controller.position.maxScrollExtent,
          )
          .toDouble();
      controller.jumpTo(target);
      _currentScrollOffset = target;
      widget.onVerticalOffsetChanged?.call(target);
    });
  }

  void _jumpToExternalOffset(double offset) {
    final controller = _centerVerticalController;
    if (controller == null || !controller.hasClients) {
      _currentScrollOffset = offset;
      return;
    }

    final clamped = offset.clamp(
      controller.position.minScrollExtent,
      controller.position.maxScrollExtent,
    );

    if ((controller.offset - clamped).abs() < 0.5) {
      _currentScrollOffset = clamped;
      return;
    }

    controller.jumpTo(clamped);
    _currentScrollOffset = clamped;
    widget.onVerticalOffsetChanged?.call(clamped);
  }

  bool _handleHorizontalNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.horizontal) return false;

    if (notification is UserScrollNotification) {
      final isDragging = notification.direction != ScrollDirection.idle;
      if (!isDragging) _handleDragEnd();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isScrollLocked = ref.watch(agendaDayScrollLockProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.hasBoundedWidth && constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;

        if ((_viewportWidth - availableWidth).abs() > 0.5) {
          _viewportWidth = availableWidth;
          if (_pendingRecentering) _scheduleRecentering();
        }

        if (_viewportWidth == 0) return const SizedBox.shrink();

        final children = _windowDates.map((date) {
          final isCenter = DateUtils.isSameDay(date, _centerDate);

          return SizedBox(
            width: _viewportWidth,
            child: RepaintBoundary(
              child: MultiStaffDayViewForPaging(
                key: ValueKey(date),
                staffList: widget.staffList,
                date: date,
                initialScrollOffset: _currentScrollOffset,
                onScrollOffsetChanged: (offset) {
                  if (isCenter) {
                    _currentScrollOffset = offset;
                    widget.onVerticalOffsetChanged?.call(offset);
                  }
                },
                onHorizontalEdge: isCenter ? _handleHorizontalEdge : null,
                onVerticalControllerChanged: isCenter
                    ? _handleCenterVerticalController
                    : null,
                isPrimary: isCenter,
              ),
            ),
          );
        }).toList();

        return NotificationListener<ScrollNotification>(
          onNotification: _handleHorizontalNotification,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: Builder(
              key: ValueKey(_centerDate),
              builder: (context) => SingleChildScrollView(
                controller: _timelineController,
                scrollDirection: Axis.horizontal,
                physics: isScrollLocked
                    ? const NeverScrollableScrollPhysics()
                    : const ClampingScrollPhysics(),
                clipBehavior: Clip.hardEdge,
                child: Row(children: children),
              ),
            ),
          ),
        );
      },
    );
  }

  void _scheduleRecentering() {
    if (_viewportWidth == 0) {
      _pendingRecentering = true;
      return;
    }
    _pendingRecentering = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = _timelineController;
      if (mounted && controller != null && controller.hasClients) {
        _animateToCenter();
      }
    });
  }

  List<DateTime> _buildWindow(DateTime center) {
    final base = DateUtils.dateOnly(center);
    final prev = DateUtils.addDaysToDate(base, -1);
    final next = DateUtils.addDaysToDate(base, 1);
    return [prev, base, next];
  }

  double _timelineOffsetForToday(LayoutConfig layoutConfig) {
    final now = DateTime.now();
    final minutes = now.hour * 60 + now.minute;
    return (minutes / layoutConfig.minutesPerSlot) * layoutConfig.slotHeight;
  }
}
