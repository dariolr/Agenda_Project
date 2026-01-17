import 'package:agenda_backend/app/providers/form_factor_provider.dart';
import 'package:agenda_backend/app/theme/app_spacing.dart';
import 'package:agenda_backend/app/widgets/staff_circle_avatar.dart';
import 'package:agenda_backend/core/l10n/date_time_formats.dart';
import 'package:agenda_backend/core/models/appointment.dart';
import 'package:agenda_backend/core/widgets/labeled_form_field.dart';
import 'package:agenda_backend/core/widgets/no_scrollbar_behavior.dart';
import 'package:agenda_backend/features/staff/providers/staff_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/booking.dart';
import '../../../../core/models/service_variant.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_dividers.dart';
import '../../../../core/widgets/feedback_dialog.dart';
import '../../../../core/widgets/local_loading_overlay.dart';
import '../../../clients/domain/clients.dart';
import '../../../clients/presentation/dialogs/client_edit_dialog.dart';
import '../../../clients/providers/clients_providers.dart';
import '../../../services/providers/service_categories_provider.dart';
import '../../../services/providers/services_provider.dart';
import '../../data/bookings_api.dart';
import '../../domain/service_item_data.dart';
import '../../providers/agenda_scroll_request_provider.dart';
import '../../providers/appointment_providers.dart';
import '../../providers/bookings_provider.dart';
import '../../providers/bookings_repository_provider.dart';
import '../../providers/business_providers.dart';
import '../../providers/date_range_provider.dart';
import '../../providers/layout_config_provider.dart';
import '../../providers/location_providers.dart';
import '../../providers/staff_slot_availability_provider.dart';
import 'service_item_card.dart';

/// Show the Booking dialog for creating a new multi-service booking.
Future<void> showBookingDialog(
  BuildContext context,
  WidgetRef ref, {
  Booking? existing,
  DateTime? date,
  TimeOfDay? time,
  int? initialStaffId,
  bool autoOpenDatePicker = false,
}) async {
  final formFactor = ref.read(formFactorProvider);
  final presentation = formFactor == AppFormFactor.desktop
      ? _BookingPresentation.dialog
      : _BookingPresentation.bottomSheet;

  final content = _BookingDialog(
    existing: existing,
    initialDate: date,
    initialTime: time,
    initialStaffId: initialStaffId,
    autoOpenDatePicker: autoOpenDatePicker,
    presentation: presentation,
  );

  if (presentation == _BookingPresentation.dialog) {
    await showDialog(
      context: context,
      builder: (_) => content,
      barrierDismissible: false,
    );
  } else {
    await AppBottomSheet.show(
      context: context,
      useRootNavigator: true,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
      builder: (_) => content,
      heightFactor: AppBottomSheet.defaultHeightFactor,
    );
  }
}

enum _BookingPresentation { dialog, bottomSheet }

class _BookingDialog extends ConsumerStatefulWidget {
  const _BookingDialog({
    this.existing,
    this.initialDate,
    this.initialTime,
    this.initialStaffId,
    this.autoOpenDatePicker = false,
    required this.presentation,
  });

  final Booking? existing;
  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final int? initialStaffId;
  final bool autoOpenDatePicker;
  final _BookingPresentation presentation;

  @override
  ConsumerState<_BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends ConsumerState<_BookingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late DateTime _date;
  int? _clientId;

  bool _clientPickerAutoRequested = false;
  int? _autoOpenServicePickerIndex;
  bool _shouldAutoOpenServicePicker = false;
  bool _datePickerAutoRequested = false;

  /// Nome cliente personalizzato (usato solo per clienti nuovi non ancora salvati)
  String _customClientName = '';

  /// Lista di servizi nella prenotazione
  final List<ServiceItemData> _serviceItems = [];

  /// Contatore per generare chiavi univoche
  int _itemKeyCounter = 0;

  bool _warningDismissed = false;
  bool _midnightWarningVisible = false;
  bool _midnightWarningDismissed = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final agendaDate = ref.read(agendaDateProvider);

    if (widget.existing != null) {
      // Editing existing booking
      _date = DateUtils.dateOnly(widget.initialDate ?? agendaDate);
      _notesController.text = widget.existing!.notes ?? '';
      _clientId = widget.existing!.clientId;
      _customClientName = widget.existing!.clientName ?? '';

      // Load existing appointments into _serviceItems
      final bookingAppointments = ref
          .read(appointmentsProvider.notifier)
          .getByBookingId(widget.existing!.id);

      for (final appointment in bookingAppointments) {
        final baseDuration = _baseDurationFromAppointment(appointment);
        final blockedExtraMinutes = appointment.blockedExtraMinutes;
        final processingExtraMinutes = appointment.processingExtraMinutes;
        _serviceItems.add(
          ServiceItemData(
            key: _nextItemKey(),
            startTime: TimeOfDay.fromDateTime(appointment.startTime),
            staffId: appointment.staffId,
            serviceId: appointment.serviceId,
            serviceVariantId: appointment.serviceVariantId,
            durationMinutes: baseDuration,
            blockedExtraMinutes: blockedExtraMinutes,
            processingExtraMinutes: processingExtraMinutes,
          ),
        );
      }

      // Se non ci sono appointments, aggiungi un item vuoto
      if (_serviceItems.isEmpty) {
        final initialTime =
            widget.initialTime ?? const TimeOfDay(hour: 10, minute: 0);
        _serviceItems.add(
          ServiceItemData(key: _nextItemKey(), startTime: initialTime),
        );
      }
    } else {
      _date = DateUtils.dateOnly(widget.initialDate ?? agendaDate);

      // Aggiungi un primo servizio vuoto
      final initialTime =
          widget.initialTime ?? const TimeOfDay(hour: 10, minute: 0);
      _serviceItems.add(
        ServiceItemData(
          key: _nextItemKey(),
          startTime: initialTime,
          staffId: widget.initialStaffId,
        ),
      );
    }

