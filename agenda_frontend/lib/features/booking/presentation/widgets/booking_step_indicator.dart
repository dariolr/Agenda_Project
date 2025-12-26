import 'package:flutter/material.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../providers/booking_provider.dart';

class BookingStepIndicator extends StatelessWidget {
  final BookingStep currentStep;
  final bool allowStaffSelection;
  final void Function(BookingStep) onStepTap;

  const BookingStepIndicator({
    super.key,
    required this.currentStep,
    required this.allowStaffSelection,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final steps = [
      (BookingStep.services, l10n.bookingStepServices, Icons.list_alt),
      if (allowStaffSelection)
        (BookingStep.staff, l10n.bookingStepStaff, Icons.person),
      (BookingStep.dateTime, l10n.bookingStepDateTime, Icons.calendar_today),
      (
        BookingStep.summary,
        l10n.bookingStepSummary,
        Icons.check_circle_outline,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: steps.asMap().entries.map((entry) {
          final index = entry.key;
          final (step, label, icon) = entry.value;
          final isActive = step == currentStep;
          final isPast = step.index < currentStep.index;
          final isClickable = isPast;

          return Expanded(
            child: GestureDetector(
              onTap: isClickable ? () => onStepTap(step) : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (index > 0)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: isPast || isActive
                                ? theme.colorScheme.primary
                                : theme.dividerColor,
                          ),
                        ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? theme.colorScheme.primary
                              : isPast
                              ? theme.colorScheme.primary.withOpacity(0.2)
                              : theme.dividerColor,
                        ),
                        child: Icon(
                          isPast ? Icons.check : icon,
                          size: 18,
                          color: isActive
                              ? Colors.white
                              : isPast
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      if (index < steps.length - 1)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: isPast
                                ? theme.colorScheme.primary
                                : theme.dividerColor,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isActive || isPast
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
