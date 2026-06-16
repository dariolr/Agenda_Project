import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/form_factor_provider.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/models/location.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_dividers.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/labeled_form_field.dart';
import '../../../../core/widgets/local_loading_overlay.dart';
import '../../../agenda/providers/business_providers.dart';
import '../../../agenda/providers/location_providers.dart';
import '../../../auth/providers/auth_provider.dart';

Future<void> showLocationDialog(
  BuildContext context,
  WidgetRef ref, {
  Location? initial,
}) async {
  final formFactor = ref.read(formFactorProvider);
  final dialog = _LocationDialog(initial: initial);

  await AppForm.show(
    context: context,
    builder: (_) => dialog,
    formFactor: formFactor,
    useRootNavigator: true,
    padding: EdgeInsets.zero,
    heightFactor: AppForm.defaultBottomSheetHeightFactor,
  );
}

class _LocationDialog extends ConsumerStatefulWidget {
  const _LocationDialog({this.initial});

  final Location? initial;

  bool get isEditing => initial != null;

  @override
  ConsumerState<_LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends ConsumerState<_LocationDialog> {
  static const int _neverCancellationHours = 100000;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedCountryCode = 'IT';
  String _selectedTimezone = 'Europe/Rome';
  String? _selectedBookingDefaultLocale;
  final Map<String, TextEditingController> _nomenclatureControllers = {};
  final _maxBookingAdvanceDaysController = TextEditingController();
  bool _isActive = true;
  bool _onlineBookingEnabled = true;
  int _minBookingNoticeHours = 1;
  int _maxBookingAdvanceDays = 90;
  int? _cancellationHours;
  bool _allowCustomerChooseStaff = true;
  bool _allowMultiServiceBooking = true;
  bool _showPriceToCustomer = true;
  bool _showDurationToCustomer = true;
  String _staffIconKey = 'person';

  // Smart Slot Display Settings
  int _onlineBookingSlotIntervalMinutes = 15;
  String _slotDisplayMode = 'all';
  int _minGapMinutes = 30;

  // Opzioni disponibili per i dropdown
  static const _noticeHoursOptions = [1, 2, 4, 6, 12, 24, 48];
  static const List<int?> _cancellationHoursOptions = [
    null,
    0,
    1,
    2,
    4,
    8,
    12,
    24,
    48,
    72,
    96,
    120,
    168,
    _neverCancellationHours,
  ];

  String _formatCancellationPolicyValue(BuildContext context, int hours) {
    final l10n = context.l10n;
    if (hours == 0) {
      return l10n.teamLocationCancellationHoursAlways;
    }
    if (hours == _neverCancellationHours) {
      return l10n.teamLocationCancellationHoursNever;
    }
    if (hours >= 24 && hours % 24 == 0) {
      return l10n.teamLocationDays(hours ~/ 24);
    }
    return l10n.teamLocationHours(hours);
  }

  Widget _buildComboText(String text, {bool selected = false}) {
    return Tooltip(
      message: text,
      child: Text(
        text,
        maxLines: selected ? 1 : 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildSectionDivider(BuildContext context) {
    final bleed = ref.read(formFactorProvider) == AppFormFactor.desktop
        ? 20.0
        : 16.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Transform.translate(
          offset: Offset(-bleed, 0),
          child: SizedBox(
            width: constraints.maxWidth + (bleed * 2),
            child: const AppDivider(),
          ),
        );
      },
    );
  }

  String _fallbackTimezoneFromBusiness() {
    final businessTimezone = ref.read(currentBusinessProvider).timezone?.trim();
    if (businessTimezone != null && businessTimezone.isNotEmpty) {
      return businessTimezone;
    }

    final locations = ref.read(locationsProvider);
    for (final location in locations) {
      final timezone = location.timezone.trim();
      if (timezone.isNotEmpty) {
        return timezone;
      }
    }

    return 'Europe/Rome';
  }

  String _businessTimezoneOrDefault() {
    final tz = ref.read(currentBusinessProvider).timezone?.trim();
    if (tz != null && tz.isNotEmpty) {
      return tz;
    }
    return 'Europe/Rome';
  }

  String? _inferCountryFromTimezone(String timezone) {
    return switch (timezone.trim()) {
      'Europe/Rome' => 'IT',
      'Europe/Paris' => 'FR',
      'Europe/Madrid' || 'Atlantic/Canary' => 'ES',
      'Europe/Berlin' => 'DE',
      'Europe/London' => 'GB',
      'Europe/Zurich' => 'CH',
      'Europe/Vienna' => 'AT',
      'Europe/Lisbon' || 'Atlantic/Azores' || 'Atlantic/Madeira' => 'PT',
      'Europe/Amsterdam' => 'NL',
      'Europe/Brussels' => 'BE',
      'America/New_York' ||
      'America/Chicago' ||
      'America/Denver' ||
      'America/Los_Angeles' ||
      'America/Anchorage' ||
      'America/Adak' ||
      'Pacific/Honolulu' => 'US',
      _ => null,
    };
  }

  String _fallbackCountryFromBusiness() {
    final locations = ref.read(locationsProvider);
    for (final location in locations) {
      final country = location.country?.trim().toUpperCase();
      if (country != null && country.isNotEmpty) {
        return country;
      }
    }

    final inferred = _inferCountryFromTimezone(_fallbackTimezoneFromBusiness());
    return inferred ?? 'IT';
  }

  String _businessCountryOrDefault() {
    final inferred = _inferCountryFromTimezone(_businessTimezoneOrDefault());
    return inferred ?? 'IT';
  }

  List<String> _timezonesForCountry(String countryCode) {
    return _countryTimezones[countryCode] ?? const ['Europe/Rome'];
  }

  String _countryLabel(BuildContext context, String countryCode) {
    final l10n = context.l10n;
    return switch (countryCode) {
      'IT' => l10n.teamLocationCountryItaly,
      'FR' => l10n.teamLocationCountryFrance,
      'ES' => l10n.teamLocationCountrySpain,
      'DE' => l10n.teamLocationCountryGermany,
      'GB' => l10n.teamLocationCountryUnitedKingdom,
      'US' => l10n.teamLocationCountryUnitedStates,
      'CH' => l10n.teamLocationCountrySwitzerland,
      'AT' => l10n.teamLocationCountryAustria,
      'PT' => l10n.teamLocationCountryPortugal,
      'NL' => l10n.teamLocationCountryNetherlands,
      'BE' => l10n.teamLocationCountryBelgium,
      _ => countryCode,
    };
  }

  static final List<int> _onlineBookingSlotIntervalOptions = [
    for (int minutes = 5; minutes <= 120; minutes += 5) minutes,
  ];
  static final List<int> _minGapOptions = [
    for (int minutes = 5; minutes <= 120; minutes += 5) minutes,
  ];
  static const List<String> _allowedNomenclatureKeys = [
    'location_step_label',
    'services_step_label',
    'staff_step_label',
    'location_title',
    'location_subtitle',
    'location_empty',
    'services_title',
    'services_subtitle',
    'services_empty_title',
    'services_empty_subtitle',
    'services_selected_none',
    'services_selected_one',
    'summary_services_label',
    'tab_services',
    'tab_events',
    'events_step_label',
    'services_events_step_label',
    'services_events_title',
    'services_events_subtitle',
    'events_title',
    'events_subtitle',
    'events_empty_title',
    'events_empty_subtitle',
    'events_selected_none',
    'summary_event_label',
    'event_group_label',
    'event_full',
    'event_spots_left',
    'event_spots_available',
    'event_waitlist_label',
    'event_join_waitlist_label',
    'event_waitlist_dialog_title',
    'event_waitlist_dialog_message',
    'event_waitlist_dialog_confirm',
    'event_waitlist_notice',
    'event_already_booked',
    'event_already_waitlisted',
    'event_manage_booking',
    'tab_conflict_events_title',
    'tab_conflict_events_subtitle',
    'tab_conflict_services_title',
    'tab_conflict_services_subtitle',
    'staff_label',
    'staff_title',
    'staff_subtitle',
    'staff_any_label',
    'staff_any_subtitle',
    'staff_empty',
    'no_staff_for_services',
    'error_invalid_service',
    'error_invalid_staff',
    'error_invalid_location',
    'error_staff_unavailable',
    'error_missing_services',
    'error_service_unavailable',
  ];

  static const List<String> _nomenclatureFieldOrder = _allowedNomenclatureKeys;
  static const List<String> _staffIconKeys = [
    'person',
    'door',
    'team',
    'tennis',
    'soccer',
    'resource',
    'room',
    'court',
    'equipment',
    'wellness',
    'medical',
    'beauty',
    'education',
    'pet',
    'generic',
  ];
  static const Map<String, List<String>> _countryTimezones = {
    'IT': ['Europe/Rome'],
    'FR': ['Europe/Paris'],
    'ES': ['Europe/Madrid', 'Atlantic/Canary'],
    'DE': ['Europe/Berlin'],
    'GB': ['Europe/London'],
    'US': [
      'America/New_York',
      'America/Chicago',
      'America/Denver',
      'America/Los_Angeles',
      'America/Anchorage',
      'America/Adak',
      'Pacific/Honolulu',
    ],
    'CH': ['Europe/Zurich'],
    'AT': ['Europe/Vienna'],
    'PT': ['Europe/Lisbon', 'Atlantic/Azores', 'Atlantic/Madeira'],
    'NL': ['Europe/Amsterdam'],
    'BE': ['Europe/Brussels'],
  };

  IconData _staffIconForKey(String key) {
    switch (key) {
      case 'person':
        return Icons.person;
      case 'door':
        return Icons.meeting_room_outlined;
      case 'team':
        return Icons.groups_outlined;
      case 'tennis':
        return Icons.sports_tennis_outlined;
      case 'soccer':
        return Icons.sports_soccer_outlined;
      case 'resource':
        return Icons.category_outlined;
      case 'room':
        return Icons.fitness_center_outlined;
      case 'court':
        return Icons.sports_tennis_outlined;
      case 'equipment':
        return Icons.handyman_outlined;
      case 'wellness':
        return Icons.spa_outlined;
      case 'medical':
        return Icons.medical_services_outlined;
      case 'beauty':
        return Icons.auto_awesome_outlined;
      case 'education':
        return Icons.school_outlined;
      case 'pet':
        return Icons.pets_outlined;
      case 'generic':
        return Icons.widgets_outlined;
      default:
        return Icons.person;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _nameController.text = widget.initial!.name;
      _addressController.text = widget.initial!.address ?? '';
      _selectedCountryCode =
          (widget.initial!.country?.trim().isNotEmpty ?? false)
          ? widget.initial!.country!.trim().toUpperCase()
          : _fallbackCountryFromBusiness();
      _selectedTimezone = widget.initial!.timezone.trim().isNotEmpty
          ? widget.initial!.timezone.trim()
          : _fallbackTimezoneFromBusiness();
      final allowedTimezones = _timezonesForCountry(_selectedCountryCode);
      if (!allowedTimezones.contains(_selectedTimezone)) {
        _selectedTimezone = allowedTimezones.first;
      }
      final isSuperadmin = ref.read(authProvider).user?.isSuperadmin ?? false;
      if (!isSuperadmin) {
        _selectedTimezone = _businessTimezoneOrDefault();
        _selectedCountryCode = _businessCountryOrDefault();
      }
      final initialBookingLocale = widget.initial!.bookingDefaultLocale
          ?.trim()
          .toLowerCase();
      _selectedBookingDefaultLocale =
          (initialBookingLocale == 'it' || initialBookingLocale == 'en')
          ? initialBookingLocale
          : null;
      _emailController.text = widget.initial!.email ?? '';
      final defaultMap = widget.initial!.bookingTextOverrides?['default'];
      for (final key in _nomenclatureFieldOrder) {
        _nomenclatureControllers[key] = TextEditingController(
          text: defaultMap?[key] ?? '',
        );
      }
      // Retrocompatibilità: se esiste il vecchio campo "services_selected_many"
      // ma il nuovo campo unico è vuoto, riusa il suo valore.
      final legacyMany = defaultMap?['services_selected_many']?.trim();
      final summaryCtrl = _nomenclatureControllers['summary_services_label'];
      if (summaryCtrl != null &&
          summaryCtrl.text.trim().isEmpty &&
          legacyMany != null &&
          legacyMany.isNotEmpty) {
        summaryCtrl.text = legacyMany;
      }
      _isActive = widget.initial!.isActive;
      _onlineBookingEnabled = widget.initial!.onlineBookingEnabled;
      _minBookingNoticeHours = widget.initial!.minBookingNoticeHours;
      _maxBookingAdvanceDays = widget.initial!.maxBookingAdvanceDays;
      _maxBookingAdvanceDaysController.text = _maxBookingAdvanceDays.toString();
      _cancellationHours = widget.initial!.cancellationHours;
      _allowCustomerChooseStaff = widget.initial!.allowCustomerChooseStaff;
      _allowMultiServiceBooking = widget.initial!.allowMultiServiceBooking;
      _showPriceToCustomer = widget.initial!.showPriceToCustomer;
      _showDurationToCustomer = widget.initial!.showDurationToCustomer;
      _staffIconKey = widget.initial!.staffIconKey;
      _onlineBookingSlotIntervalMinutes =
          widget.initial!.onlineBookingSlotIntervalMinutes;
      _slotDisplayMode = widget.initial!.slotDisplayMode;
      _minGapMinutes = widget.initial!.minGapMinutes;
    } else {
      // Nuova sede: nome volutamente vuoto (campo obbligatorio).
      _nameController.text = '';

      // Se esistono già sedi, usa come default i valori dell'ultima sede creata.
      final existingLocations = ref.read(locationsProvider);
      final lastLocation = existingLocations.isEmpty
          ? null
          : existingLocations.reduce((a, b) => a.id > b.id ? a : b);

      final defaultMap = lastLocation?.bookingTextOverrides?['default'];
      for (final key in _nomenclatureFieldOrder) {
        _nomenclatureControllers[key] = TextEditingController(
          text: defaultMap?[key] ?? '',
        );
      }

      if (lastLocation != null) {
        _selectedCountryCode =
            (lastLocation.country?.trim().isNotEmpty ?? false)
            ? lastLocation.country!.trim().toUpperCase()
            : _fallbackCountryFromBusiness();
        _selectedTimezone = lastLocation.timezone.trim().isNotEmpty
            ? lastLocation.timezone.trim()
            : _fallbackTimezoneFromBusiness();
        final allowedTimezones = _timezonesForCountry(_selectedCountryCode);
        if (!allowedTimezones.contains(_selectedTimezone)) {
          _selectedTimezone = allowedTimezones.first;
        }
        final isSuperadmin = ref.read(authProvider).user?.isSuperadmin ?? false;
        if (!isSuperadmin) {
          _selectedTimezone = _businessTimezoneOrDefault();
          _selectedCountryCode = _businessCountryOrDefault();
        }
        final lastBookingLocale = lastLocation.bookingDefaultLocale
            ?.trim()
            .toLowerCase();
        _selectedBookingDefaultLocale =
            (lastBookingLocale == 'it' || lastBookingLocale == 'en')
            ? lastBookingLocale
            : null;
        _isActive = lastLocation.isActive;
        _onlineBookingEnabled = lastLocation.onlineBookingEnabled;
        _minBookingNoticeHours = lastLocation.minBookingNoticeHours;
        _maxBookingAdvanceDays = lastLocation.maxBookingAdvanceDays;
        _maxBookingAdvanceDaysController.text = _maxBookingAdvanceDays
            .toString();
        _cancellationHours = lastLocation.cancellationHours;
        _allowCustomerChooseStaff = lastLocation.allowCustomerChooseStaff;
        _allowMultiServiceBooking = lastLocation.allowMultiServiceBooking;
        _showPriceToCustomer = lastLocation.showPriceToCustomer;
        _showDurationToCustomer = lastLocation.showDurationToCustomer;
        _staffIconKey = lastLocation.staffIconKey;
        _onlineBookingSlotIntervalMinutes =
            lastLocation.onlineBookingSlotIntervalMinutes;
        _slotDisplayMode = lastLocation.slotDisplayMode;
        _minGapMinutes = lastLocation.minGapMinutes;
      } else {
        _selectedCountryCode = _fallbackCountryFromBusiness();
        _selectedTimezone = _fallbackTimezoneFromBusiness();
        final allowedTimezones = _timezonesForCountry(_selectedCountryCode);
        if (!allowedTimezones.contains(_selectedTimezone)) {
          _selectedTimezone = allowedTimezones.first;
        }
        final isSuperadmin = ref.read(authProvider).user?.isSuperadmin ?? false;
        if (!isSuperadmin) {
          _selectedTimezone = _businessTimezoneOrDefault();
          _selectedCountryCode = _businessCountryOrDefault();
        }
        _selectedBookingDefaultLocale = null;
        _maxBookingAdvanceDaysController.text = _maxBookingAdvanceDays
            .toString();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _maxBookingAdvanceDaysController.dispose();
    for (final controller in _nomenclatureControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isSuperadmin = ref.watch(
      authProvider.select((s) => s.user?.isSuperadmin ?? false),
    );
    final currentBusiness = ref.watch(currentBusinessProvider);
    final businessNotificationEmail = currentBusiness
        .onlineBookingsNotificationEmail
        ?.trim();
    final hasBusinessNotificationEmail =
        businessNotificationEmail != null &&
        businessNotificationEmail.isNotEmpty;
    final locationEmailHint = hasBusinessNotificationEmail
        ? businessNotificationEmail
        : l10n.teamLocationEmailHint;
    final isLocationEmailEmpty = _emailController.text.trim().isEmpty;
    final locationEmailLabel =
        isLocationEmailEmpty && !hasBusinessNotificationEmail
        ? l10n.teamLocationEmailLabel
        : l10n.teamLocationEmailHint;
    final title = widget.isEditing
        ? l10n.teamEditLocationTitle
        : l10n.teamNewLocationTitle;

    final actions = [
      AppOutlinedActionButton(
        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        padding: AppButtonStyles.dialogButtonPadding,
        child: Text(l10n.actionCancel),
      ),
      AppFilledButton(
        onPressed: _isLoading ? null : _onSave,
        padding: AppButtonStyles.dialogButtonPadding,
        child: Text(l10n.actionSave),
      ),
    ];

    final bottomActions = actions
        .map(
          (a) => SizedBox(width: AppButtonStyles.dialogButtonWidth, child: a),
        )
        .toList();

    final nameField = LabeledFormField(
      label: l10n.teamLocationNameLabel,
      child: TextFormField(
        controller: _nameController,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
        ),
        validator: (v) =>
            v == null || v.trim().isEmpty ? l10n.validationRequired : null,
      ),
    );

    final addressField = LabeledFormField(
      label: l10n.teamLocationAddressLabel,
      child: TextFormField(
        controller: _addressController,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );

    final countryField = LabeledFormField(
      label: l10n.teamLocationCountryLabel,
      child: DropdownButtonFormField<String>(
        value: _selectedCountryCode,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
        ),
        items: _countryTimezones.keys
            .map(
              (code) => DropdownMenuItem(
                value: code,
                child: Text('${_countryLabel(context, code)} ($code)'),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value == null) return;
          setState(() {
            _selectedCountryCode = value;
            final allowedTimezones = _timezonesForCountry(value);
            if (!allowedTimezones.contains(_selectedTimezone)) {
              _selectedTimezone = allowedTimezones.first;
            }
          });
        },
      ),
    );

    final timezoneField = LabeledFormField(
      label: l10n.teamLocationTimezoneLabel,
      child: DropdownButtonFormField<String>(
        value: _selectedTimezone,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
        ),
        items: _timezonesForCountry(
          _selectedCountryCode,
        ).map((tz) => DropdownMenuItem(value: tz, child: Text(tz))).toList(),
        onChanged: (value) {
          if (value == null) return;
          setState(() => _selectedTimezone = value);
        },
      ),
    );

    final bookingDefaultLocaleField = LabeledFormField(
      label: l10n.teamLocationBookingDefaultLocaleLabel,
      child: DropdownButtonFormField<String?>(
        value: _selectedBookingDefaultLocale,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          isDense: true,
          helperText: l10n.teamLocationBookingDefaultLocaleHint,
        ),
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: Text(l10n.teamLocationBookingDefaultLocaleAuto),
          ),
          DropdownMenuItem<String?>(
            value: 'it',
            child: Text(l10n.teamLocationBookingDefaultLocaleItalian),
          ),
          DropdownMenuItem<String?>(
            value: 'en',
            child: Text(l10n.teamLocationBookingDefaultLocaleEnglish),
          ),
        ],
        onChanged: (value) {
          setState(() => _selectedBookingDefaultLocale = value);
        },
      ),
    );

    final emailField = LabeledFormField(
      label: locationEmailLabel,
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          isDense: true,
          hintText: locationEmailHint,
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return null; // Optional
          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
          if (!emailRegex.hasMatch(v.trim())) {
            return l10n.validationInvalidEmail;
          }
          return null;
        },
      ),
    );

    final content = Form(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          nameField,
          const SizedBox(height: AppSpacing.formRowSpacing),
          addressField,
          if (isSuperadmin) ...[
            const SizedBox(height: AppSpacing.formRowSpacing),
            countryField,
            const SizedBox(height: AppSpacing.formRowSpacing),
            timezoneField,
          ],
          const SizedBox(height: AppSpacing.formRowSpacing),
          emailField,
          const SizedBox(height: AppSpacing.formRowSpacing),
          _buildSectionDivider(context),
          const SizedBox(height: AppSpacing.formRowSpacing),
          Text(
            l10n.teamLocationOnlineBookingSettingsSection,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            title: Text(l10n.teamLocationOnlineBookingEnabledLabel),
            subtitle: Text(
              l10n.teamLocationOnlineBookingEnabledHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            value: _onlineBookingEnabled,
            onChanged: (v) => setState(() => _onlineBookingEnabled = v),
            contentPadding: EdgeInsets.zero,
          ),
          if (_onlineBookingEnabled) ...[
            if (isSuperadmin) ...[
              const SizedBox(height: AppSpacing.formRowSpacing),
              bookingDefaultLocaleField,
            ],
            const SizedBox(height: AppSpacing.formRowSpacing),
            // Sezione Limiti Prenotazione Online
            Text(
              l10n.teamLocationBookingLimitsSection,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              title: Text(l10n.teamLocationAllowCustomerChooseStaffLabel),
              subtitle: Text(
                l10n.teamLocationAllowCustomerChooseStaffHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              value: _allowCustomerChooseStaff,
              onChanged: (v) => setState(() => _allowCustomerChooseStaff = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 4),
            SwitchListTile.adaptive(
              title: Text(l10n.teamLocationAllowMultiServiceBookingLabel),
              subtitle: Text(
                l10n.teamLocationAllowMultiServiceBookingHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              value: _allowMultiServiceBooking,
              onChanged: (v) => setState(() => _allowMultiServiceBooking = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 4),
            SwitchListTile.adaptive(
              title: Text(l10n.locationShowPriceToCustomerLabel),
              subtitle: Text(
                l10n.locationShowPriceToCustomerHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              value: _showPriceToCustomer,
              onChanged: (v) => setState(() => _showPriceToCustomer = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 4),
            SwitchListTile.adaptive(
              title: Text(l10n.locationShowDurationToCustomerLabel),
              subtitle: Text(
                l10n.locationShowDurationToCustomerHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              value: _showDurationToCustomer,
              onChanged: (v) => setState(() => _showDurationToCustomer = v),
              contentPadding: EdgeInsets.zero,
            ),
            if (_allowCustomerChooseStaff) ...[
              const SizedBox(height: AppSpacing.formRowSpacing),
              if (isSuperadmin)
                LabeledFormField(
                  label: l10n.teamLocationStaffIconKeyLabel,
                  child: DropdownButtonFormField<String>(
                    value: _staffIconKey,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      isDense: true,
                      helperText: l10n.teamLocationStaffIconKeyHint,
                    ),
                    items: _staffIconKeys
                        .map(
                          (key) => DropdownMenuItem<String>(
                            value: key,
                            child: Center(
                              child: Icon(_staffIconForKey(key), size: 20),
                            ),
                          ),
                        )
                        .toList(),
                    selectedItemBuilder: (context) {
                      return _staffIconKeys
                          .map(
                            (key) => Align(
                              alignment: Alignment.centerLeft,
                              child: Icon(_staffIconForKey(key), size: 20),
                            ),
                          )
                          .toList();
                    },
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _staffIconKey = value);
                      }
                    },
                  ),
                ),
            ],
            const SizedBox(height: AppSpacing.formRowSpacing),
            // Preavviso minimo
            LabeledFormField(
              label: l10n.teamLocationMinBookingNoticeLabel,
              child: DropdownButtonFormField<int>(
                value: _minBookingNoticeHours,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  helperText: l10n.teamLocationMinBookingNoticeHint,
                ),
                items: _noticeHoursOptions.map((hours) {
                  return DropdownMenuItem(
                    value: hours,
                    child: Text(l10n.teamLocationHours(hours)),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _minBookingNoticeHours = v);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.formRowSpacing),
            // Anticipo massimo
            LabeledFormField(
              label: l10n.teamLocationMaxBookingAdvanceLabel,
              child: TextFormField(
                controller: _maxBookingAdvanceDaysController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  helperText: l10n.teamLocationMaxBookingAdvanceHint,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return l10n.validationInvalidNumber;
                  return null;
                },
                onChanged: (v) {
                  final n = int.tryParse(v);
                  if (n != null && n > 0) {
                    setState(() => _maxBookingAdvanceDays = n);
                  }
                },
              ),
            ),
            const SizedBox(height: AppSpacing.formRowSpacing),
            LabeledFormField(
              label: l10n.teamLocationCancellationHoursLabel,
              child: DropdownButtonFormField<int?>(
                value: _cancellationHours,
                isExpanded: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  helperText: l10n.teamLocationCancellationHoursHint,
                ),
                items: _cancellationHoursOptions.map((hours) {
                  String label;
                  if (hours == null) {
                    final businessCancellationHours = ref
                        .read(currentBusinessProvider)
                        .cancellationHours;
                    if (businessCancellationHours != null) {
                      final businessPolicy = _formatCancellationPolicyValue(
                        context,
                        businessCancellationHours,
                      );
                      label = l10n
                          .teamLocationCancellationHoursUseBusinessWithValue(
                            businessPolicy,
                          );
                    } else {
                      label = l10n.teamLocationCancellationHoursUseBusiness;
                    }
                  } else if (hours == 0) {
                    label = l10n.teamLocationCancellationHoursAlways;
                  } else if (hours == _neverCancellationHours) {
                    label = l10n.teamLocationCancellationHoursNever;
                  } else if (hours >= 24 && hours % 24 == 0) {
                    label = l10n.teamLocationDays(hours ~/ 24);
                  } else {
                    label = l10n.teamLocationHours(hours);
                  }
                  return DropdownMenuItem<int?>(
                    value: hours,
                    child: _buildComboText(label),
                  );
                }).toList(),
                selectedItemBuilder: (context) {
                  return _cancellationHoursOptions.map((hours) {
                    String label;
                    if (hours == null) {
                      final businessCancellationHours = ref
                          .read(currentBusinessProvider)
                          .cancellationHours;
                      if (businessCancellationHours != null) {
                        final businessPolicy = _formatCancellationPolicyValue(
                          context,
                          businessCancellationHours,
                        );
                        label = l10n
                            .teamLocationCancellationHoursUseBusinessWithValue(
                              businessPolicy,
                            );
                      } else {
                        label = l10n.teamLocationCancellationHoursUseBusiness;
                      }
                    } else if (hours == 0) {
                      label = l10n.teamLocationCancellationHoursAlways;
                    } else if (hours == _neverCancellationHours) {
                      label = l10n.teamLocationCancellationHoursNever;
                    } else if (hours >= 24 && hours % 24 == 0) {
                      label = l10n.teamLocationDays(hours ~/ 24);
                    } else {
                      label = l10n.teamLocationHours(hours);
                    }
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: _buildComboText(label, selected: true),
                    );
                  }).toList();
                },
                onChanged: (v) {
                  setState(() => _cancellationHours = v);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.formRowSpacing),
            _buildSectionDivider(context),
            const SizedBox(height: AppSpacing.formRowSpacing),
            // Sezione Smart Slot Display
            Text(
              l10n.teamLocationSmartSlotSection,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.teamLocationSmartSlotDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            // Intervallo slot
            LabeledFormField(
              label: l10n.teamLocationSlotIntervalLabel,
              child: DropdownButtonFormField<int>(
                value: _onlineBookingSlotIntervalMinutes,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  helperText: l10n.teamLocationSlotIntervalHint,
                ),
                items: _onlineBookingSlotIntervalOptions.map((minutes) {
                  return DropdownMenuItem(
                    value: minutes,
                    child: Text(l10n.teamLocationMinutes(minutes)),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _onlineBookingSlotIntervalMinutes = v);
                  }
                },
              ),
            ),
            const SizedBox(height: AppSpacing.formRowSpacing),
            // Modalità visualizzazione slot
            LabeledFormField(
              label: l10n.teamLocationSlotDisplayModeLabel,
              child: DropdownButtonFormField<String>(
                value: _slotDisplayMode,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  helperText: _slotDisplayMode == 'all'
                      ? l10n.teamLocationSlotDisplayModeAllHint
                      : l10n.teamLocationSlotDisplayModeMinGapHint,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'all',
                    child: Text(l10n.teamLocationSlotDisplayModeAll),
                  ),
                  DropdownMenuItem(
                    value: 'min_gap',
                    child: Text(l10n.teamLocationSlotDisplayModeMinGap),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _slotDisplayMode = v);
                },
              ),
            ),
            // Gap minimo (visibile solo se min_gap mode)
            if (_slotDisplayMode == 'min_gap') ...[
              const SizedBox(height: AppSpacing.formRowSpacing),
              LabeledFormField(
                label: l10n.teamLocationMinGapLabel,
                child: DropdownButtonFormField<int>(
                  value: _minGapMinutes,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    isDense: true,
                    helperText: l10n.teamLocationMinGapHint,
                  ),
                  items: _minGapOptions.map((minutes) {
                    return DropdownMenuItem(
                      value: minutes,
                      child: Text(l10n.teamLocationMinutes(minutes)),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _minGapMinutes = v);
                  },
                ),
              ),
            ],
            if (isSuperadmin) ...[
              const SizedBox(height: AppSpacing.formRowSpacing),
              _buildSectionDivider(context),
              const SizedBox(height: AppSpacing.formRowSpacing),
              Text(
                l10n.teamLocationNomenclatureSection,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.teamLocationNomenclatureEditorIntro,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              ..._nomenclatureFieldOrder.map((key) {
                final controller = _nomenclatureControllers[key]!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: controller,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      isDense: true,
                      hintText: _nomenclatureDefaultHint(context, key),
                      hintStyle: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.45),
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: AppSpacing.formRowSpacing),
            ],
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.formRowSpacing),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );

    if (ref.read(formFactorProvider) == AppFormFactor.desktop) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 600, maxWidth: 720),
          child: LocalLoadingOverlay(
            isLoading: _isLoading,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  Flexible(child: SingleChildScrollView(child: content)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      for (int i = 0; i < bottomActions.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        bottomActions[i],
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
          return LocalLoadingOverlay(
            isLoading: _isLoading,
            child: SizedBox(
              height: constraints.maxHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 12,
                          bottom: 0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            content,
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!isKeyboardOpen) ...[
                    const AppDivider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Align(
                        alignment: bottomActions.length == 3
                            ? Alignment.center
                            : Alignment.centerRight,
                        child: Wrap(
                          alignment: bottomActions.length == 3
                              ? WrapAlignment.center
                              : WrapAlignment.end,
                          spacing: 8,
                          runSpacing: 8,
                          children: bottomActions,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isLoading = false;
  String? _error;

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final notifier = ref.read(locationsProvider.notifier);
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final isSuperadmin = ref.read(authProvider).user?.isSuperadmin ?? false;
    final rawCountry = _selectedCountryCode.trim().toUpperCase();
    final country = isSuperadmin
        ? (rawCountry.isEmpty ? _fallbackCountryFromBusiness() : rawCountry)
        : _businessCountryOrDefault();
    final rawTimezone = _selectedTimezone.trim();
    final timezone = isSuperadmin
        ? (rawTimezone.isEmpty ? _fallbackTimezoneFromBusiness() : rawTimezone)
        : _businessTimezoneOrDefault();
    final bookingDefaultLocale = isSuperadmin
        ? _selectedBookingDefaultLocale?.trim().toLowerCase()
        : null;
    final email = _emailController.text.trim();
    final bookingTextOverrides = isSuperadmin
        ? _buildBookingTextOverrides(context.l10n)
        : null;
    if (isSuperadmin && bookingTextOverrides == null && _error != null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      if (widget.initial != null) {
        // Aggiorna location esistente
        await notifier.updateLocation(
          locationId: widget.initial!.id,
          name: name,
          address: address.isEmpty ? null : address,
          country: country,
          email: email.isEmpty ? null : email,
          timezone: timezone,
          bookingDefaultLocale: bookingDefaultLocale,
          isActive: _isActive,
          onlineBookingEnabled: _onlineBookingEnabled,
          minBookingNoticeHours: _minBookingNoticeHours,
          maxBookingAdvanceDays: _maxBookingAdvanceDays,
          bookingTextOverrides: bookingTextOverrides,
          staffIconKey: isSuperadmin ? _staffIconKey : null,
          cancellationHours: _cancellationHours,
          allowCustomerChooseStaff: _allowCustomerChooseStaff,
          allowMultiServiceBooking: _allowMultiServiceBooking,
          showPriceToCustomer: _showPriceToCustomer,
          showDurationToCustomer: _showDurationToCustomer,
          onlineBookingSlotIntervalMinutes: _onlineBookingSlotIntervalMinutes,
          slotDisplayMode: _slotDisplayMode,
          minGapMinutes: _minGapMinutes,
        );
      } else {
        // Crea nuova location
        await notifier.create(
          name: name,
          address: address.isEmpty ? null : address,
          country: country,
          email: email.isEmpty ? null : email,
          timezone: timezone,
          bookingDefaultLocale: bookingDefaultLocale,
          isActive: _isActive,
          onlineBookingEnabled: _onlineBookingEnabled,
          minBookingNoticeHours: _minBookingNoticeHours,
          maxBookingAdvanceDays: _maxBookingAdvanceDays,
          bookingTextOverrides: bookingTextOverrides,
          staffIconKey: isSuperadmin ? _staffIconKey : null,
          cancellationHours: _cancellationHours,
          allowCustomerChooseStaff: _allowCustomerChooseStaff,
          allowMultiServiceBooking: _allowMultiServiceBooking,
          showPriceToCustomer: _showPriceToCustomer,
          showDurationToCustomer: _showDurationToCustomer,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic>? _buildBookingTextOverrides(L10n l10n) {
    final normalized = <String, String>{};
    for (final entry in _nomenclatureControllers.entries) {
      final key = entry.key;
      final rawValue = entry.value.text;
      if (rawValue.trim().isEmpty) {
        continue;
      }
      // Preserve operator-entered casing exactly as typed.
      normalized[key] = rawValue;
    }

    if (normalized.isEmpty) {
      return null;
    }

    return {'default': normalized};
  }

  static const Map<String, Map<String, String>>
  _nomenclatureDefaultHintsByLanguage = {
    'it': {
      'location_step_label': 'Sede',
      'services_step_label': 'Servizi',
      'staff_step_label': '{staffLabel}',
      'location_title': 'Scegli la sede',
      'location_subtitle': 'Seleziona dove vuoi effettuare la prenotazione',
      'location_empty': 'Nessuna sede disponibile',
      'services_title': 'Scegli i servizi',
      'services_subtitle': 'Puoi selezionare uno o più servizi',
      'services_empty_title': 'Nessun servizio disponibile al momento',
      'services_empty_subtitle':
          'Non ci sono servizi prenotabili online per questa attività',
      'services_selected_none': 'Nessun servizio selezionato',
      'services_selected_one': '1 servizio selezionato',
      'summary_services_label': 'Servizi selezionati',
      'tab_services': 'Servizi',
      'tab_events': 'Eventi',
      'events_step_label': 'Eventi',
      'services_events_step_label': 'Servizi / eventi',
      'services_events_title': 'Scegli un servizio o un evento',
      'services_events_subtitle':
          'Seleziona un servizio o iscriviti a un evento di gruppo',
      'events_title': 'Scegli un evento',
      'events_subtitle': "Seleziona l'evento a cui vuoi partecipare",
      'events_empty_title': 'Nessun evento disponibile',
      'events_empty_subtitle':
          'Non ci sono eventi di gruppo programmati al momento.',
      'events_selected_none': 'Seleziona un evento',
      'summary_event_label': 'Evento selezionato',
      'event_group_label': 'Evento di gruppo',
      'event_full': 'Completo',
      'event_spots_left': '{count} posti',
      'event_spots_available': '{count} posti disponibili',
      'event_waitlist_label': "Lista d'attesa",
      'event_join_waitlist_label': "Iscriviti in lista d'attesa",
      'event_waitlist_dialog_title': 'Evento al completo',
      'event_waitlist_dialog_message':
          "Questo evento è al completo. Vuoi iscriverti alla lista d'attesa?",
      'event_waitlist_dialog_confirm': 'Iscriviti',
      'event_waitlist_notice': "Sarai aggiunto alla lista d'attesa",
      'event_already_booked': 'Già prenotato',
      'event_already_waitlisted': "Già in lista d'attesa",
      'event_manage_booking': 'Gestisci prenotazione',
      'tab_conflict_events_title': 'Evento non selezionabile',
      'tab_conflict_events_subtitle':
          'Hai già selezionato uno o più servizi. Una prenotazione può includere servizi oppure un evento di gruppo, non entrambi. Deseleziona i servizi per scegliere un evento.',
      'tab_conflict_services_title': 'Servizi non selezionabili',
      'tab_conflict_services_subtitle':
          'Hai già selezionato l\'evento "{eventName}". Una prenotazione può includere servizi oppure un evento di gruppo, non entrambi. Deseleziona l\'evento per scegliere i servizi.',
      'staff_label': 'Operatore',
      'staff_title': 'Scegli {staffLabel}',
      'staff_subtitle': 'Seleziona con chi desideri essere servito',
      'staff_any_label': 'Qualsiasi fornitore dei servizi disponibile',
      'staff_any_subtitle':
          'Ti assegneremo il primo fornitore dei servizi libero',
      'staff_empty': 'Nessun fornitore dei servizi disponibile al momento',
      'no_staff_for_services':
          'Nessun fornitore dei servizi può eseguire tutti i servizi selezionati. Prova a selezionare meno servizi o servizi diversi.',
      'error_invalid_service':
          'Uno o più servizi selezionati non sono disponibili',
      'error_invalid_staff':
          'Il fornitore dei servizi selezionato non è disponibile per questi servizi',
      'error_invalid_location': 'La sede selezionata non è disponibile',
      'error_staff_unavailable':
          'Il fornitore dei servizi selezionato non è disponibile in questo orario',
      'error_missing_services':
          'Impossibile recuperare i servizi della prenotazione',
      'error_service_unavailable': 'Servizio temporaneamente non disponibile',
    },
    'en': {
      'location_step_label': 'Location',
      'services_step_label': 'Services',
      'staff_step_label': '{staffLabel}',
      'location_title': 'Choose location',
      'location_subtitle': 'Select where you want to book',
      'location_empty': 'No location available',
      'services_title': 'Choose services',
      'services_subtitle': 'You can select one or more services',
      'services_empty_title': 'No services available at the moment',
      'services_empty_subtitle':
          'There are no services available for online booking at this business',
      'services_selected_none': 'No service selected',
      'services_selected_one': '1 service selected',
      'summary_services_label': 'Selected services',
      'tab_services': 'Services',
      'tab_events': 'Events',
      'events_step_label': 'Events',
      'services_events_step_label': 'Services / events',
      'services_events_title': 'Choose a service or event',
      'services_events_subtitle': 'Select a service or join a group event',
      'events_title': 'Choose an event',
      'events_subtitle': 'Select the event you want to attend',
      'events_empty_title': 'No events available',
      'events_empty_subtitle':
          'There are no group events scheduled at the moment.',
      'events_selected_none': 'Select an event',
      'summary_event_label': 'Selected event',
      'event_group_label': 'Group event',
      'event_full': 'Full',
      'event_spots_left': '{count} spots',
      'event_spots_available': '{count} spots available',
      'event_waitlist_label': 'Waitlist',
      'event_join_waitlist_label': 'Join waitlist',
      'event_waitlist_dialog_title': 'Event is full',
      'event_waitlist_dialog_message':
          'This event is full. Would you like to join the waitlist?',
      'event_waitlist_dialog_confirm': 'Join waitlist',
      'event_waitlist_notice': 'You\'ll be added to the waitlist',
      'event_already_booked': 'Already booked',
      'event_already_waitlisted': 'Already on waitlist',
      'event_manage_booking': 'Manage booking',
      'tab_conflict_events_title': 'Event not selectable',
      'tab_conflict_events_subtitle':
          'You\'ve already selected one or more services. A booking can include either services or a group event, not both. Deselect the services to choose an event.',
      'tab_conflict_services_title': 'Services not selectable',
      'tab_conflict_services_subtitle':
          'You\'ve already selected the event "{eventName}". A booking can include either services or a group event, not both. Deselect the event to choose services.',
      'staff_label': 'Staff member',
      'staff_title': 'Choose {staffLabel}',
      'staff_subtitle': 'Select who you want to be served by',
      'staff_any_label': 'Any available service provider',
      'staff_any_subtitle':
          'We\'ll assign you the first available service provider',
      'staff_empty': 'No service provider available at the moment',
      'no_staff_for_services':
          'No service provider can perform all selected services. Try selecting fewer or different services.',
      'error_invalid_service':
          'One or more selected services are not available',
      'error_invalid_staff':
          'The selected service provider is not available for these services',
      'error_invalid_location': 'The selected location is not available',
      'error_staff_unavailable':
          'The selected service provider is not available at this time',
      'error_missing_services': 'Unable to load booking services',
      'error_service_unavailable': 'Service temporarily unavailable',
    },
  };

  String _nomenclatureDefaultHint(BuildContext context, String key) {
    final languageCode = _resolveDefaultLanguageCode(context);
    final defaults =
        _nomenclatureDefaultHintsByLanguage[languageCode] ??
        _nomenclatureDefaultHintsByLanguage['en']!;
    return defaults[key] ?? key;
  }

  String _resolveDefaultLanguageCode(BuildContext context) {
    // Fonte primaria: locale della location (derivato dal country code).
    final country = _selectedCountryCode.trim().toUpperCase();
    final locationLanguage = switch (country) {
      'IT' || 'SM' || 'VA' => 'it',
      'US' || 'GB' || 'IE' || 'AU' || 'CA' || 'NZ' => 'en',
      _ => null,
    };

    final supported = L10n.delegate.supportedLocales
        .map((l) => l.languageCode.toLowerCase())
        .toSet();

    if (locationLanguage != null && supported.contains(locationLanguage)) {
      return locationLanguage;
    }

    // Fallback: locale corrente dell'app.
    final appLanguage = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase();
    if (supported.contains(appLanguage)) {
      return appLanguage;
    }

    // Ultimo fallback: prima lingua disponibile.
    return L10n.delegate.supportedLocales.first.languageCode.toLowerCase();
  }
}
