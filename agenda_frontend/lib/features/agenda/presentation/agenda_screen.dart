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

    return SafeArea(
      // Passa la lista dello staff alla view
      child: AgendaDayPager(staffList: staffList),
    );
  }
}
