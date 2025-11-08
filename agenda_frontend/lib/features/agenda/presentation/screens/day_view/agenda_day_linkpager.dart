import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/models/staff.dart';
import '../../../domain/config/layout_config.dart';
import '../../../providers/agenda_providers.dart';
import '../../../providers/date_range_provider.dart';
import '../../../providers/drag_layer_link_provider.dart';
import '../../../providers/layout_config_provider.dart';
import 'multi_staff_day_view.dart';

class AgendaDayLinkPagerController {
  _AgendaDayLinkPagerState? _state;
  double? _pendingOffset;

  void _attach(_AgendaDayLinkPagerState state) {
    _state = state;
    if (_pendingOffset != null) {
      state._jumpToExternalOffset(_pendingOffset!);
      _pendingOffset = null;
    }
  }

  void _detach(_AgendaDayLinkPagerState state) {
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

class AgendaDayLinkPager extends ConsumerStatefulWidget {
  const AgendaDayLinkPager({
    super.key,
    required this.staffList,
    this.onVerticalOffsetChanged,
    this.controller,
  });

  final List<Staff> staffList;
  final ValueChanged<double>? onVerticalOffsetChanged;
  final AgendaDayLinkPagerController? controller;
  static const bool debugShowColoredPages = false;

  @override
  ConsumerState<AgendaDayLinkPager> createState() => _AgendaDayLinkPagerState();
}

class _AgendaDayLinkPagerState extends ConsumerState<AgendaDayLinkPager> {
  late DateTime _centerDate;
  late List<DateTime> _visibleDates;
  late final ScrollController _scrollController;
  ProviderSubscription<DateTime>? _dateSubscription;
  bool _isUpdatingFromPager = false;
  double _currentScrollOffset = 0.0;
  double _lastScrollOffset = 0.0;
  bool _hasAutoCenteredToday = false;
  ScrollController? _centerVerticalController;
  static const bool _debugTimings = true;
  DateTime? _swipeStartTime;
  double _viewportExtent = 0.0;
  bool _isSettling = false;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _centerDate = DateUtils.dateOnly(ref.read(agendaDateProvider));
    _visibleDates = _buildVisibleDates(_centerDate);
    _scrollController = ScrollController();
    final layoutConfig = ref.read(layoutConfigProvider);
    _currentScrollOffset = _timelineOffsetForToday(layoutConfig);
    _lastScrollOffset = _currentScrollOffset;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onVerticalOffsetChanged?.call(_currentScrollOffset);
      _jumpToCenter();
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
    _scrollController.dispose();
    widget.controller?._detach(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AgendaDayLinkPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: CustomScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverFillViewport(
              padEnds: false,
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final date = _visibleDates[index];

                  final isCenter = DateUtils.isSameDay(date, _centerDate);
                  final isToday = DateUtils.isSameDay(date, DateTime.now());
                  final allowAutoCenter = isToday && !_hasAutoCenteredToday;

                  final view = MultiStaffDayView(
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
                  );

                  if (allowAutoCenter) {
                    _hasAutoCenteredToday = true;
                  }

                  if (!AgendaDayLinkPager.debugShowColoredPages) {
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
                childCount: _visibleDates.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.horizontal) {
      return false;
    }
    _viewportExtent = notification.metrics.viewportDimension;
    if (notification is UserScrollNotification) {
      final isDragging = notification.direction != ScrollDirection.idle;
      if (isDragging && _swipeStartTime == null) {
        _swipeStartTime = DateTime.now();
        _logTiming('Swipe start');
      } else if (!isDragging && _swipeStartTime != null) {
        _logTiming('Swipe end');
      }
    }
    if (notification is ScrollEndNotification) {
      _logTiming('Scroll end → settle');
      _settleToNearestPage();
    }
    return false;
  }

  void _handlePageChanged(int index) {
    _logTiming('Handle page changed index=$index');
    _logSwipeElapsed();
    if (index == 1) return;
    final targetDate = _visibleDates[index];
    _lastScrollOffset = _currentScrollOffset;
    _updateCenter(targetDate, _lastScrollOffset);
    _isUpdatingFromPager = true;
    ref.read(agendaDateProvider.notifier).set(targetDate);
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToCenter());
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToCenter());
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

  void _jumpToCenter() {
    if (!_scrollController.hasClients || _viewportExtent <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToCenter());
      return;
    }
    final target = _viewportExtent;
    if ((_scrollController.offset - target).abs() <= 0.5) {
      return;
    }
    _scrollController.jumpTo(target);
  }

  void _handleHorizontalEdge(AxisDirection direction) {
    if (_isSettling || !_scrollController.hasClients) {
      return;
    }

    final int? targetPage = switch (direction) {
      AxisDirection.left => 0,
      AxisDirection.right => 2,
      _ => null,
    };

    if (targetPage == null) {
      return;
    }

    _logTiming('Horizontal edge swipe → page $targetPage');
    _animateToPage(targetPage);
  }

  void _settleToNearestPage() {
    if (_isSettling || !_scrollController.hasClients || _viewportExtent <= 0) {
      return;
    }
    final currentOffset = _scrollController.offset;
    final currentPage = currentOffset / _viewportExtent;
    final target = currentPage.round().clamp(0, _visibleDates.length - 1);
    if ((target - currentPage).abs() < 0.05) {
      _logTiming('Already near page $target');
      return;
    }
    _logTiming('Settle to page $target from $currentPage');
    _animateToPage(target);
  }

  void _animateToPage(int targetPage) {
    if (!_scrollController.hasClients || _viewportExtent <= 0) return;
    final targetPixels = targetPage * _viewportExtent;
    _isSettling = true;
    final duration = targetPage == 1
        ? const Duration(milliseconds: 160)
        : const Duration(milliseconds: 220);
    _scrollController
        .animateTo(
          targetPixels,
          duration: duration,
          curve: Curves.easeOut,
        )
        .whenComplete(() {
          if (!mounted) return;
          _isSettling = false;
          _logTiming('Settle animation complete (page $targetPage)');
          if (targetPage != 1) {
            _handlePageChanged(targetPage);
          }
        });
  }

  List<DateTime> _buildVisibleDates(DateTime center) {
    final base = DateUtils.dateOnly(center);
    final prev = DateUtils.addDaysToDate(base, -1);
    final next = DateUtils.addDaysToDate(base, 1);
    return [prev, base, next];
  }

  void _resetDragState() {
    ref.read(dragPositionProvider.notifier).clear();
    ref.read(dragBodyBoxProvider.notifier).scheduleClear();
    ref.read(dragLayerLinkProvider.notifier).resetOnMicrotask();
  }

  double _timelineOffsetForToday(LayoutConfig layoutConfig) {
    final now = DateTime.now();
    final minutes = now.hour * 60 + now.minute;
    return (minutes / layoutConfig.minutesPerSlot) * layoutConfig.slotHeight;
  }

  void _logTiming(String message) {
    if (!_debugTimings) return;
    debugPrint('[DayLinkPager] $message @ ${DateTime.now().toIso8601String()}');
  }

  void _logSwipeElapsed() {
    if (!_debugTimings) return;
    final start = _swipeStartTime;
    if (start == null) return;
    final elapsed = DateTime.now().difference(start).inMilliseconds;
    debugPrint('[DayLinkPager] Page change committed in ${elapsed}ms');
    _swipeStartTime = null;
  }
}
