import 'package:agenda_backend/app/widgets/top_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StaffTopControls extends ConsumerWidget {
  const StaffTopControls({
    super.key,
    this.todayLabel,
    this.labelOverride,
    this.compact = false,
  });

  final String? todayLabel;
  final String? labelOverride;
  final bool compact;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TopControls.staff(
      todayLabel: todayLabel,
      labelOverride: labelOverride,
      compact: compact,
    );
  }
}