    if (widget.existing == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        if (widget.autoOpenDatePicker) {
          await _scheduleAutoDatePicker();
        }
        if (!mounted) return;
        _scheduleAutoClientPicker();
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  int _baseDurationFromAppointment(Appointment appointment) {
    final totalMinutes = appointment.endTime
        .difference(appointment.startTime)
        .inMinutes;
    final extraMinutes = appointment.blockedExtraMinutes;
    final base = totalMinutes - extraMinutes;
    return base > 0 ? base : 0;
  }

  String _nextItemKey() => 'item_${_itemKeyCounter++}';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEdit = widget.existing != null;
    final isDialog = widget.presentation == _BookingPresentation.dialog;

    final formFactor = ref.watch(formFactorProvider);
    final services = ref.watch(servicesProvider).value ?? [];
    final serviceCategories = ref.watch(serviceCategoriesProvider);
    final variants = ref.watch(serviceVariantsProvider).value ?? [];
    final asyncClients = ref.watch(clientsProvider);
    final clients = asyncClients.value ?? [];
    final clientsById = ref.watch(clientsByIdProvider);
    final allStaff = ref.watch(staffForCurrentLocationProvider);

    // Deriva il nome del cliente dal provider se _clientId è impostato,
    // altrimenti usa il nome personalizzato (per clienti nuovi)
    final clientName = _clientId != null
        ? (clientsById[_clientId]?.name ?? _customClientName)
        : _customClientName;

    final title = isEdit
        ? l10n.appointmentDialogTitleEdit
        : l10n.appointmentDialogTitleNew;

    final isDesktop = widget.presentation == _BookingPresentation.dialog;
    final conflictFlags = _serviceConflictFlags();
    final eligibleIndices = <int>[];
    for (int i = 0; i < _serviceItems.length; i++) {
      if (_isWarningEligible(_serviceItems[i])) {
        eligibleIndices.add(i);
      }
    }
    final allEligibleConflict =
        eligibleIndices.isNotEmpty &&
        eligibleIndices.every((i) => conflictFlags[i]);
    final showAppointmentWarning =
        eligibleIndices.length > 1 && allEligibleConflict;
    final showServiceWarnings = !showAppointmentWarning;
    final content = Form(
      key: _formKey,
      child: ConstrainedBox(
        // Su desktop, limita la larghezza del form. Su mobile, usa tutta la larghezza.
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 340 : double.infinity,
        ),
        child: ScrollConfiguration(
          behavior: const NoScrollbarBehavior(),
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.formFirstRowSpacing),

                // Client selection
                _ClientSelectionField(
                  clientId: _clientId,
                  clientName: clientName,
                  clients: clients,
                  onClientSelected: (id, name) {
                    setState(() {
                      _clientId = id;
                      _customClientName = name;
                    });
                  },
                  onClientRemoved: () {
                    setState(() {
                      _clientId = null;
                      _customClientName = '';
                    });
                  },
                  onOpenPicker: _openClientPicker,
                ),
                const SizedBox(height: AppSpacing.formRowSpacing),

                // Date and Time selector (row)
                LabeledFormField(
                  label: l10n.formDate,
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(8),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DtFmt.shortDate(context, _date)),
                          const Icon(Icons.calendar_today, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.formRowSpacing),

                // Services section header
                // Services list
                ..._buildServiceItems(
                  services: services,
                  categories: serviceCategories,
                  variants: variants,
                  allStaff: allStaff,
                  formFactor: formFactor,
                  conflictFlags: conflictFlags,
                  showServiceWarnings: showServiceWarnings,
                  serviceWarningMessage:
                      l10n.bookingUnavailableTimeWarningService,
                ),

                const SizedBox(height: AppSpacing.formRowSpacing),

                // Notes field
                LabeledFormField(
                  label: l10n.formNotes,
                  child: TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      hintText: l10n.notesPlaceholder,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(height: AppSpacing.formRowSpacing),
              ],
            ),
          ),
        ),
      ),
    );

    final actions = [
      AppOutlinedActionButton(
        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
        padding: AppButtonStyles.dialogButtonPadding,
        child: Text(l10n.actionCancel),
      ),
      AppAsyncFilledButton(
        onPressed: _isSaving ? null : _onSave,
        padding: AppButtonStyles.dialogButtonPadding,
        isLoading: _isSaving,
        showSpinner: false,
        child: Text(l10n.actionSave),
      ),
    ];

    if (isDialog) {
      return DismissibleDialog(
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 600, maxWidth: 720),
            child: LocalLoadingOverlay(
              isLoading: _isSaving,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Flexible(child: content),
                    const SizedBox(height: AppSpacing.formToActionsSpacing),
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppSpacing.formFirstRowSpacing,
                      ),
                      child: _warningBanner(
                        20,
                        showAppointmentWarning,
                        l10n.bookingUnavailableTimeWarningAppointment,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        for (int i = 0; i < actions.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          SizedBox(
                            width: AppButtonStyles.dialogButtonWidth,
                            child: actions[i],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Bottom sheet layout
    const horizontalPadding = 20.0;
    final titlePadding = EdgeInsets.fromLTRB(
      horizontalPadding,
      0,
      horizontalPadding,
      12,
    );

    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return SafeArea(
      top: false,
      child: LocalLoadingOverlay(
        isLoading: _isSaving,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: titlePadding,
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: content,
              ),
            ),
            _warningBanner(
              horizontalPadding,
              showAppointmentWarning,
              l10n.bookingUnavailableTimeWarningAppointment,
            ),
            if (!isKeyboardOpen) ...[
              const AppBottomSheetDivider(),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AppSpacing.formFirstRowSpacing,
                  horizontalPadding,
                  0,
                ),
                child: Row(
                  mainAxisAlignment: actions.length == 3
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.end,
                  children: [
                    for (int i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      SizedBox(
                        width: AppButtonStyles.dialogButtonWidth,
                        child: actions[i],
                      ),
                    ],
                  ],
                ),
              ),
            ],
            SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildServiceItems({
    required List<dynamic> services,
    required List<dynamic> categories,
    required List<dynamic> variants,
    required List<dynamic> allStaff,
    required AppFormFactor formFactor,
    required List<bool> conflictFlags,
    required bool showServiceWarnings,
    required String serviceWarningMessage,
  }) {
    final widgets = <Widget>[];

    // Conta servizi effettivamente selezionati
    final selectedCount = _serviceItems
        .where((s) => s.serviceId != null)
        .length;

    for (int i = 0; i < _serviceItems.length; i++) {
      final item = _serviceItems[i];
      final TimeOfDay? suggestedStartTime = i > 0
          ? _resolveServiceEndTime(_serviceItems[i - 1], variants.cast())
          : null;
      final variant = item.serviceId != null
          ? variants.cast<ServiceVariant?>().firstWhere(
              (v) => v?.serviceId == item.serviceId,
              orElse: () => null,
            )
          : null;
      final defaultProcessing = variant?.processingTime ?? 0;
      final defaultBlocked = variant?.blockedTime ?? 0;
      final defaultExtraType = defaultBlocked > 0
          ? ExtraMinutesType.blocked
          : (defaultProcessing > 0 ? ExtraMinutesType.processing : null);
      final hasBlockedExtra = item.blockedExtraMinutes > 0;
      final hasProcessingExtra = item.processingExtraMinutes > 0;
      final canAddDefaultExtra = defaultExtraType == ExtraMinutesType.blocked
          ? !hasBlockedExtra
          : (defaultExtraType == ExtraMinutesType.processing
                ? !hasProcessingExtra
                : false);
      final showWarning =
          showServiceWarnings &&
          _isWarningEligible(item) &&
          i < conflictFlags.length &&
          conflictFlags[i];

      // Get eligible staff for this service
      final eligibleStaffIds = item.serviceId != null
          ? ref.watch(eligibleStaffForServiceProvider(item.serviceId!))
          : <int>[];
      final isStaffIneligible =
          item.serviceId != null &&
          item.staffId != null &&
          !eligibleStaffIds.contains(item.staffId);

      final isFirst = i == 0;
      final isLast = i == _serviceItems.length - 1;
      widgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isFirst) ...[
              Row(
                children: [
                  Text(
                    selectedCount > 0
                        ? context.l10n.servicesSelectedCount(selectedCount)
                        : context.l10n.formServices,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ServiceItemCard(
                index: i,
                item: item,
                services: services.cast(),
                categories: categories.cast(),
                variants: variants.cast(),
                eligibleStaff: eligibleStaffIds,
                allStaff: allStaff.cast(),
                formFactor: formFactor,
                canRemove: _serviceItems.length > 1,
                // Obbligatorio solo se non ci sono altri servizi selezionati
                isServiceRequired: selectedCount == 0,
                onChanged: (updated) => _updateServiceItem(i, updated),
                onRemove: () => _removeServiceItem(i),
                onStartTimeChanged: (time) => _updateServiceStartTime(i, time),
                onEndTimeChanged: (time) => _updateServiceEndTime(i, time),
                onDurationChanged: (duration) =>
                    _updateServiceDuration(i, duration),
                suggestedStartTime: suggestedStartTime,
                autoOpenServicePicker:
                    (_shouldAutoOpenServicePicker && i == 0) ||
                    _autoOpenServicePickerIndex == i,
                onServicePickerAutoOpened:
                    (_shouldAutoOpenServicePicker && i == 0) ||
                        _autoOpenServicePickerIndex == i
                    ? () {
                        if (_shouldAutoOpenServicePicker && i == 0) {
                          _onServicePickerAutoOpened();
                        }
                        _onServicePickerAutoOpenedForIndex(i);
                      }
                    : null,
                onServicePickerAutoCompleted: _scrollFormToBottom,
                onAutoOpenStaffPickerCompleted: _scrollFormToBottom,
                availabilityWarningMessage: showWarning
                    ? serviceWarningMessage
                    : null,
                staffEligibilityWarningMessage: isStaffIneligible
                    ? context.l10n.bookingStaffNotEligibleWarning
                    : null,
              ),
            ),
            if (canAddDefaultExtra) ...[
              if (isLast && item.serviceId != null)
                Row(
                  children: [
                    AppOutlinedActionButton(
                      onPressed: () {
                        setState(() {
                          _serviceItems[i] =
                              defaultExtraType == ExtraMinutesType.blocked
                              ? _serviceItems[i].copyWith(
                                  blockedExtraMinutes: defaultBlocked,
                                )
                              : _serviceItems[i].copyWith(
                                  processingExtraMinutes: defaultProcessing,
                                );
                          _recalculateTimesFrom(i + 1, variants.cast());
                          _clearMidnightWarningIfResolved(variants.cast());
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, size: 18),
                          const SizedBox(width: 8),
                          Text(context.l10n.additionalTimeSwitch),
                        ],
                      ),
                    ),
                    const Spacer(),
                    AppOutlinedActionButton(
                      onPressed: _addService,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, size: 18),
                          const SizedBox(width: 8),
                          Text(context.l10n.addService),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Align(
                  alignment: Alignment.centerRight,
                  child: AppOutlinedActionButton(
                    onPressed: () {
                      setState(() {
                        _serviceItems[i] =
                            defaultExtraType == ExtraMinutesType.blocked
                            ? _serviceItems[i].copyWith(
                                blockedExtraMinutes: defaultBlocked,
                              )
                            : _serviceItems[i].copyWith(
                                processingExtraMinutes: defaultProcessing,
                              );
                        _recalculateTimesFrom(i + 1, variants.cast());
                        _clearMidnightWarningIfResolved(variants.cast());
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, size: 18),
                        const SizedBox(width: 8),
                        Text(context.l10n.additionalTimeSwitch),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              if (isLast &&
                  item.serviceId != null &&
                  _midnightWarningVisible &&
                  !_midnightWarningDismissed) ...[
                _midnightWarningBanner(),
                const SizedBox(height: 16),
              ],
            ],
            if (hasBlockedExtra) ...[
              ExtraTimeCard(
                title: context.l10n.fieldBlockedTimeLabel,
                startTime: _baseEndTime(item, variants.cast()),
                durationMinutes: item.blockedExtraMinutes,
                formFactor: formFactor,
                onStartTimeChanged: (_) {},
                onDurationChanged: (duration) {
                  setState(() {
                    _serviceItems[i] = _serviceItems[i].copyWith(
                      blockedExtraMinutes: duration,
                    );
                    _recalculateTimesFrom(i + 1, variants.cast());
                    _clearMidnightWarningIfResolved(variants.cast());
                  });
                },
                onRemove: () {
                  setState(() {
                    _serviceItems[i] = _serviceItems[i].copyWith(
                      blockedExtraMinutes: 0,
                    );
                    _recalculateTimesFrom(i + 1, variants.cast());
                    _clearMidnightWarningIfResolved(variants.cast());
                  });
                },
              ),
              const SizedBox(height: 8),
            ],
            if (hasProcessingExtra) ...[
              ExtraTimeCard(
                title: context.l10n.fieldProcessingTimeLabel,
                startTime: _addMinutes(
                  _baseEndTime(item, variants.cast()),
                  item.blockedExtraMinutes,
                ),
                durationMinutes: item.processingExtraMinutes,
                formFactor: formFactor,
                onStartTimeChanged: (_) {},
                onDurationChanged: (duration) {
                  setState(() {
                    _serviceItems[i] = _serviceItems[i].copyWith(
                      processingExtraMinutes: duration,
                    );
                    _recalculateTimesFrom(i + 1, variants.cast());
                    _clearMidnightWarningIfResolved(variants.cast());
                  });
                },
                onRemove: () {
                  setState(() {
                    _serviceItems[i] = _serviceItems[i].copyWith(
                      processingExtraMinutes: 0,
                    );
                    _recalculateTimesFrom(i + 1, variants.cast());
                    _clearMidnightWarningIfResolved(variants.cast());
                  });
                },
              ),
              const SizedBox(height: 8),
            ],
            if (isLast && item.serviceId != null && !canAddDefaultExtra) ...[
              Align(
                alignment: Alignment.centerRight,
                child: AppOutlinedActionButton(
                  onPressed: _addService,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 18),
                      const SizedBox(width: 8),
                      Text(context.l10n.addService),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_midnightWarningVisible && !_midnightWarningDismissed) ...[
                _midnightWarningBanner(),
                const SizedBox(height: 8),
              ],
            ],
          ],
        ),
      );
    }

    if (_serviceItems.isEmpty) {
      widgets.add(
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              context.l10n.noServicesAdded,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _warningBanner(
    double horizontalPadding,
    bool hasConflicts,
    String message,
  ) {
    if (!hasConflicts || _warningDismissed) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        12,
        horizontalPadding,
        12,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.amber,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF8A4D00),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: const Color(0xFF8A4D00),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            onPressed: () {
              setState(() => _warningDismissed = true);
            },
          ),
        ],
      ),
    );
  }

  Widget _midnightWarningBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.amber,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.serviceStartsAfterMidnight,
              style: const TextStyle(
                color: Color(0xFF8A4D00),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: const Color(0xFF8A4D00),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            onPressed: () {
              setState(() => _midnightWarningDismissed = true);
            },
          ),
        ],
      ),
    );
  }

  void _showMidnightWarning() {
    setState(() {
      _midnightWarningVisible = true;
      _midnightWarningDismissed = false;
    });
  }

  void _clearMidnightWarningIfResolved(List<ServiceVariant> variants) {
    if (!_midnightWarningVisible) return;
    if (!_hasMidnightOverflow(variants)) {
      _midnightWarningVisible = false;
      _midnightWarningDismissed = false;
    }
  }

  bool _hasMidnightOverflow(List<ServiceVariant> variants) {
    for (final item in _serviceItems) {
      final startMinutes = item.startTime.hour * 60 + item.startTime.minute;
      final endTime = _resolveServiceEndTime(item, variants);
      final endMinutes = endTime.hour * 60 + endTime.minute;
      if (endMinutes < startMinutes) return true;
    }
    return false;
  }

  bool _isWarningEligible(ServiceItemData item) {
    return item.serviceId != null && item.staffId != null;
  }

  List<bool> _serviceConflictFlags() {
    final layout = ref.watch(layoutConfigProvider);
    final Map<int, Set<int>> cache = {};
    final flags = <bool>[];

    for (final item in _serviceItems) {
      final staffId = item.staffId;
      if (staffId == null || item.serviceId == null) {
        flags.add(false);
        continue;
      }

      final available = cache.putIfAbsent(
        staffId,
        () => ref.watch(staffSlotAvailabilityProvider(staffId)),
      );

      if (available.isEmpty) {
        flags.add(true);
        continue;
      }

      final startMinutes = item.startTime.hour * 60 + item.startTime.minute;
      final endMinutes = startMinutes + item.durationMinutes;
      final startSlot = startMinutes ~/ layout.minutesPerSlot;
      final endSlot = (endMinutes / layout.minutesPerSlot).ceil();

      var hasConflict = false;
      for (int slot = startSlot; slot < endSlot; slot++) {
        if (!available.contains(slot)) {
          hasConflict = true;
          break;
        }
      }
      flags.add(hasConflict);
    }
    return flags;
  }

  void _scheduleAutoClientPicker() {
    if (_clientPickerAutoRequested) return;
    _clientPickerAutoRequested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openClientPicker(triggerServiceAutoOpen: true);
    });
  }

  Future<void> _scheduleAutoDatePicker() async {
    if (_datePickerAutoRequested) return;
    _datePickerAutoRequested = true;
    await _pickDate();
  }

  Future<void> _openClientPicker({bool triggerServiceAutoOpen = false}) async {
    final formFactor = ref.read(formFactorProvider);
    final isDesktop = formFactor == AppFormFactor.desktop;
    bool dismissed = false;

    while (mounted) {
      if (!mounted) return;
      final asyncClients = ref.read(clientsProvider);
      final clients = asyncClients.value ?? [];
      _ClientItem? result;
      if (isDesktop) {
        result = await showDialog<_ClientItem?>(
          context: context,
          builder: (ctx) => Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 600,
                maxWidth: 720,
                maxHeight: 600,
              ),
              child: _ClientPickerSheet(
                clients: clients,
                selectedClientId: _clientId,
              ),
            ),
          ),
        );
      } else {
        result = await AppBottomSheet.show<_ClientItem?>(
          context: context,
          useRootNavigator: true,
          padding: EdgeInsets.zero,
          heightFactor: AppBottomSheet.defaultHeightFactor,
          builder: (ctx) =>
              _ClientPickerSheet(clients: clients, selectedClientId: _clientId),
        );
      }

      if (result == null) {
        dismissed = true;
        break;
      }
      final selectedResult = result;
      if (selectedResult.id == -2) {
        if (!mounted) return;
        Client? initialClient;
        if (selectedResult.name.isNotEmpty) {
          final nameParts = Client.splitFullName(selectedResult.name);
          // NON passare businessId: lasciare che ClientForm usi currentBusinessProvider
          initialClient = Client(
            id: 0,
            businessId: ref.read(currentBusinessProvider).id,
            firstName: nameParts.firstName,
            lastName: nameParts.lastName,
            createdAt: DateTime.now(),
          );
        }
        final newClient = await showClientEditDialog(
          context,
          ref,
          client: initialClient,
        );
        if (newClient != null) {
          setState(() {
            _clientId = newClient.id;
            _customClientName = newClient.name;
          });
          break;
        }
        continue;
      } else if (selectedResult.id == -1) {
        setState(() {
          _clientId = null;
          _customClientName = '';
        });
        break;
      } else {
        setState(() {
          _clientId = selectedResult.id;
          _customClientName = selectedResult.name;
        });
        break;
      }
    }

    if (!mounted) return;
    if (triggerServiceAutoOpen && !dismissed) {
      setState(() {
        _shouldAutoOpenServicePicker = true;
      });
    }
  }

  void _onServicePickerAutoOpened() {
    if (!_shouldAutoOpenServicePicker) return;
    setState(() {
      _shouldAutoOpenServicePicker = false;
    });
  }

  void _onServicePickerAutoOpenedForIndex(int index) {
    if (_autoOpenServicePickerIndex != index) return;
    setState(() {
      _autoOpenServicePickerIndex = null;
    });
  }

  void _addService() {
    final variants = ref.read(serviceVariantsProvider).value ?? [];
    // Calcola l'orario di inizio per il nuovo servizio
    TimeOfDay nextStart;
    if (_serviceItems.isEmpty) {
      nextStart = widget.initialTime ?? const TimeOfDay(hour: 10, minute: 0);
    } else {
      // Prendi l'ultimo servizio e calcola il suo orario di fine
      final lastItem = _serviceItems.last;
      final lastStartMinutes =
          lastItem.startTime.hour * 60 + lastItem.startTime.minute;
      final lastEnd = _resolveServiceEndTime(lastItem, variants);
      final lastEndMinutes = lastEnd.hour * 60 + lastEnd.minute;

      // Blocca se il servizio precedente termina dopo la mezzanotte
      if (lastEndMinutes < lastStartMinutes) {
        _showMidnightWarning();
        return;
      }
      nextStart = lastEnd;
    }

    // Smart staff selection:
    // 1. Try initial staff if eligible
    // 2. Leave null for user selection
    int? smartStaffId = widget.initialStaffId;

    final newIndex = _serviceItems.length;
    setState(() {
      _clearMidnightWarningIfResolved(variants.cast());
      _serviceItems.add(
        ServiceItemData(
          key: _nextItemKey(),
          startTime: nextStart,
          staffId: smartStaffId,
        ),
      );
      _autoOpenServicePickerIndex = newIndex;
    });
  }

  void _removeServiceItem(int index) {
    if (_serviceItems.length <= 1) return;

    final variants = ref.read(serviceVariantsProvider).value ?? [];

    setState(() {
      _serviceItems.removeAt(index);

      // Ricalcola gli orari per i servizi successivi
      _recalculateTimesFrom(index, variants);
      _clearMidnightWarningIfResolved(variants.cast());
    });
  }

  void _updateServiceItem(int index, ServiceItemData updated) {
    final variants = ref.read(serviceVariantsProvider).value ?? [];

    setState(() {
      _serviceItems[index] = updated;

      // Se cambia il servizio, potremmo dover aggiornare lo staff
      // e ricalcolare gli orari successivi
      _recalculateTimesFrom(index + 1, variants);

      // Se lo staff è ancora null, seleziona automaticamente un eligible
      if (updated.serviceId != null && updated.staffId == null) {
        final newStaffId = _findBestStaff(updated.serviceId!);
        _serviceItems[index] = updated.copyWith(staffId: newStaffId);
      }
      _clearMidnightWarningIfResolved(variants.cast());
    });
  }

  void _updateServiceStartTime(int index, TimeOfDay newTime) {
    final variants = ref.read(serviceVariantsProvider).value ?? [];
    if (index > 0) {
      final prev = _serviceItems[index - 1];
      final prevStartMinutes = prev.startTime.hour * 60 + prev.startTime.minute;
      final prevEnd = _resolveServiceEndTime(prev, variants);
      final prevEndMinutes = prevEnd.hour * 60 + prevEnd.minute;
      if (prevEndMinutes < prevStartMinutes) {
        _showMidnightWarning();
        return;
      }
    }

    setState(() {
      final updated = _serviceItems[index].copyWith(startTime: newTime);
      _serviceItems[index] = _applyAutoExtraStart(updated, variants);

      // Ricalcola gli orari per i servizi successivi
      _recalculateTimesFrom(index + 1, variants);
      _clearMidnightWarningIfResolved(variants.cast());
    });
  }

  void _updateServiceEndTime(int index, TimeOfDay newEndTime) {
    setState(() {
      final item = _serviceItems[index];

      // Calcola la nuova durata basata sulla differenza tra end e start
      final startMinutes = item.startTime.hour * 60 + item.startTime.minute;
      final endMinutes = newEndTime.hour * 60 + newEndTime.minute;
      var newDuration = endMinutes - startMinutes;

      // Se la durata è negativa o zero, imposta un minimo di 15 minuti
      if (newDuration <= 0) {
        newDuration = 15;
      }

      _serviceItems[index] = item.copyWith(durationMinutes: newDuration);

      // Ricalcola gli orari per i servizi successivi
      final variants = ref.read(serviceVariantsProvider).value ?? [];
      _serviceItems[index] = _applyAutoExtraStart(
        _serviceItems[index],
        variants,
      );
      _recalculateTimesFrom(index + 1, variants);
      _clearMidnightWarningIfResolved(variants.cast());
    });
  }

  void _updateServiceDuration(int index, int newDuration) {
    setState(() {
      _serviceItems[index] = _serviceItems[index].copyWith(
        durationMinutes: newDuration,
      );

      // Ricalcola gli orari per i servizi successivi
      final variants = ref.read(serviceVariantsProvider).value ?? [];
      _serviceItems[index] = _applyAutoExtraStart(
        _serviceItems[index],
        variants,
      );
      _recalculateTimesFrom(index + 1, variants);
      _clearMidnightWarningIfResolved(variants.cast());
    });
  }

  void _recalculateTimesFrom(int fromIndex, List<ServiceVariant> variants) {
    if (fromIndex <= 0 || fromIndex >= _serviceItems.length) return;

    for (int i = fromIndex; i < _serviceItems.length; i++) {
      final prevItem = _serviceItems[i - 1];
      final prevEnd = _resolveServiceEndTime(prevItem, variants);
      final updated = _serviceItems[i].copyWith(startTime: prevEnd);
      _serviceItems[i] = _applyAutoExtraStart(updated, variants);
    }
  }

  TimeOfDay _resolveServiceEndTime(
    ServiceItemData item,
    List<ServiceVariant> variants,
  ) {
    final baseEnd = _baseEndTime(item, variants);
    if (item.blockedExtraMinutes <= 0) {
      return baseEnd;
    }
    return _addMinutes(baseEnd, item.blockedExtraMinutes);
  }

  ServiceItemData _applyAutoExtraStart(
    ServiceItemData item,
    List<ServiceVariant> variants,
  ) {
    return item;
  }

  TimeOfDay _baseEndTime(ServiceItemData item, List<ServiceVariant> variants) {
    final variant = _variantForItem(item, variants);
    final baseDuration = item.durationMinutes > 0
        ? item.durationMinutes
        : (variant?.durationMinutes ?? 30);
    return item.getEndTime(baseDuration);
  }

  ServiceVariant? _variantForItem(
    ServiceItemData item,
    List<ServiceVariant> variants,
  ) {
    if (item.serviceVariantId != null) {
      for (final v in variants) {
        if (v.id == item.serviceVariantId) return v;
      }
    }
    if (item.serviceId != null) {
      for (final v in variants) {
        if (v.serviceId == item.serviceId) return v;
      }
    }
    return null;
  }

  TimeOfDay _addMinutes(TimeOfDay time, int minutes) {
    final totalMinutes = time.hour * 60 + time.minute + minutes;
    return TimeOfDay(
      hour: (totalMinutes ~/ 60) % 24,
      minute: totalMinutes % 60,
    );
  }

  /// Trova lo staff migliore per un servizio:
  /// 1. Primo staff eligible disponibile
  /// 2. null per selezione manuale
  int? _findBestStaff(int serviceId) {
    final eligibleIds = ref.read(eligibleStaffForServiceProvider(serviceId));
    if (eligibleIds.isEmpty) return null;
    return eligibleIds.first;
  }

  Future<void> _pickDate() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return Dialog(
          child: CalendarDatePicker(
            initialDate: _date,
            firstDate: DateTime.now().subtract(const Duration(days: 365)),
            lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
            onDateChanged: (value) => Navigator.of(context).pop(value),
          ),
        );
      },
    );
    if (picked != null) {
      setState(() => _date = DateUtils.dateOnly(picked));
    }
  }

  void _scrollFormToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _onSave() async {
    if (!mounted) return;
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;

    // Verifica che ci sia almeno un servizio con dati completi
    final validItems = _serviceItems
        .where((item) => item.serviceId != null && item.staffId != null)
        .toList();

    if (validItems.isEmpty) {
      await FeedbackDialog.showError(
        context,
        title: l10n.errorTitle,
        message: l10n.atLeastOneServiceRequired,
      );
      return;
    }

    setState(() => _isSaving = true);

    final clientsById = ref.read(clientsByIdProvider);
    final bookingsNotifier = ref.read(bookingsProvider.notifier);
    final location = ref.read(currentLocationProvider);
    final repository = ref.read(bookingsRepositoryProvider);

    // Deriva il nome del cliente dal provider se _clientId è impostato
    final clientName = _clientId != null
        ? (clientsById[_clientId]?.name ?? _customClientName)
        : _customClientName;

    // Costruisci items per l'API (ogni servizio con il suo staff, start_time e override)
    final items = validItems.map((item) {
      final start = DateTime(
        _date.year,
        _date.month,
        _date.day,
        item.startTime.hour,
        item.startTime.minute,
      );
      return BookingItemRequest(
        serviceId: item.serviceId!,
        staffId: item.staffId!,
        startTime: start.toIso8601String(),
        // Include override values from ServiceItemData
        serviceVariantId: item.serviceVariantId,
        durationMinutes: item.durationMinutes,
        blockedExtraMinutes: item.blockedExtraMinutes > 0
            ? item.blockedExtraMinutes
            : null,
        processingExtraMinutes: item.processingExtraMinutes > 0
            ? item.processingExtraMinutes
            : null,
        // Prezzo personalizzato (se impostato)
        price: item.price,
      );
    }).toList();

    try {
      // UNA singola chiamata API per creare UN booking con tutti i servizi
      final bookingResponse = await repository.createBookingWithItems(
        locationId: location.id,
        idempotencyKey: const Uuid().v4(),
        items: items,
        clientId: _clientId,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      // Aggiorna booking metadata locale
      bookingsNotifier.ensureBooking(
        bookingId: bookingResponse.id,
        businessId: bookingResponse.businessId,
        locationId: bookingResponse.locationId,
        clientId: bookingResponse.clientId,
        clientName: bookingResponse.clientName ?? clientName,
      );

      // Refresh appointments per caricare i nuovi
      ref.invalidate(appointmentsProvider);
      await ref.read(appointmentsProvider.future);

      // Trova il primo appointment creato per lo scroll
      final currentList = ref.read(appointmentsProvider).value ?? [];
      final scrollTarget = currentList
          .where((a) => a.bookingId == bookingResponse.id)
          .firstOrNull;

      if (scrollTarget != null) {
        ref.read(agendaScrollRequestProvider.notifier).request(scrollTarget);
      }
    } catch (_) {
      if (mounted) {
        await FeedbackDialog.showError(
          context,
          title: l10n.errorTitle,
          message: l10n.errorTitle,
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }
}

// ============================================================================
// Helper Widgets
// ============================================================================

class _ClientItem {
  final int id;
  final String name;
  const _ClientItem(this.id, this.name);
}

/// Widget per la selezione del cliente con link cliccabile e hint
class _ClientSelectionField extends ConsumerWidget {
  const _ClientSelectionField({
    required this.clientId,
    required this.clientName,
    required this.clients,
    required this.onClientSelected,
    required this.onClientRemoved,
    required this.onOpenPicker,
  });

  final int? clientId;
  final String clientName;
  final List<Client> clients;
  final void Function(int? id, String name) onClientSelected;
  final VoidCallback onClientRemoved;
  final Future<void> Function()? onOpenPicker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final hasClient = clientId != null || clientName.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.formClient,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        if (hasClient)
          _SelectedClientTile(
            clientName: clientName,
            onTap: () => onOpenPicker?.call(),
            onRemove: onClientRemoved,
          )
        else
          InkWell(
            onTap: () => onOpenPicker?.call(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_add_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.addClientToAppointment,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 6),
        Text(
          l10n.clientOptionalHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Tile che mostra il cliente selezionato con opzione per rimuoverlo
class _SelectedClientTile extends StatelessWidget {
  const _SelectedClientTile({
    required this.clientName,
    required this.onTap,
    required this.onRemove,
  });

  final String clientName;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            StaffCircleAvatar(
              height: 32,
              color: theme.colorScheme.primary,
              isHighlighted: false,
              initials: clientName.isNotEmpty
                  ? initialsFromName(clientName, maxChars: 2)
                  : '?',
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                clientName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, size: 20, color: theme.colorScheme.error),
              onPressed: onRemove,
              tooltip: context.l10n.removeClient,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet per la selezione del cliente
class _ClientPickerSheet extends ConsumerStatefulWidget {
  const _ClientPickerSheet({required this.clients, this.selectedClientId});

  final List<Client> clients;
  final int? selectedClientId;

  @override
  ConsumerState<_ClientPickerSheet> createState() => _ClientPickerSheetState();
}

class _ClientPickerSheetState extends ConsumerState<_ClientPickerSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Client> get _filteredClients {
    final asyncClients = ref.watch(clientsProvider);
    final clients = (asyncClients.value ?? [])
        .where((c) => !c.isArchived)
        .toList();
    if (_searchQuery.isEmpty) return clients;
    final q = _searchQuery.toLowerCase();
    return clients.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final maxHeight = MediaQuery.of(context).size.height * 0.8;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.selectClientTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.formFirstRowSpacing),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l10n.searchClientPlaceholder,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value.trim());
                    },
                  ),
                ],
              ),
            ),
            const AppBottomSheetDivider(),
            // Quick actions
            ListTile(
              leading: StaffCircleAvatar(
                height: 32,
                color: theme.colorScheme.primary,
                isHighlighted: false,
                initials: '',
                child: Icon(
                  Icons.person_add_outlined,
                  color: theme.colorScheme.onSurface,
                  size: 18,
                ),
              ),
              title: Text(l10n.createNewClient),
              onTap: () {
                Navigator.of(context).pop(_ClientItem(-2, _searchQuery));
              },
            ),
            ListTile(
              leading: StaffCircleAvatar(
                height: 32,
                color: theme.colorScheme.onSurfaceVariant,
                isHighlighted: false,
                initials: '',
                child: Icon(
                  Icons.person_off_outlined,
                  color: theme.colorScheme.onSurface,
                  size: 18,
                ),
              ),
              title: Text(l10n.noClientForAppointment),
              onTap: () {
                Navigator.of(context).pop(const _ClientItem(-1, ''));
              },
            ),
            const AppBottomSheetDivider(),
            // Client list
            Flexible(
              child: _filteredClients.isEmpty
                  ? Center(
                      child: Text(
                        l10n.clientsEmpty,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: _filteredClients.length,
                      itemBuilder: (context, index) {
                        final client = _filteredClients[index];
                        final isSelected = client.id == widget.selectedClientId;
                        return ListTile(
                          leading: StaffCircleAvatar(
                            height: 32,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.primary,
                            isHighlighted: isSelected,
                            initials: client.name.isNotEmpty
                                ? initialsFromName(client.name, maxChars: 2)
                                : '?',
                          ),
                          title: Text(client.name),
                          subtitle: client.phone != null
                              ? Text(
                                  client.phone!,
                                  style: theme.textTheme.bodySmall,
                                )
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.edit_outlined,
                                  size: 20,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                onPressed: () async {
                                  await showClientEditDialog(
                                    context,
                                    ref,
                                    client: client,
                                  );
                                },
                                tooltip: l10n.clientsEdit,
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: theme.colorScheme.primary,
                                ),
                            ],
                          ),
                          onTap: () {
                            Navigator.of(
                              context,
                            ).pop(_ClientItem(client.id, client.name));
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
