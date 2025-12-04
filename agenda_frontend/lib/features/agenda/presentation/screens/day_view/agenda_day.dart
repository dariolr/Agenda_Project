import 'package:agenda_frontend/features/agenda/presentation/screens/day_view/multi_staff_day_view.dart';
import 'package:agenda_frontend/features/agenda/providers/date_range_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/models/staff.dart';
import '../../../domain/config/layout_config.dart';
import '../../../providers/layout_config_provider.dart';

class AgendaDayController {
  _AgendaDayState? _state;
  double? _pendingOffset;

  void _attach(_AgendaDayState state) {
    _state = state;
    if (_pendingOffset != null) {
      state._jumpToExternalOffset(_pendingOffset!);
      _pendingOffset = null;
    }
  }

  void _detach(_AgendaDayState state) {
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

class AgendaDay extends ConsumerStatefulWidget {
  const AgendaDay({
    super.key,
    required this.staffList,
    this.onVerticalOffsetChanged,
    this.controller,
  });

  final List<Staff> staffList;
  final ValueChanged<double>? onVerticalOffsetChanged;
  final AgendaDayController? controller;

  @override
  ConsumerState<AgendaDay> createState() => _AgendaDayState();
}

class _AgendaDayState extends ConsumerState<AgendaDay> {
  ScrollController? _centerVerticalController;
  double _currentScrollOffset = 0;

  DateTime? _previousDate;
  bool _slideFromRight = true;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);

    final layoutConfig = ref.read(layoutConfigProvider);
    _currentScrollOffset = _timelineOffsetForToday(layoutConfig);
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    super.dispose();
  }

  void _handleCenterVerticalController(ScrollController controller) {
    if (_centerVerticalController == controller) return;
    _centerVerticalController = controller;

    final layoutConfig = ref.read(layoutConfigProvider);
    final initialOffset = _timelineOffsetForToday(layoutConfig);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !controller.hasClients) return;

      // Centra la timeline al centro della viewport visibile
      final viewportHeight = controller.position.viewportDimension;
      final target = (initialOffset - viewportHeight / 2)
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

  @override
  Widget build(BuildContext context) {
    final date = ref.watch(agendaDateProvider);

    // calcola direzione
    if (_previousDate != null && _previousDate != date) {
      _slideFromRight = date.isAfter(_previousDate!);
    }
    _previousDate = date;

    // 👇 AnimatedSwitcher forza animazione visibile anche se Flutter riusa il widget
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 250),
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        final offsetTween = Tween<Offset>(
          begin: _slideFromRight
              ? const Offset(1.0, 0.0)
              : const Offset(-1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));

        // 👇 Fade + Slide combinati per rendere visibile la transizione
        return SlideTransition(
          position: animation.drive(offsetTween),
          child: FadeTransition(
            opacity: animation.drive(CurveTween(curve: Curves.easeInOut)),
            child: child,
          ),
        );
      },
      // 👇 chiave unica e realmente diversa a ogni data
      child: _AnimatedDayContainer(
        key: ValueKey('day-${date.toIso8601String()}'),
        staffList: widget.staffList,
        currentScrollOffset: _currentScrollOffset,
        onVerticalOffsetChanged: widget.onVerticalOffsetChanged,
        onVerticalControllerChanged: _handleCenterVerticalController,
      ),
    );
  }

  double _timelineOffsetForToday(LayoutConfig layoutConfig) {
    final now = DateTime.now();
    final minutes = now.hour * 60 + now.minute;
    return (minutes / layoutConfig.minutesPerSlot) * layoutConfig.slotHeight;
  }
}

class _AnimatedDayContainer extends StatelessWidget {
  const _AnimatedDayContainer({
    super.key,
    required this.staffList,
    required this.currentScrollOffset,
    this.onVerticalOffsetChanged,
    required this.onVerticalControllerChanged,
  });

  final List<Staff> staffList;
  final double currentScrollOffset;
  final ValueChanged<double>? onVerticalOffsetChanged;
  final ValueChanged<ScrollController> onVerticalControllerChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return MultiStaffDayView(
          staffList: staffList,
          initialScrollOffset: currentScrollOffset,
          onScrollOffsetChanged: (offset) {
            onVerticalOffsetChanged?.call(offset);
          },
          onVerticalControllerChanged: onVerticalControllerChanged,
        );
      },
    );
  }
}
