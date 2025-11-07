import 'package:agenda_frontend/core/widgets/no_scrollbar_behavior.dart';
import 'package:agenda_frontend/features/agenda/presentation/screens/day_view/hour_column.dart';
import 'package:agenda_frontend/features/agenda/presentation/screens/widgets/agenda_dividers.dart';
import 'package:agenda_frontend/features/agenda/presentation/screens/widgets/current_time_line.dart';
import 'package:agenda_frontend/features/agenda/providers/is_resizing_provider.dart';
import 'package:agenda_frontend/features/agenda/providers/layout_config_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/staff_providers.dart';
import 'screens/day_view/agenda_day_pager.dart';

class AgendaScreen extends ConsumerWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Recupera la lista dello staff filtrata sulla location corrente
    final staffList = ref.watch(staffForCurrentLocationProvider);
    final isResizing = ref.watch(isResizingProvider);
    final layoutConfig = ref.watch(layoutConfigProvider);

    final hourColumnWidth = layoutConfig.hourColumnWidth;
    final totalHeight = layoutConfig.totalHeight;
    return SafeArea(
      // Passa la lista dello staff alla view
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          offset: const Offset(3, 0),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: hourColumnWidth,
                      height: layoutConfig.headerHeight,
                    ),
                  ),

                  Expanded(
                    child: ScrollConfiguration(
                      // mantiene l'assenza di scrollbar come prima
                      behavior: const NoScrollbarBehavior(),
                      child: SingleChildScrollView(
                        // controller: verticalController,
                        physics: isResizing
                            ? const NeverScrollableScrollPhysics()
                            : null,
                        child: SizedBox(
                          width: hourColumnWidth,
                          child: const HourColumn(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              AgendaVerticalDivider(height: totalHeight, thickness: 1),
              Expanded(child: AgendaDayPager(staffList: staffList)),
            ],
          ),
          CurrentTimeLine(hourColumnWidth: hourColumnWidth),
        ],
      ),
    );
  }
}
