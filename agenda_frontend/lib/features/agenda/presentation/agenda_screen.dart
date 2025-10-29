import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/staff_providers.dart';
import 'screens/day_view/multi_staff_day_view.dart';

class AgendaScreen extends ConsumerWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Recupera la lista dello staff dal provider
    final staffList = ref.watch(staffProvider);

    return SafeArea(
      // Passa la lista dello staff alla view
      child: MultiStaffDayView(staffList: staffList),
    );
  }
}
