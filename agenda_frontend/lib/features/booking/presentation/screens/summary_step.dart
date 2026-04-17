import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/class_event.dart';

import '../../../../app/providers/route_slug_provider.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/booking_nomenclature_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/locations_provider.dart';
import '../widgets/wrong_business_auth_banner.dart';

class SummaryStep extends ConsumerStatefulWidget {
  const SummaryStep({super.key});

  @override
  ConsumerState<SummaryStep> createState() => _SummaryStepState();
}

class _SummaryStepState extends ConsumerState<SummaryStep> {
  static const int _neverCancellationHours = 100000;
  final _notesController = TextEditingController();
  final _scrollController = ScrollController();
  bool _cancellationPolicyAccepted = false;
  bool _showCancellationPolicyWarning = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(
        max,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final bookingState = ref.watch(bookingFlowProvider);
    final customStaffLabel = ref.watch(bookingStaffDisplayLabelProvider);
    final customServiceLabel = ref.watch(bookingServiceDisplayLabelProvider);
    final phraseOverrides = ref.watch(
      bookingTextOverridesForLocaleProvider(Localizations.localeOf(context)),
    );
    final request = bookingState.request;
    final totals = ref.watch(bookingTotalsProvider);
    final selectedServiceById = {
      for (final service in request.services) service.id: service,
    };
    final location = ref.watch(effectiveLocationProvider);
    final business = ref.watch(currentBusinessProvider).value;
    final cancellationHours =
        location?.cancellationHours ?? business?.cancellationHours ?? 24;

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
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner se autenticato per business diverso
                const WrongBusinessAuthBanner(),

                // === BRANCH CLASSE ===
                if (request.isClassEventBooking) ...[
                  _buildClassEventSummary(
                    context,
                    theme,
                    request.selectedClassEvent!,
                  ),
                  const SizedBox(height: 16),
                ],

                // === BRANCH SERVIZIO NORMALE ===
                // Data e ora
                if (!request.isClassEventBooking && request.selectedSlot != null)
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
                if (!request.isClassEventBooking && request.selectedSlot != null)
                  const SizedBox(height: 16),

                // Servizi selezionati (con operatore)
                if (request.isClassEventBooking) const SizedBox.shrink()
                else
                _SummarySection(
                  title: bookingSummaryServicesLabel(
                    context,
                    customServiceLabel,
                    phraseOverrides: phraseOverrides,
                  ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        package.name,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      if (totals.selectedItemCount > 1)
                                        Text(
                                          context.localizedDurationLabel(
                                            package.customerVisibleDurationMinutes(
                                              selectedServiceById,
                                            ),
                                          ),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
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
                      ...request.services
                          .where(
                            (service) =>
                                request.isServiceManuallySelected(service.id),
                          )
                          .map((service) {
                            final staff = request.staffForService(service.id);
                            final isCovered = totals.coveredServiceIds.contains(
                              service.id,
                            );
                            final operatorLabel =
                                request.isAnyOperatorForService(service.id)
                                ? bookingAnyStaffLabel(
                                    context,
                                    customStaffLabel,
                                    phraseOverrides: phraseOverrides,
                                  )
                                : (staff != null
                                      ? staff.fullName
                                      : bookingAnyStaffLabel(
                                          context,
                                          customStaffLabel,
                                          phraseOverrides: phraseOverrides,
                                        ));
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.6),
                                              ),
                                        ),
                                        if (totals.selectedItemCount > 1 &&
                                            !isCovered)
                                          Text(
                                            context.localizedDurationLabel(
                                              service
                                                  .customerVisibleDurationMinutes,
                                            ),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.6),
                                                ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (totals.selectedItemCount > 1 &&
                                      !isCovered)
                                    Text(
                                      service.formattedPrice,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
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
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.7,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                context.localizedDurationLabel(
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
                                _formatTotalPrice(
                                  context,
                                  totals.totalPrice,
                                ).replaceFirst('€', '').trim(),
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
                const SizedBox(height: 16),

                // Policy modifica/cancellazione (ultima informazione)
                _SummarySection(
                  title: l10n.summaryCancellationPolicyTitle,
                  icon: Icons.policy_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatCancellationPolicy(context, cancellationHours),
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: Theme(
                              data: theme.copyWith(
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: const VisualDensity(
                                  horizontal: -4,
                                  vertical: -4,
                                ),
                              ),
                              child: Checkbox(
                                value: _cancellationPolicyAccepted,
                                onChanged: (value) {
                                  setState(() {
                                    _cancellationPolicyAccepted =
                                        value ?? false;
                                    if (_cancellationPolicyAccepted) {
                                      _showCancellationPolicyWarning = false;
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() {
                                  _cancellationPolicyAccepted =
                                      !_cancellationPolicyAccepted;
                                  if (_cancellationPolicyAccepted) {
                                    _showCancellationPolicyWarning = false;
                                  }
                                });
                              },
                              child: Text(
                                l10n.summaryCancellationPolicyAcceptLabel,
                                textAlign: TextAlign.left,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_showCancellationPolicyWarning) ...[
                        const SizedBox(height: 8),
                        Text(
                          l10n.summaryCancellationPolicyAcceptRequiredError,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
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

  Widget _buildClassEventSummary(
    BuildContext context,
    ThemeData theme,
    ClassEvent event,
  ) {
    final startTime = DateTime.tryParse(event.displayStartsAt);
    final endTime = DateTime.tryParse(event.displayEndsAt);
    final dateLabel = startTime != null
        ? DateFormat('EEEE d MMMM yyyy', 'it').format(startTime)
        : event.displayStartsAt;
    final timeLabel = (startTime != null && endTime != null)
        ? '${DateFormat('HH:mm').format(startTime)} – ${DateFormat('HH:mm').format(endTime)}'
        : '';

    Color? dotColor;
    if (event.classTypeColorHex != null) {
      final hex = event.classTypeColorHex!.replaceFirst('#', '');
      if (hex.length == 6) {
        dotColor = Color(int.parse('FF$hex', radix: 16));
      }
    }

    return _SummarySection(
      title: context.l10n.classEventGroupLesson,
      icon: Icons.fitness_center_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (dotColor != null) ...[
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  event.classTypeName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                event.formattedPrice,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(width: 6),
              Text(
                dateLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          if (timeLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  timeLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.people_outline,
                size: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(width: 6),
              Text(
                event.isFull
                    ? context.l10n.classEventFull
                    : context.l10n.classEventSpotsAvailable(event.spotsLeft),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: event.isFull
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          if (event.isFull && event.waitlistEnabled) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.l10n.classEventWaitlistNotice,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    WidgetRef ref,
    BookingFlowState state,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final customStaffLabel = ref.watch(bookingStaffDisplayLabelProvider);
    final customServiceLabel = ref.watch(bookingServiceDisplayLabelProvider);
    final customLocationLabel = ref.watch(bookingLocationDisplayLabelProvider);
    final phraseOverrides = ref.watch(
      bookingTextOverridesForLocaleProvider(Localizations.localeOf(context)),
    );
    final isAuthenticated = ref.watch(
      authProvider.select((state) => state.isAuthenticated),
    );
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
                        _resolveBookingErrorMessage(
                          context,
                          state,
                          customStaffLabel: customStaffLabel,
                          customServiceLabel: customServiceLabel,
                          customLocationLabel: customLocationLabel,
                          phraseOverrides: phraseOverrides,
                        ),
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
                      if (!_cancellationPolicyAccepted) {
                        setState(() {
                          _showCancellationPolicyWarning = true;
                        });
                        _scrollToBottom();
                        return;
                      }
                      if (_showCancellationPolicyWarning) {
                        setState(() {
                          _showCancellationPolicyWarning = false;
                        });
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
    BookingFlowState state, {
    required String? customStaffLabel,
    required String? customServiceLabel,
    required String? customLocationLabel,
    required Map<String, String>? phraseOverrides,
  }) {
    final l10n = context.l10n;
    final normalizedMessage = (state.errorMessage ?? '').toLowerCase();
    final isBlockedCustomer =
        state.errorCode == 'account_disabled' ||
        (state.errorCode == 'unauthorized' &&
            (normalizedMessage.contains('account is disabled') ||
                normalizedMessage.contains('account disabled') ||
                normalizedMessage.contains('blocked')));

    if (isBlockedCustomer) {
      return l10n.blockedCustomerContactMessage;
    }

    switch (state.errorCode) {
      case 'slot_conflict':
        return l10n.bookingErrorSlotConflict;
      case 'invalid_service':
        return bookingErrorInvalidServiceMessage(
          context,
          customServiceLabel,
          phraseOverrides: phraseOverrides,
        );
      case 'invalid_staff':
        return bookingErrorInvalidStaffMessage(
          context,
          customStaffLabel,
          customServiceLabel,
          phraseOverrides: phraseOverrides,
        );
      case 'invalid_location':
        return bookingErrorInvalidLocationMessage(
          context,
          customLocationLabel,
          phraseOverrides: phraseOverrides,
        );
      case 'invalid_client':
        return l10n.bookingErrorInvalidClient;
      case 'invalid_time':
        return l10n.bookingErrorInvalidTime;
      case 'staff_unavailable':
        return bookingErrorStaffUnavailableMessage(
          context,
          customStaffLabel,
          phraseOverrides: phraseOverrides,
        );
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

  String _formatCancellationPolicy(BuildContext context, int hours) {
    final l10n = context.l10n;
    if (hours == _neverCancellationHours) {
      return l10n.summaryCancellationPolicyNever;
    }
    if (hours == 0) {
      return l10n.summaryCancellationPolicyAlways;
    }
    if (hours >= 24 && hours % 24 == 0) {
      return l10n.summaryCancellationPolicyDays(hours ~/ 24);
    }
    return l10n.summaryCancellationPolicyHours(hours);
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
