import 'package:agenda_frontend/core/l10n/date_time_formats.dart';
import 'package:flutter/material.dart';

import '../../../domain/config/layout_config.dart';

/// Slot interattivo che reagisce all'hover del mouse.
/// Usa lo stesso margin, borderRadius e spessore del bordo delle AppointmentCard.
class HoverSlot extends StatefulWidget {
  final DateTime slotTime;
  final double height;
  final Color colorPrimary1;

  const HoverSlot({
    super.key,
    required this.slotTime,
    required this.height,
    required this.colorPrimary1,
  });

  @override
  State<HoverSlot> createState() => _HoverSlotState();
}

class _HoverSlotState extends State<HoverSlot> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final timeStr = DtFmt.hm(
      context,
      widget.slotTime.hour,
      widget.slotTime.minute,
    );

    final radius = BorderRadius.circular(4);
    final margin = EdgeInsets.all(LayoutConfig.columnInnerPadding);
    final borderWidth = LayoutConfig.borderWidth;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        margin: margin,
        height: widget.height - LayoutConfig.columnInnerPadding * 2,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _hovered
              ? widget.colorPrimary1.withOpacity(0.06)
              : Colors.transparent,
          border: Border.all(
            color: _hovered
                ? widget.colorPrimary1.withOpacity(0.1)
                : Colors.transparent,
            width: _hovered ? borderWidth : 0,
          ),
          borderRadius: radius,
        ),
        child: _hovered
            ? Padding(
                padding: const EdgeInsets.all(2),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: widget.colorPrimary1,
                    ),
                  ),
                ),
              )
            : const SizedBox.expand(),
      ),
    );
  }
}

/// Wrapper that builds [HoverSlot] only when the pointer (mouse) or touch is
/// active on the slot. This avoids constructing the (slightly heavier)
/// hover contents for every slot when not needed.
class LazyHoverSlot extends StatefulWidget {
  final DateTime slotTime;
  final double height;
  final Color colorPrimary1;

  const LazyHoverSlot({
    super.key,
    required this.slotTime,
    required this.height,
    required this.colorPrimary1,
  });

  @override
  State<LazyHoverSlot> createState() => _LazyHoverSlotState();
}

class _LazyHoverSlotState extends State<LazyHoverSlot> {
  bool _show = false;

  void _onEnter(PointerEvent _) {
    setState(() => _show = true);
  }

  void _onExit(PointerEvent _) {
    setState(() => _show = false);
  }

  void _onTapDown(TapDownDetails _) {
    // On touch devices show the hover content while pressing.
    setState(() => _show = true);
  }

  void _onTapUp(TapUpDetails _) {
    // Hide shortly after release to mimic hover disappearing.
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _show = false);
    });
  }

  void _onTapCancel() {
    setState(() => _show = false);
  }

  @override
  Widget build(BuildContext context) {
    // We keep the same size and margin as HoverSlot so layout doesn't jump.
    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: _show
              ? HoverSlot(
                  slotTime: widget.slotTime,
                  height: widget.height,
                  colorPrimary1: widget.colorPrimary1,
                )
              : Container(),
        ),
      ),
    );
  }
}
