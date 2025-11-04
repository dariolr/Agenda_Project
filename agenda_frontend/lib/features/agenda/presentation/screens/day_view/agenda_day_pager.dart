import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/models/staff.dart';
import '../../../providers/date_range_provider.dart';
import '../../../providers/layout_config_provider.dart';
import 'multi_staff_day_view.dart';

class AgendaDayPager extends ConsumerStatefulWidget {
  const AgendaDayPager({super.key, required this.staffList});

  final List<Staff> staffList;

  @override
  ConsumerState<AgendaDayPager> createState() => _AgendaDayPagerState();
}

class _AgendaDayPagerState extends ConsumerState<AgendaDayPager> {
  static const int _initialPage = 10000;

  late final DateTime _baseDate;
  late final PageController _pageController;
  bool _isAnimatingFromDateChange = false;
  bool _isUpdatingDateFromPage = false;
  bool _didAttachDateListener = false;
  final Map<int, List<Staff>> _staffListCache = {};
  final Map<int, double> _verticalOffsets = {};
  double _currentScrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    final initialDate = DateUtils.dateOnly(ref.read(agendaDateProvider));
    _baseDate = initialDate;
    _pageController = PageController(initialPage: _initialPage);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_pageController.hasClients) return;
      final targetIndex = _indexForDate(ref.read(agendaDateProvider));
      _pageController.jumpToPage(targetIndex);
      _currentScrollOffset = _verticalOffsets[targetIndex] ?? 0.0;
    });
  }

  @override
  void dispose() {
    _staffListCache.clear();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AgendaDayPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.staffList, widget.staffList)) {
      _staffListCache.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_didAttachDateListener) {
      _didAttachDateListener = true;
      ref.listen<DateTime>(agendaDateProvider, (previous, next) {
        if (_isUpdatingDateFromPage) {
          _isUpdatingDateFromPage = false;
          return;
        }

        if (_isAnimatingFromDateChange) {
          return;
        }
        if (!_pageController.hasClients) {
          return;
        }
        final lastDate = previous ?? next;
        final currentIndex = _indexForDate(lastDate);
        _verticalOffsets[currentIndex] = _currentScrollOffset;
        _currentScrollOffset =
            _verticalOffsets[_indexForDate(next)] ?? _currentScrollOffset;
        final targetIndex = _indexForDate(next);
        final currentPage = _pageController.page;
        if (currentPage != null && (currentPage - targetIndex).abs() < 0.001) {
          return;
        }
        _isAnimatingFromDateChange = true;
        _pageController
            .animateToPage(
              targetIndex,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
            )
            .whenComplete(() {
              _isAnimatingFromDateChange = false;
            });
      });
    }

    final layoutConfig = ref.watch(layoutConfigProvider);

    double _currentTimeOffset() {
      final now = DateTime.now();
      final minutes = now.hour * 60 + now.minute;
      return (minutes / layoutConfig.minutesPerSlot) * layoutConfig.slotHeight;
    }

    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        final newDate = _dateForIndex(index);
        final notifier = ref.read(agendaDateProvider.notifier);
        if (_isAnimatingFromDateChange) {
          _isAnimatingFromDateChange = false;
          return;
        }

        final currentIndex = _indexForDate(ref.read(agendaDateProvider));
        _verticalOffsets[currentIndex] = _currentScrollOffset;

        if (DateUtils.isSameDay(newDate, ref.read(agendaDateProvider))) {
          return;
        }
        _isUpdatingDateFromPage = true;
        notifier.set(newDate);
        _currentScrollOffset =
            _verticalOffsets[index] ?? _currentScrollOffset;
      },
      itemBuilder: (context, index) {
        final staffListForPage = _staffListCache.putIfAbsent(
          index,
          () => List<Staff>.unmodifiable(widget.staffList),
        );
        final pageDate = _dateForIndex(index);
        final today = DateUtils.dateOnly(DateTime.now());
        final isToday = DateUtils.isSameDay(pageDate, today);
        final storedOffset = _verticalOffsets[index];
        double initialOffset;
        if (storedOffset != null) {
          initialOffset = storedOffset;
        } else if (isToday) {
          initialOffset = _currentTimeOffset();
          _verticalOffsets[index] = initialOffset;
          _currentScrollOffset = initialOffset;
        } else {
          initialOffset = _currentScrollOffset;
          _verticalOffsets[index] = initialOffset;
        }
        return MultiStaffDayView(
          key: ValueKey(_dateForIndex(index)),
          staffList: staffListForPage,
          date: pageDate,
          initialScrollOffset: initialOffset,
          onScrollOffsetChanged: (offset) {
            _verticalOffsets[index] = offset;
            _currentScrollOffset = offset;
          },
        );
      },
    );
  }

  int _indexForDate(DateTime date) {
    final normalized = DateUtils.dateOnly(date);
    final days = normalized.difference(_baseDate).inDays;
    return _initialPage + days;
  }

  DateTime _dateForIndex(int index) {
    final offset = index - _initialPage;
    return DateUtils.addDaysToDate(_baseDate, offset);
  }
}
