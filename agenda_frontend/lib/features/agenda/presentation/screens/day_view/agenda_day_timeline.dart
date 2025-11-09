import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/models/staff.dart';
import '../../../domain/config/layout_config.dart';
import '../../../providers/agenda_interaction_lock_provider.dart';
import '../../../providers/date_range_provider.dart';
import '../../../providers/layout_config_provider.dart';
import 'multi_staff_day_view.dart';

/// Controller analogo a [AgendaDayScrollerController] che consente di
/// sincronizzare l'offset verticale con la colonna delle ore.
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
    if (_state == state) {
      _state = null;
    }
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

/// Timeline continua composta da tre giornate (precedente, corrente, successiva)
/// all'interno della stessa scroll view orizzontale.
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
  final ScrollController _timelineController = ScrollController();
  late DateTime _centerDate;
  late List<DateTime> _windowDates;
  ProviderSubscription<DateTime>? _dateSubscription;
  double _viewportWidth = 0;
  double _currentScrollOffset = 0;
  double _lastScrollOffset = 0;
  bool _hasAutoCenteredToday = false;
  bool _suppressTimelineListener = false;
  bool _pendingRecentering = true;
  bool _isUserInteracting = false;
  ScrollController? _centerVerticalController;
  static const double _edgeThresholdFactor = 0.35;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _centerDate = DateUtils.dateOnly(ref.read(agendaDateProvider));
    _windowDates = _buildWindow(_centerDate);

    final layoutConfig = ref.read(layoutConfigProvider);
    _currentScrollOffset = _timelineOffsetForToday(layoutConfig);
    _lastScrollOffset = _currentScrollOffset;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onVerticalOffsetChanged?.call(_currentScrollOffset);
    });

    _timelineController.addListener(_handleTimelineScroll);
    _dateSubscription = ref.listenManual<DateTime>(
      agendaDateProvider,
      _onExternalDateChanged,
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _dateSubscription?.close();
    _timelineController
      ..removeListener(_handleTimelineScroll)
      ..dispose();
    widget.controller?._detach(this);
    super.dispose();
  }

  void _onExternalDateChanged(DateTime? previous, DateTime next) {
    final normalized = DateUtils.dateOnly(next);
    if (DateUtils.isSameDay(normalized, _centerDate)) {
      return;
    }
    _lastScrollOffset = _currentScrollOffset;
    _updateCenter(normalized, _lastScrollOffset, recenterTimeline: true);
  }

  void _handleTimelineScroll() {
    if (_suppressTimelineListener || !_timelineController.hasClients) {
      return;
    }
    _isUserInteracting = true;

    if (_viewportWidth <= 0) {
      return;
    }

    final offset = _timelineController.offset;
    final forwardThreshold = _viewportWidth * (1 + _edgeThresholdFactor);
    final backwardThreshold = _viewportWidth * (1 - _edgeThresholdFactor);

    if (offset >= forwardThreshold) {
      _shiftWindow(1);
    } else if (offset <= backwardThreshold) {
      _shiftWindow(-1);
    }
  }

  void _shiftWindow(int direction) {
    if (_viewportWidth == 0) return;
    final nextCenter = DateUtils.addDaysToDate(_centerDate, direction);
    _lastScrollOffset = _currentScrollOffset;
    _updateCenter(nextCenter, _lastScrollOffset);
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
    if (recenterTimeline || _isUserInteracting) {
      _scheduleRecentering();
    }
  }

  void _scheduleRecentering() {
    if (_viewportWidth == 0) {
      _pendingRecentering = true;
      return;
    }
    _pendingRecentering = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_timelineController.hasClients) return;
      _suppressTimelineListener = true;
      _timelineController.jumpTo(_viewportWidth);
      _suppressTimelineListener = false;
      _isUserInteracting = false;
    });
  }

  void _handleCenterVerticalController(ScrollController controller) {
    if (_centerVerticalController == controller) return;
    _centerVerticalController = controller;
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
    if (notification.metrics.axis != Axis.horizontal) {
      return false;
    }

    if (notification is UserScrollNotification) {
      final isDragging = notification.direction != ScrollDirection.idle;
      if (!isDragging) {
        _scheduleRecentering();
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isScrollLocked = ref.watch(agendaDayScrollLockProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.hasBoundedWidth &&
                constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;

        if ((_viewportWidth - availableWidth).abs() > 0.5) {
          _viewportWidth = availableWidth;
          if (_pendingRecentering) {
            _scheduleRecentering();
          }
        }

        if (_viewportWidth == 0) {
          return const SizedBox.shrink();
        }

        final children = _windowDates.map((date) {
          final isCenter = DateUtils.isSameDay(date, _centerDate);
          final isToday = DateUtils.isSameDay(date, DateTime.now());
          final allowAutoCenter = isToday && !_hasAutoCenteredToday;

          final view = SizedBox(
            width: _viewportWidth,
            child: MultiStaffDayView(
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
              onVerticalControllerChanged:
                  isCenter ? _handleCenterVerticalController : null,
              isPrimary: isCenter,
            ),
          );

          if (allowAutoCenter) {
            _hasAutoCenteredToday = true;
          }

          return view;
        }).toList();

        if (_timelineController.hasClients && !_pendingRecentering) {
          if (_timelineController.offset == 0) {
            _scheduleRecentering();
          }
        }

        return NotificationListener<ScrollNotification>(
          onNotification: _handleHorizontalNotification,
          child: SingleChildScrollView(
            controller: _timelineController,
            scrollDirection: Axis.horizontal,
            physics: isScrollLocked
                ? const NeverScrollableScrollPhysics()
                : const ClampingScrollPhysics(),
            clipBehavior: Clip.hardEdge,
            child: Row(children: children),
          ),
        );
      },
    );
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
