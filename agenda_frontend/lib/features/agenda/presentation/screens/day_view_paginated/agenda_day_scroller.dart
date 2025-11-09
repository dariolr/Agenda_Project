import 'package:agenda_frontend/features/agenda/presentation/screens/day_view_paginated/multi_staff_day_for_paging_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/models/staff.dart';
import '../../../domain/config/layout_config.dart';
import '../../../providers/agenda_interaction_lock_provider.dart';
import '../../../providers/agenda_providers.dart';
import '../../../providers/date_range_provider.dart';
import '../../../providers/drag_layer_link_provider.dart';
import '../../../providers/layout_config_provider.dart';

class AgendaDayScrollerController {
  _AgendaDayScrollerState? _state;
  double? _pendingOffset;

  void _attach(_AgendaDayScrollerState state) {
    _state = state;
    if (_pendingOffset != null) {
      state._jumpToExternalOffset(_pendingOffset!);
      _pendingOffset = null;
    }
  }

  void _detach(_AgendaDayScrollerState state) {
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

class AgendaDayScroller extends ConsumerStatefulWidget {
  const AgendaDayScroller({
    super.key,
    required this.staffList,
    this.onVerticalOffsetChanged,
    this.controller,
  });

  final List<Staff> staffList;
  final ValueChanged<double>? onVerticalOffsetChanged;
  final AgendaDayScrollerController? controller;
  static const bool debugShowColoredPages = false;

  @override
  ConsumerState<AgendaDayScroller> createState() => _AgendaDayScrollerState();
}

class _AgendaDayScrollerState extends ConsumerState<AgendaDayScroller> {
  late DateTime _centerDate;
  late List<DateTime> _visibleDates;
  late final PageController _pageController;
  ProviderSubscription<DateTime>? _dateSubscription;
  bool _isUpdatingFromPager = false;
  double _currentScrollOffset = 0.0;
  double _lastScrollOffset = 0.0;
  bool _hasAutoCenteredToday = false;
  ScrollController? _centerVerticalController;
  static const Duration _edgeSwipeDuration = Duration(milliseconds: 200);
  static const Curve _edgeSwipeCurve = Curves.easeOut;
  static const bool _debugTimings = true;
  DateTime? _swipeStartTime;
  bool _isUserDragging = false;
  bool _edgeAnimationInFlight = false;
  bool _centerRebuildScheduled = false;
  AxisDirection? _pendingEdgeDirection;
  bool _edgeArmed = false;
  AxisDirection? _armedEdgeDirection;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _centerDate = DateUtils.dateOnly(ref.read(agendaDateProvider));
    _visibleDates = _buildVisibleDates(_centerDate);
    _pageController = PageController(initialPage: 1);
    final layoutConfig = ref.read(layoutConfigProvider);
    _currentScrollOffset = _timelineOffsetForToday(layoutConfig);
    _lastScrollOffset = _currentScrollOffset;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onVerticalOffsetChanged?.call(_currentScrollOffset);
    });
    _dateSubscription = ref.listenManual<DateTime>(
      agendaDateProvider,
      _onExternalDateChanged,
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _dateSubscription?.close();
    _pageController.dispose();
    widget.controller?._detach(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AgendaDayScroller oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPageScrollLocked = ref.watch(agendaDayScrollLockProvider);

    return SizedBox.expand(
      child: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          final metrics = notification.metrics;
          if (metrics is! PageMetrics || metrics.axis != Axis.horizontal) {
            return false;
          }
          final dragging = notification.direction != ScrollDirection.idle;
          if (dragging && !_isUserDragging) {
            _isUserDragging = true;
            _swipeStartTime = DateTime.now();
            _pendingEdgeDirection = null;
            _log('Swipe start');
          } else if (!dragging && _isUserDragging) {
            _isUserDragging = false;
            _log('Swipe end');
            _consumePendingEdge();
          }
          return false;
        },
        child: PageView.builder(
          controller: _pageController,
          itemCount: _visibleDates.length,
          scrollDirection: Axis.horizontal,
          physics: isPageScrollLocked
              ? const NeverScrollableScrollPhysics()
              : const _FastPageScrollPhysics(),
          padEnds: false,
          onPageChanged: _handlePageChanged,
          itemBuilder: (context, index) {
            final date = _visibleDates[index];
            final isCenter = DateUtils.isSameDay(date, _centerDate);
            final isToday = DateUtils.isSameDay(date, DateTime.now());
            final allowAutoCenter = isToday && !_hasAutoCenteredToday;

            final view = MultiStaffDayViewForPaging(
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
              onHorizontalEdge: _handleHorizontalEdge,
              onVerticalControllerChanged: isCenter
                  ? _handleCenterVerticalController
                  : null,
              isPrimary: isCenter,
            );

            if (allowAutoCenter) {
              _hasAutoCenteredToday = true;
            }

            if (!AgendaDayScroller.debugShowColoredPages) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: view,
              );
            }

            final Color bgColor = switch (index) {
              0 => Colors.red.withOpacity(0.15),
              1 => Colors.green.withOpacity(0.15),
              2 => Colors.blue.withOpacity(0.15),
              _ => Colors.grey.withOpacity(0.15),
            };

            return Container(color: bgColor, child: view);
          },
        ),
      ),
    );
  }

  void _handlePageChanged(int index) {
    _log('onPageChanged index=$index');
    _logSwipeElapsed();
    if (index == 1) return;
    final targetDate = _visibleDates[index];
    _lastScrollOffset = _currentScrollOffset;
    _updateCenter(targetDate, _lastScrollOffset);
    _isUpdatingFromPager = true;
    ref.read(agendaDateProvider.notifier).set(targetDate);
  }

  void _onExternalDateChanged(DateTime? previous, DateTime next) {
    final normalized = DateUtils.dateOnly(next);
    if (_isUpdatingFromPager) {
      _isUpdatingFromPager = false;
      return;
    }
    if (DateUtils.isSameDay(normalized, _centerDate)) {
      return;
    }
    _lastScrollOffset = _currentScrollOffset;
    _updateCenter(normalized, _lastScrollOffset);
  }

  void _updateCenter(DateTime newCenter, double inheritedOffset) {
    _resetDragState();
    setState(() {
      _centerDate = newCenter;
      _visibleDates = _buildVisibleDates(newCenter);
      _currentScrollOffset = inheritedOffset;
      _centerVerticalController = null;
    });
    widget.onVerticalOffsetChanged?.call(_currentScrollOffset);
    _schedulePageRecentering();
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

  void _schedulePageRecentering() {
    if (_centerRebuildScheduled) return;
    _centerRebuildScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerRebuildScheduled = false;
      if (!_pageController.hasClients) return;
      final current =
          _pageController.page ?? _pageController.initialPage.toDouble();
      if ((current - 1).abs() < 0.01) {
        return;
      }
      _log('Center snap');
      _pageController.jumpToPage(1);
    });
  }

  void _handleHorizontalEdge(AxisDirection direction) {
    if (!_consumeEdgeArm(direction)) return;
    if (_isUserDragging) {
      _pendingEdgeDirection = direction;
      return;
    }
    _startEdgeAnimation(direction);
  }

  void _consumePendingEdge() {
    final direction = _pendingEdgeDirection;
    _pendingEdgeDirection = null;
    if (direction == null) {
      _resetEdgeArm();
      return;
    }
    _startEdgeAnimation(direction);
  }

  void _startEdgeAnimation(AxisDirection direction) {
    if (!_pageController.hasClients || _edgeAnimationInFlight) {
      _log(
        'Ignoring edge while dragging=$_isUserDragging inFlight=$_edgeAnimationInFlight',
      );
      return;
    }

    final targetPage = switch (direction) {
      AxisDirection.left => 0,
      AxisDirection.right => 2,
      _ => null,
    };

    if (targetPage == null) {
      return;
    }

    final current =
        _pageController.page ?? _pageController.initialPage.toDouble();
    if ((current - targetPage).abs() < 0.05) {
      return;
    }

    _log('Horizontal edge swipe → page $targetPage');
    _edgeAnimationInFlight = true;
    _pageController
        .animateToPage(
          targetPage,
          duration: _edgeSwipeDuration,
          curve: _edgeSwipeCurve,
        )
        .whenComplete(() {
          _edgeAnimationInFlight = false;
          _log('Edge swipe complete');
        });
  }

  List<DateTime> _buildVisibleDates(DateTime center) {
    final base = DateUtils.dateOnly(center);
    final prev = DateUtils.addDaysToDate(base, -1);
    final next = DateUtils.addDaysToDate(base, 1);
    return [prev, base, next];
  }

  void _resetDragState() {
    _resetEdgeArm();
    ref.read(dragPositionProvider.notifier).clear();
    ref.read(dragBodyBoxProvider.notifier).scheduleClear();
    ref.read(dragLayerLinkProvider.notifier).resetOnMicrotask();
  }

  bool _consumeEdgeArm(AxisDirection direction) {
    if (!_edgeArmed) {
      _edgeArmed = true;
      _armedEdgeDirection = direction;
      return false;
    }
    if (_armedEdgeDirection != direction) {
      _armedEdgeDirection = direction;
      return false;
    }
    _edgeArmed = false;
    _armedEdgeDirection = null;
    return true;
  }

  void _resetEdgeArm() {
    _edgeArmed = false;
    _armedEdgeDirection = null;
  }

  double _timelineOffsetForToday(LayoutConfig layoutConfig) {
    final now = DateTime.now();
    final minutes = now.hour * 60 + now.minute;
    return (minutes / layoutConfig.minutesPerSlot) * layoutConfig.slotHeight;
  }

  void _log(String message) {
    if (!_debugTimings) return;
    debugPrint('[DayScroller] $message @ ${DateTime.now().toIso8601String()}');
  }

  void _logSwipeElapsed() {
    if (!_debugTimings) return;
    final start = _swipeStartTime;
    if (start == null) return;
    final elapsed = DateTime.now().difference(start).inMilliseconds;
    debugPrint('[DayScroller] Page change committed in ${elapsed}ms');
    _swipeStartTime = null;
  }
}

class _FastPageScrollPhysics extends PageScrollPhysics {
  const _FastPageScrollPhysics({super.parent});

  @override
  _FastPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _FastPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring =>
      const SpringDescription(mass: 0.6, stiffness: 500, damping: 1.9);
}
