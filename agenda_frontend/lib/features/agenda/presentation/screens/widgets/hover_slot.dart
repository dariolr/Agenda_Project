import 'package:flutter/material.dart';

import '../../../domain/config/layout_config.dart';

/// Slot interattivo che reagisce all'hover del mouse.
/// Usa lo stesso margin, borderRadius e spessore del bordo delle AppointmentCard.
class HoverSlot extends StatefulWidget {
  final DateTime slotTime;
  final double height;
  final Duration freeDuration;
  final Color colorPrimary1;

  const HoverSlot({
    super.key,
    required this.slotTime,
    required this.height,
    required this.freeDuration,
    required this.colorPrimary1,
  });

  @override
  State<HoverSlot> createState() => _HoverSlotState();
}

class _HoverSlotState extends State<HoverSlot> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${widget.slotTime.hour.toString().padLeft(2, '0')}:${widget.slotTime.minute.toString().padLeft(2, '0')}';
    final freeStr = widget.freeDuration.inMinutes > 0
        ? '${widget.freeDuration.inMinutes} min'
        : '';

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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: widget.colorPrimary1,
                      ),
                    ),
                    Text(
                      freeStr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: widget.colorPrimary1.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.expand(),
      ),
    );
  }
}
