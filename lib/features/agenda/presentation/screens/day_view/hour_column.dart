import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/config/agenda_theme.dart';
import '../../../domain/config/layout_config.dart';
import '../../../providers/layout_config_provider.dart';
import '../widgets/agenda_dividers.dart';

class HourColumn extends ConsumerWidget {
  const HourColumn({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotHeight = ref.watch(layoutConfigProvider);
    final totalSlots = LayoutConfig.totalSlots;
    final slotsPerHour = (60 ~/ LayoutConfig.minutesPerSlot);

    return Column(
      children: List.generate(totalSlots, (index) {
        final isHourStart = index % slotsPerHour == 0;
        final hour = (index ~/ slotsPerHour);
        final minutes = (index % slotsPerHour) * LayoutConfig.minutesPerSlot;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          height: slotHeight,
          child: Stack(
            children: [
              if (isHourStart)
                Positioned(
                  left: 8,
                  top: 0,
                  child: Text(
                    "${hour.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}",
                    style: AgendaTheme.hourTextStyle,
                  ),
                ),
              Align(
                alignment: Alignment.bottomLeft,
                child: AgendaHorizontalDivider(
                  color: Colors.grey.withOpacity(isHourStart ? 0.2 : 0.5),
                  thickness: isHourStart ? 0.5 : 1,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
