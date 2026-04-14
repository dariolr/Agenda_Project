import 'package:flutter/material.dart';

import '../dialogs/recurrence_summary_dialog.dart';

Future<List<int>?> showRecurrenceExclusionDialog({
  required BuildContext context,
  required RecurringPreviewResult preview,
  String? titleText,
  String? hintText,
  String Function(int count)? confirmLabelBuilder,
  bool excludeConflictsByDefault = true,
}) {
  return RecurrencePreviewDialog.show(
    context,
    preview,
    titleText: titleText,
    hintText: hintText,
    confirmLabelBuilder: confirmLabelBuilder,
    excludeConflictsByDefault: excludeConflictsByDefault,
  );
}
