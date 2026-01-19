import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/providers/route_slug_provider.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/booking_provider.dart';

class SummaryStep extends ConsumerStatefulWidget {
  const SummaryStep({super.key});

  @override
  ConsumerState<SummaryStep> createState() => _SummaryStepState();
}

class _SummaryStepState extends ConsumerState<SummaryStep> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final bookingState = ref.watch(bookingFlowProvider);
    final request = bookingState.request;
    final totals = ref.watch(bookingTotalsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                l10n.summaryTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.summarySubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Data e ora
                if (request.selectedSlot != null)
                  _SummarySection(
                    title: l10n.summaryDateTime,
                    icon: Icons.calendar_today,
                    child: Text(
                      DateFormat(
                        "EEEE d MMMM yyyy 'alle' HH:mm",
                        'it',
                      ).format(request.selectedSlot!.startTime),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                if (request.selectedSlot != null) const SizedBox(height: 16),

                // Servizi selezionati (con operatore)
                _SummarySection(
                  title: l10n.summaryServices,
                  icon: Icons.list_alt,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (totals.selectedPackages.isNotEmpty)
                        ...totals.selectedPackages.map((package) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        package.name,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        l10n.servicePackageLabel,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.6),
                                        ),
                                      ),
                                      if (totals.selectedItemCount > 1)
                                        Text(
                                          l10n.durationMinutes(
                                            package.effectiveDurationMinutes,
                                          ),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.6),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (totals.selectedItemCount > 1)
                                  Text(
                                    _formatTotalPrice(
                                      context,
                                      package.effectivePrice,
                                    ).replaceFirst('€', '').trim(),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ...request.services.map((service) {
                        final staff = request.staffForService(service.id);
                        final isCovered =
                            totals.coveredServiceIds.contains(service.id);
                        final operatorLabel = request.isAnyOperatorForService(
                                  service.id,
                                )
                            ? l10n.staffAnyOperator
                            : (staff != null
                                ? staff.fullName
                                : l10n.staffAnyOperator);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      service.name,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      operatorLabel,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                    if (totals.selectedItemCount > 1 &&
                                        !isCovered)
                                      Text(
                                        l10n.durationMinutes(
                                          service.durationMinutes,
                                        ),
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.6),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (totals.selectedItemCount > 1 && !isCovered)
                                Text(
                                  service.formattedPrice,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return SizedBox(
                            height: 1,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: -16,
                                  right: -16,
                                  top: 0,
                                  child: Divider(
                                    height: 1,
                                    color: theme.dividerColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.summaryDuration,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                l10n.summaryPrice,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 16,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                l10n.durationMinutes(
                                  totals.totalDurationMinutes,
                                ),
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.euro,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatTotalPrice(context, totals.totalPrice)
                                    .replaceFirst('€', '')
                                    .trim(),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const SizedBox(height: 24),

                // Note
                Text(
                  l10n.summaryNotes,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: l10n.summaryNotesHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    ref.read(bookingFlowProvider.notifier).updateNotes(value);
                  },
                ),
              ],
            ),
          ),
        ),

        // Footer
        _buildFooter(context, ref, bookingState),
      ],
    );
  }

  Widget _buildFooter(
    BuildContext context,
    WidgetRef ref,
    BookingFlowState state,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isAuthenticated =
        ref.watch(authProvider.select((state) => state.isAuthenticated));
    final slug = ref.watch(routeSlugProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Errore
            if (state.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _resolveBookingErrorMessage(context, state),
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Bottone conferma
            ElevatedButton(
              onPressed: state.isLoading
                  ? null
                  : () async {
                      if (!isAuthenticated && slug != null) {
                        context.go('/$slug/login');
                        return;
                      }
                      try {
                        await ref
                            .read(bookingFlowProvider.notifier)
                            .confirmBooking();
                      } on TokenExpiredException {
                        // Sessione scaduta - reindirizza al login
                        // Lo stato della prenotazione è già salvato in localStorage
                        if (context.mounted && slug != null) {
                          context.go('/$slug/login');
                        }
                      }
                    },
              child: state.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.actionConfirm),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTotalPrice(BuildContext context, double totalPrice) {
    final l10n = context.l10n;
    if (totalPrice == 0) return l10n.servicesFree;
    return '€${totalPrice.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _resolveBookingErrorMessage(
    BuildContext context,
    BookingFlowState state,
  ) {
    final l10n = context.l10n;
    switch (state.errorCode) {
      case 'slot_conflict':
        return l10n.bookingErrorSlotConflict;
      case 'invalid_service':
        return l10n.bookingErrorInvalidService;
      case 'invalid_staff':
        return l10n.bookingErrorInvalidStaff;
      case 'invalid_location':
        return l10n.bookingErrorInvalidLocation;
      case 'invalid_client':
        return l10n.bookingErrorInvalidClient;
      case 'invalid_time':
        return l10n.bookingErrorInvalidTime;
      case 'staff_unavailable':
        return l10n.bookingErrorStaffUnavailable;
      case 'outside_working_hours':
        return l10n.bookingErrorOutsideWorkingHours;
      case 'not_found':
        return l10n.bookingErrorNotFound;
      case 'unauthorized':
        return l10n.bookingErrorUnauthorized;
      case 'validation_error':
        return l10n.bookingErrorValidation;
      case 'internal_error':
        return l10n.bookingErrorServer;
    }
    return state.errorMessage ?? l10n.errorGeneric;
  }
}

class _SummarySection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SummarySection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
