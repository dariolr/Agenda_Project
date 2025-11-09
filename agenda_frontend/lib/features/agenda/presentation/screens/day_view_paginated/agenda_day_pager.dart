import 'package:agenda_frontend/features/agenda/presentation/screens/day_view_paginated/multi_staff_day_for_paging_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/models/staff.dart';
import '../../../domain/config/layout_config.dart';
import '../../../providers/agenda_providers.dart';
import '../../../providers/date_range_provider.dart';
import '../../../providers/drag_layer_link_provider.dart';
import '../../../providers/layout_config_provider.dart';

class AgendaDayPagerController {
  _AgendaDayPagerState? _state;
  double? _pendingOffset;

  void _attach(_AgendaDayPagerState state) {
    _state = state;
    if (_pendingOffset != null) {
      state._jumpToExternalOffset(_pendingOffset!);
      _pendingOffset = null;
    }
  }

  void _detach(_AgendaDayPagerState state) {
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

class AgendaDayPager extends ConsumerStatefulWidget {
  const AgendaDayPager({
    super.key,
    required this.staffList,
    this.onVerticalOffsetChanged,
    this.controller,
  });

  final List<Staff> staffList;
  final ValueChanged<double>? onVerticalOffsetChanged;
  final AgendaDayPagerController? controller;
  static const bool debugShowColoredPages = false;

  @override
  ConsumerState<AgendaDayPager> createState() => _AgendaDayPagerState();
}

class _AgendaDayPagerState extends ConsumerState<AgendaDayPager> {
  late DateTime _centerDate;
  late List<DateTime> _visibleDates;
  late final PageController _pageController;
  ProviderSubscription<DateTime>? _dateSubscription;
  bool _isAnimatingFromPager = false;
  bool _isUpdatingFromPager = false;
  double _currentScrollOffset = 0.0;
  double _lastScrollOffset = 0.0;
  bool _hasAutoCenteredToday = false;
  ScrollController? _centerVerticalController;
  static const Duration _edgeSwipeDuration = Duration(milliseconds: 220);
  static const Curve _edgeSwipeCurve = Curves.easeOut;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(1);
      }
    });
  }

  @override
  void dispose() {
    _dateSubscription?.close();
    _pageController.dispose();
    widget.controller?._detach(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AgendaDayPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: PageView.builder(
        controller: _pageController,
        itemCount: _visibleDates.length,
        physics: const PageScrollPhysics(),
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
            onHorizontalEdge: isCenter ? _handleHorizontalEdge : null,
            onVerticalControllerChanged: isCenter
                ? _handleCenterVerticalController
                : null,
            isPrimary: isCenter,
          );

          if (allowAutoCenter) {
            _hasAutoCenteredToday = true;
          }

          if (!AgendaDayPager.debugShowColoredPages) {
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
    );
  }

  void _handlePageChanged(int index) {
    if (index == 1) return;
    final targetDate = _visibleDates[index];
    _lastScrollOffset = _currentScrollOffset;
    _updateCenter(targetDate, _lastScrollOffset);
    _isUpdatingFromPager = true;
    ref.read(agendaDateProvider.notifier).set(targetDate);
    _jumpToCenter();
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
    _jumpToCenter();
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
    if (!_pageController.hasClients) return;
    _isAnimatingFromPager = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(1);
      }
      _isAnimatingFromPager = false;
    });
  }

  void _handleHorizontalEdge(AxisDirection direction) {
    if (_isAnimatingFromPager || !_pageController.hasClients) {
      return;
    }

    final currentPage =
        _pageController.page ?? _pageController.initialPage.toDouble();
    const double centerPage = 1.0;
    if ((currentPage - centerPage).abs() > 0.05) {
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

    _isAnimatingFromPager = true;
    _pageController
        .animateToPage(
          targetPage,
          duration: _edgeSwipeDuration,
          curve: _edgeSwipeCurve,
        )
        .whenComplete(() {
          if (!mounted) return;
          // in caso l'onPageChanged non sia scattato (es. gesture annullata)
          _isAnimatingFromPager = false;
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
}
