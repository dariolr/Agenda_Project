import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../providers/booking_provider.dart';
import '../widgets/booking_step_indicator.dart';
import 'confirmation_step.dart';
import 'date_time_step.dart';
import 'services_step.dart';
import 'staff_step.dart';
import 'summary_step.dart';

class BookingScreen extends ConsumerWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingState = ref.watch(bookingFlowProvider);
    final config = ref.watch(bookingConfigProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bookingTitle),
        leading: bookingState.canGoBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    ref.read(bookingFlowProvider.notifier).previousStep(),
              )
            : null,
      ),
      body: Column(
        children: [
          // Step indicator
          if (bookingState.currentStep != BookingStep.confirmation)
            BookingStepIndicator(
              currentStep: bookingState.currentStep,
              allowStaffSelection: config.allowStaffSelection,
              onStepTap: (step) {
                ref.read(bookingFlowProvider.notifier).goToStep(step);
              },
            ),

          // Content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildStepContent(bookingState.currentStep),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(BookingStep step) {
    switch (step) {
      case BookingStep.services:
        return const ServicesStep();
      case BookingStep.staff:
        return const StaffStep();
      case BookingStep.dateTime:
        return const DateTimeStep();
      case BookingStep.summary:
        return const SummaryStep();
      case BookingStep.confirmation:
        return const ConfirmationStep();
    }
  }
}
