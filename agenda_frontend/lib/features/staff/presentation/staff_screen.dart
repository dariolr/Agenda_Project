import 'package:flutter/material.dart';

import '../../../core/l10n/l10_extension.dart';

class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        context.l10n.staffScreenPlaceholder,
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}
