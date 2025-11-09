import 'package:agenda_frontend/features/agenda/presentation/screens/day_view/multi_staff_day_view.dart';
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return MultiStaffDayView(
          staffList: widget.staffList,
          initialScrollOffset: _currentScrollOffset,
          onScrollOffsetChanged: (offset) {
            _currentScrollOffset = offset;
            widget.onVerticalOffsetChanged?.call(offset);
          },
          onVerticalControllerChanged: _handleCenterVerticalController,
        );
      },
    );
  }

  double _timelineOffsetForToday(LayoutConfig layoutConfig) {
    final now = DateTime.now();
    final minutes = now.hour * 60 + now.minute;
    return (minutes / layoutConfig.minutesPerSlot) * layoutConfig.slotHeight;
  }
}
