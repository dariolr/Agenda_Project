import 'package:agenda_backend/features/agenda/presentation/screens/day_view/multi_staff_day_view.dart';
import 'package:agenda_backend/features/agenda/providers/date_range_provider.dart';
import 'package:agenda_backend/features/agenda/providers/initial_scroll_provider.dart';
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
    required this.hourColumnWidth,
    required this.currentTimeVerticalOffset,
  });

  final List<Staff> staffList;
  final ValueChanged<double>? onVerticalOffsetChanged;
  final AgendaDayController? controller;
  final double hourColumnWidth;
  final double currentTimeVerticalOffset;

  @override
  ConsumerState<AgendaDay> createState() => _AgendaDayState();
}

class _AgendaDayState extends ConsumerState<AgendaDay> {
  ScrollController? _centerVerticalController;

  DateTime? _previousDate;
  bool _slideFromRight = true;

  /// Data attualmente attiva per filtrare eventi da widget in uscita
  DateTime? _activeDate;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    super.dispose();
  }

  /// Ottiene l'offset corrente (dal provider o calcolato dall'orario attuale)
  double _getCurrentScrollOffset() {
    final savedOffset = ref.read(agendaVerticalOffsetProvider);
    if (savedOffset != null) {
      return savedOffset;
    }
    // Prima apertura: usa l'orario corrente
    final layoutConfig = ref.read(layoutConfigProvider);
    return _timelineOffsetForToday(layoutConfig);
  }

  void _handleCenterVerticalController(ScrollController controller) {
    if (_centerVerticalController == controller) return;
    _centerVerticalController = controller;

    // 🔹 Scroll all'orario corrente SOLO alla prima apertura dell'app
    final initialScrollDone = ref.read(initialScrollDoneProvider);

    if (initialScrollDone) {
      // Non è la prima apertura: sincronizza solo la HourColumn con l'offset corrente
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !controller.hasClients) return;
        // Notifica l'offset corrente per sincronizzare la HourColumn
        widget.onVerticalOffsetChanged?.call(_getCurrentScrollOffset());
      });
      return;
    }

    final layoutConfig = ref.read(layoutConfigProvider);
    final initialOffset = _timelineOffsetForToday(layoutConfig);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !controller.hasClients) return;

      // Marca lo scroll iniziale come completato (dopo il build)
      ref.read(initialScrollDoneProvider.notifier).markDone();

      // Centra la timeline al centro della viewport visibile
      final viewportHeight = controller.position.viewportDimension;
      final target = (initialOffset - viewportHeight / 2)
          .clamp(
            controller.position.minScrollExtent,
            controller.position.maxScrollExtent,
          )
          .toDouble();
      controller.jumpTo(target);
      // Salva nel provider
      ref.read(agendaVerticalOffsetProvider.notifier).set(target);
      widget.onVerticalOffsetChanged?.call(target);
    });
  }

  void _jumpToExternalOffset(double offset) {
    final controller = _centerVerticalController;
    if (controller == null || !controller.hasClients) {
      ref.read(agendaVerticalOffsetProvider.notifier).set(offset);
      return;
    }

    final clamped = offset.clamp(
      controller.position.minScrollExtent,
      controller.position.maxScrollExtent,
    );

    if ((controller.offset - clamped).abs() < 0.5) {
      ref.read(agendaVerticalOffsetProvider.notifier).set(clamped);
      return;
    }

    controller.jumpTo(clamped);
    ref.read(agendaVerticalOffsetProvider.notifier).set(clamped);
    widget.onVerticalOffsetChanged?.call(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final date = ref.watch(agendaDateProvider);
    final currentScrollOffset = _getCurrentScrollOffset();

    // calcola direzione
    if (_previousDate != null && _previousDate != date) {
      _slideFromRight = date.isBefore(_previousDate!);
    }
    _previousDate = date;

    // Aggiorna la data attiva per filtrare callback da widget in uscita
    _activeDate = date;

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
        date: date,
        staffList: widget.staffList,
        currentScrollOffset: currentScrollOffset,
        onVerticalOffsetChanged: (containerDate, offset) {
          // Ignora callback da widget in uscita (durante animazione)
          if (containerDate == _activeDate) {
            _handleScrollOffsetChanged(offset);
          }
        },
        onVerticalControllerChanged: _handleCenterVerticalController,
        hourColumnWidth: widget.hourColumnWidth,
        currentTimeVerticalOffset: widget.currentTimeVerticalOffset,
      ),
    );
  }

  /// Intercetta l'offset scroll per mantenerlo al cambio data
  void _handleScrollOffsetChanged(double offset) {
    ref.read(agendaVerticalOffsetProvider.notifier).set(offset);
    widget.onVerticalOffsetChanged?.call(offset);
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
    required this.date,
    required this.staffList,
    required this.currentScrollOffset,
    this.onVerticalOffsetChanged,
    required this.onVerticalControllerChanged,
    required this.hourColumnWidth,
    required this.currentTimeVerticalOffset,
  });

  final DateTime date;
  final List<Staff> staffList;
  final double currentScrollOffset;
  final void Function(DateTime date, double offset)? onVerticalOffsetChanged;
  final ValueChanged<ScrollController> onVerticalControllerChanged;
  final double hourColumnWidth;
  final double currentTimeVerticalOffset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return MultiStaffDayView(
          staffList: staffList,
          initialScrollOffset: currentScrollOffset,
          onScrollOffsetChanged: (offset) {
            onVerticalOffsetChanged?.call(date, offset);
          },
          onVerticalControllerChanged: onVerticalControllerChanged,
          hourColumnWidth: hourColumnWidth,
          currentTimeVerticalOffset: currentTimeVerticalOffset,
        );
      },
    );
  }
}
