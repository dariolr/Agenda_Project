import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/class_event.dart';
import '../../../../core/models/booking_form.dart';
import '../../../../core/widgets/dynamic_form_fields.dart';

import '../../../../app/providers/route_slug_provider.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/services/pending_booking_storage.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/booking_direct_link_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/booking_nomenclature_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/locations_provider.dart';
import '../widgets/wrong_business_auth_banner.dart';
import '../booking_step_layout.dart';

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
  String? _formsContextKey;
  bool _formsLoading = false;
  List<BookingForm> _bookingForms = const [];
  final Map<int, dynamic> _formAnswers = {};
  final Set<int> _invalidRequiredFieldIds = {};

  // Moduli per-cliente in sospeso (raccolti una volta sola). Caricati solo se
  // il cliente è autenticato; il contesto è business + sede scelta.
  String? _customerFormsContextKey;
  bool _customerFormsLoading = false;
  List<BookingForm> _customerForms = const [];
  final Map<int, dynamic> _customerAnswers = {};
  final Set<int> _invalidCustomerFieldIds = {};

  Future<void> _savePendingBookingForAuth() async {
    final bookingState = ref.read(bookingFlowProvider);
    final locationId = ref.read(effectiveLocationIdProvider);
    final business = ref.read(currentBusinessProvider).value;
    if (locationId <= 0 || business == null) return;

    await PendingBookingStorage.save(
      PendingBookingData.fromBookingRequest(
        businessId: business.id,
        locationId: locationId,
        selectedLocation: ref.read(selectedLocationProvider),
        request: bookingState.request,
      ),
    );
  }

  String _authPathWithBookingQuery(String slug) {
    final params = <String, String>{'from': 'booking'};
    final linkSlug = ref.read(bookingDirectLinkSlugProvider);
    if (linkSlug != null && linkSlug.isNotEmpty) {
      params['link'] = linkSlug;
    }
    final location = ref.read(effectiveLocationProvider);
    if (location != null) {
      params['location'] = location.id.toString();
    }
    final query = Uri(queryParameters: params).query;
    return '/$slug/login?$query';
  }

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
    final displayedManualServices = request.services
        .where(
          (service) =>
              request.isServiceManuallySelected(service.id) &&
              !totals.coveredServiceIds.contains(service.id),
        )
        .toList();
    final summaryItemCount =
        totals.selectedPackages.length + displayedManualServices.length;
    final hasMultipleSummaryItems = summaryItemCount > 1;
    final location = ref.watch(effectiveLocationProvider);
    final business = ref.watch(currentBusinessProvider).value;
    final cancellationHours =
        location?.cancellationHours ?? business?.cancellationHours ?? 24;
    // Se al momento della prenotazione i termini di modifica/cancellazione sono
    // già scaduti (appuntamento troppo vicino), l'utente deve essere informato
    // e accettare questa situazione specifica invece della policy ordinaria.
    final isCancellationWindowExpired = _isCancellationWindowExpired(
      ref.watch(locationNowProvider),
      request.selectedSlot?.startTime,
      cancellationHours,
    );
    _refreshBookingFormsIfNeeded(business?.id, location?.id, request);
    _loadCustomerFormsIfNeeded(business?.id, location?.id);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            kBookingStepHorizontalMargin,
            12,
            kBookingStepHorizontalMargin,
            8,
          ),
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
            // Aggiunge padding bottom per footer fisso (~72px) +
            // gesture bar Android + tastiera (quando il campo note è attivo).
            padding: EdgeInsets.fromLTRB(
              kBookingStepHorizontalMargin,
              0,
              kBookingStepHorizontalMargin,
              MediaQuery.of(context).viewPadding.bottom +
                  MediaQuery.of(context).viewInsets.bottom +
                  72 +
                  24,
            ),
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
                    phraseOverrides,
                    showPriceToCustomer: location?.showPriceToCustomer ?? true,
                  ),
                  const SizedBox(height: 16),
                ],

                // === BRANCH SERVIZIO NORMALE ===
                // Data e ora
                if (!request.isClassEventBooking &&
                    request.selectedSlot != null)
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
                if (!request.isClassEventBooking &&
                    request.selectedSlot != null)
                  const SizedBox(height: 16),

                // Servizi selezionati (con operatore)
                if (request.isClassEventBooking)
                  const SizedBox.shrink()
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
                            final packageDescription = package.description
                                ?.trim();
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
                                          package.name,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        if (packageDescription != null &&
                                            packageDescription.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2,
                                            ),
                                            child: Text(
                                              packageDescription,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.7),
                                                  ),
                                            ),
                                          ),
                                        if (hasMultipleSummaryItems)
                                          Text(
                                            context.localizedDurationLabel(
                                              package
                                                  .customerVisibleDurationMinutes(
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
                                  if (hasMultipleSummaryItems)
                                    Text(
                                      _formatTotalPrice(
                                        context,
                                        package.effectivePrice,
                                      ).replaceFirst('€', '').trim(),
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
                        ...displayedManualServices.map((service) {
                          final staff = request.staffForService(service.id);
                          final serviceDescription = service.description
                              ?.trim();
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                      if (serviceDescription != null &&
                                          serviceDescription.isNotEmpty) ...[
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 2,
                                          ),
                                          child: Text(
                                            serviceDescription,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.7),
                                                ),
                                          ),
                                        ),
                                        // Riga di separazione dopo la
                                        // descrizione del tipo di prenotazione.
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 6,
                                            bottom: 4,
                                          ),
                                          child: Divider(
                                            height: 1,
                                            color: theme.dividerColor,
                                          ),
                                        ),
                                      ],
                                      Text(
                                        operatorLabel,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withOpacity(0.6),
                                            ),
                                      ),
                                      if (hasMultipleSummaryItems)
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
                                if (hasMultipleSummaryItems &&
                                    (location?.showPriceToCustomer ?? true))
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
                        if ((location?.showDurationToCustomer ?? true) ||
                            (location?.showPriceToCustomer ?? true))
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (location?.showDurationToCustomer ?? true)
                                Text(
                                  l10n.summaryDuration,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              if (location?.showPriceToCustomer ?? true)
                                Row(
                                  children: [
                                    Text(
                                      hasMultipleSummaryItems
                                          ? l10n.summaryPrice
                                          : l10n.summarySinglePrice,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        if ((location?.showDurationToCustomer ?? true) ||
                            (location?.showPriceToCustomer ?? true))
                          const SizedBox(height: 6),
                        if ((location?.showDurationToCustomer ?? true) ||
                            (location?.showPriceToCustomer ?? true))
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (location?.showDurationToCustomer ?? true)
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
                                      context.localizedDurationLabel(
                                        totals.totalDurationMinutes,
                                      ),
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              if (location?.showPriceToCustomer ?? true)
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
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
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

                if (_formsLoading) ...[
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 16),
                ] else if (_bookingForms.isNotEmpty) ...[
                  _buildBookingFormsSection(context, theme),
                  const SizedBox(height: 16),
                ],

                if (_customerFormsLoading) ...[
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 16),
                ] else if (_customerForms.isNotEmpty) ...[
                  _buildCustomerFormsSection(context, theme),
                  const SizedBox(height: 16),
                ],

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
                      if (isCancellationWindowExpired)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            // Coppia Material errorContainer/onErrorContainer
                            // (senza opacità) per garantire il contrasto.
                            color: theme.colorScheme.errorContainer,
                            // Stesso arrotondamento dei riquadri dei moduli
                            // (es. consenso privacy).
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.onErrorContainer
                                  .withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 20,
                                color: theme.colorScheme.onErrorContainer,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  l10n.summaryCancellationPolicyExpiredInfo,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onErrorContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
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
                                isCancellationWindowExpired
                                    ? l10n
                                          .summaryCancellationPolicyExpiredAcceptLabel
                                    : l10n.summaryCancellationPolicyAcceptLabel,
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
                          isCancellationWindowExpired
                              ? l10n
                                    .summaryCancellationPolicyExpiredAcceptRequiredError
                              : l10n
                                    .summaryCancellationPolicyAcceptRequiredError,
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
    Map<String, String>? phraseOverrides, {
    bool showPriceToCustomer = true,
  }) {
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
      title: bookingSummaryEventLabel(
        context,
        phraseOverrides: phraseOverrides,
      ),
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
              if (showPriceToCustomer)
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
                    ? bookingClassEventFullLabel(
                        context,
                        phraseOverrides: phraseOverrides,
                      )
                    : bookingClassEventSpotsAvailableLabel(
                        context,
                        event.spotsLeft,
                        phraseOverrides: phraseOverrides,
                      ),
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
                    bookingClassEventWaitlistNotice(
                      context,
                      phraseOverrides: phraseOverrides,
                    ),
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
                        await _savePendingBookingForAuth();
                        if (!context.mounted) return;
                        context.go(_authPathWithBookingQuery(slug));
                        return;
                      }
                      if (!_cancellationPolicyAccepted) {
                        setState(() {
                          _showCancellationPolicyWarning = true;
                        });
                        _scrollToBottom();
                        return;
                      }
                      final formsValid = _validateBookingForms();
                      final customerFormsValid = _validateCustomerForms();
                      if (!formsValid || !customerFormsValid) {
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
                            .confirmBooking(
                              formSubmissions: _buildFormSubmissions(),
                            );
                        // Moduli per-cliente in sospeso (indipendenti dalla
                        // prenotazione): inviati dopo la conferma riuscita.
                        await _submitCustomerForms(
                          ref.read(currentBusinessProvider).value?.id,
                          ref.read(effectiveLocationIdProvider),
                        );
                      } on TokenExpiredException {
                        // Sessione scaduta - reindirizza al login
                        // Lo stato della prenotazione è già salvato in localStorage
                        if (context.mounted && slug != null) {
                          context.go(_authPathWithBookingQuery(slug));
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
      case 'service_capacity_full':
        return l10n.apiErrorServiceCapacityFull;
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
      case 'booking_form_required_fields_missing':
      case 'booking_form_invalid_field':
      case 'booking_form_not_applicable':
        return l10n.bookingFormsSubmitError;
      case 'internal_error':
        return l10n.bookingErrorServer;
    }
    return state.errorMessage ?? l10n.errorGeneric;
  }

  /// True se i termini di modifica/cancellazione risultano già scaduti al
  /// momento della prenotazione (l'appuntamento è più vicino della finestra
  /// consentita). Le policy "Sempre" (0) e "Mai" (costante) non dipendono dalla
  /// vicinanza dell'appuntamento e non vengono mai considerate "scadute" qui.
  bool _isCancellationWindowExpired(
    DateTime now,
    DateTime? appointmentStart,
    int hours,
  ) {
    if (appointmentStart == null) return false;
    if (hours <= 0 || hours == _neverCancellationHours) return false;
    final deadline = appointmentStart.subtract(Duration(hours: hours));
    return now.isAfter(deadline);
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

  void _refreshBookingFormsIfNeeded(
    int? businessId,
    int? locationId,
    dynamic request,
  ) {
    if (businessId == null || locationId == null || locationId <= 0) return;
    final serviceIds =
        request.services.map<int>((service) => service.id as int).toList()
          ..sort();
    final variantIds =
        request.services
            .map<int?>((service) => service.serviceVariantId as int?)
            .whereType<int>()
            .toList()
          ..sort();
    final packageIds = request.selectedPackageIds.toList()..sort();
    final classEventIds = request.selectedClassEvent == null
        ? <int>[]
        : <int>[request.selectedClassEvent.id as int];
    final key = [
      businessId,
      locationId,
      serviceIds.join(','),
      variantIds.join(','),
      packageIds.join(','),
      classEventIds.join(','),
    ].join('|');
    if (_formsContextKey == key || _formsLoading) return;
    _formsContextKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      setState(() {
        _formsLoading = true;
        _bookingForms = const [];
        _formAnswers.clear();
        _invalidRequiredFieldIds.clear();
      });
      try {
        final forms = await ref
            .read(bookingRepositoryProvider)
            .resolveBookingForms(
              businessId: businessId,
              locationId: locationId,
              serviceIds: serviceIds,
              serviceVariantIds: variantIds,
              packageIds: packageIds,
              classEventIds: classEventIds,
            );
        if (!mounted) return;
        setState(() {
          _bookingForms = forms;
          _formsLoading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _bookingForms = const [];
          _formsLoading = false;
        });
      }
    });
  }

  void _loadCustomerFormsIfNeeded(int? businessId, int? locationId) {
    if (businessId == null || locationId == null || locationId <= 0) return;
    final isAuthenticated = ref.read(
      authProvider.select((state) => state.isAuthenticated),
    );
    if (!isAuthenticated) return;
    final key = '$businessId|$locationId';
    if (_customerFormsContextKey == key || _customerFormsLoading) return;
    _customerFormsContextKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      setState(() {
        _customerFormsLoading = true;
        _customerForms = const [];
        _customerAnswers.clear();
        _invalidCustomerFieldIds.clear();
      });
      try {
        final response = await ref
            .read(apiClientProvider)
            .getPendingCustomerForms(
              businessId: businessId,
              locationId: locationId,
            );
        if (!mounted) return;
        final forms = (response['forms'] as List<dynamic>? ?? const [])
            .map((item) => BookingForm.fromJson(item as Map<String, dynamic>))
            .toList();
        setState(() {
          _customerForms = forms;
          _customerFormsLoading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _customerForms = const [];
          _customerFormsLoading = false;
        });
      }
    });
  }

  bool _validateCustomerForms() {
    final invalid = BookingFormAnswers.invalidRequired(
      _customerForms,
      _customerAnswers,
    );
    setState(() {
      _invalidCustomerFieldIds
        ..clear()
        ..addAll(invalid);
    });
    return invalid.isEmpty;
  }

  Future<void> _submitCustomerForms(int? businessId, int? locationId) async {
    if (_customerForms.isEmpty || businessId == null) return;
    final submissions = BookingFormAnswers.buildSubmissions(
      _customerForms,
      _customerAnswers,
    );
    if (submissions.isEmpty) return;
    try {
      await ref.read(apiClientProvider).submitCustomerForms(
            businessId: businessId,
            locationId: locationId,
            submissions: submissions,
          );
    } catch (_) {
      // Best-effort: un errore qui non deve invalidare la prenotazione creata.
    }
  }

  bool _validateBookingForms() {
    final invalid = <int>{};
    for (final form in _bookingForms) {
      for (final field in form.fields) {
        if (!field.isRequired || !field.isInput) continue;
        final value = _formAnswers[field.id];
        if (!_hasFormValue(field, value)) {
          invalid.add(field.id);
        }
      }
    }
    setState(() {
      _invalidRequiredFieldIds
        ..clear()
        ..addAll(invalid);
    });
    return invalid.isEmpty;
  }

  bool _hasFormValue(BookingFormField field, dynamic value) {
    if (field.fieldType == 'checkbox' || field.fieldType == 'consent') {
      return value == true;
    }
    if (field.fieldType == 'multiple_choice') {
      return value is Set<String> && value.isNotEmpty;
    }
    if (value == null) return false;
    return value.toString().trim().isNotEmpty;
  }

  List<Map<String, dynamic>> _buildFormSubmissions() {
    final submissions = <Map<String, dynamic>>[];
    for (final form in _bookingForms) {
      final answers = <Map<String, dynamic>>[];
      for (final field in form.fields) {
        if (!field.isInput) continue;
        final value = _formAnswers[field.id];
        if (!_hasFormValue(field, value)) continue;
        answers.add({
          'field_id': field.id,
          'value': value is Set<String> ? value.toList() : value,
        });
      }
      if (answers.isNotEmpty) {
        submissions.add({'form_id': form.id, 'answers': answers});
      }
    }
    return submissions;
  }

  Widget _buildBookingFormsSection(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        for (var index = 0; index < _bookingForms.length; index++) ...[
          _BookingFormSection(
            form: _bookingForms[index],
            theme: theme,
            formAnswers: _formAnswers,
            invalidRequiredFieldIds: _invalidRequiredFieldIds,
            onFieldChanged: (fieldId, value) {
              setState(() {
                _formAnswers[fieldId] = value;
                _invalidRequiredFieldIds.remove(fieldId);
              });
            },
          ),
          if (index != _bookingForms.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildCustomerFormsSection(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        for (var index = 0; index < _customerForms.length; index++) ...[
          _BookingFormSection(
            form: _customerForms[index],
            theme: theme,
            formAnswers: _customerAnswers,
            invalidRequiredFieldIds: _invalidCustomerFieldIds,
            onFieldChanged: (fieldId, value) {
              setState(() {
                _customerAnswers[fieldId] = value;
                _invalidCustomerFieldIds.remove(fieldId);
              });
            },
          ),
          if (index != _customerForms.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _BookingFormSection extends StatelessWidget {
  const _BookingFormSection({
    required this.form,
    required this.theme,
    required this.formAnswers,
    required this.invalidRequiredFieldIds,
    required this.onFieldChanged,
  });

  final BookingForm form;
  final ThemeData theme;
  final Map<int, dynamic> formAnswers;
  final Set<int> invalidRequiredFieldIds;
  final void Function(int fieldId, dynamic value) onFieldChanged;

  @override
  Widget build(BuildContext context) {
    return _SummarySection(
      title: form.title,
      icon: Icons.assignment_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (form.description != null && form.description!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(form.description!, style: theme.textTheme.bodySmall),
            ),
          for (var index = 0; index < form.fields.length; index++) ...[
            BookingFormFieldWidget(
              field: form.fields[index],
              value: formAnswers[form.fields[index].id],
              showRequiredError: invalidRequiredFieldIds.contains(
                form.fields[index].id,
              ),
              onChanged: (value) =>
                  onFieldChanged(form.fields[index].id, value),
            ),
            if (index != form.fields.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
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
