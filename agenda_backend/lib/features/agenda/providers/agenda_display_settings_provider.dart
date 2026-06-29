import 'package:flutter/material.dart' show Color;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/appointment.dart';
import '../../../core/services/preferences_service.dart';
import '../domain/agenda_card_color_source.dart';
import '../../auth/providers/current_business_user_provider.dart' show canViewPricesProvider;
import 'business_providers.dart';
import 'layout_config_provider.dart';
import 'location_providers.dart';

const Set<int> _clientsDefaultColorBusinessIds = {18, 19};

/// Colore di default per le card di appuntamenti "Completati" (grigio chiaro).
const Color kDefaultCompletedAppointmentColor = Color(0xFFE0E0E0);

AgendaCardColorSource _defaultCardColorSourceForBusiness(int businessId) {
  if (_clientsDefaultColorBusinessIds.contains(businessId)) {
    return AgendaCardColorSource.clients;
  }
  return AgendaCardColorSource.services;
}

class AgendaDisplaySettings {
  const AgendaDisplaySettings({
    this.cardTextScale = 1.0,
    this.slotHeightScale = 1.0,
    this.columnWidthScale = 1.0,
    this.mobileMaxColumns = 3,
    this.cardColorOpacity = 1.0,
    this.extraMinutesBandIntensity = 0.5,
    this.hoverUnrelatedCardDimIntensity = 0.0,
    this.useRoundedCardCorners = false,
    this.expandStaffColumnsOnOverlap = false,
    this.showPricesOverride,
    this.cardColorSourceOverride,
    this.showCancelledAppointments = false,
    this.completedColorEnabled = false,
    this.completedColor = kDefaultCompletedAppointmentColor,
  });

  final double cardTextScale;
  final double slotHeightScale;
  final double columnWidthScale;
  final int mobileMaxColumns;
  final double cardColorOpacity;
  final double extraMinutesBandIntensity;
  final double hoverUnrelatedCardDimIntensity;
  final bool useRoundedCardCorners;
  final bool expandStaffColumnsOnOverlap;
  final bool? showPricesOverride;
  final AgendaCardColorSource? cardColorSourceOverride;
  final bool showCancelledAppointments;

  /// Se true, gli appuntamenti in stato "Completata" usano [completedColor]
  /// al posto del colore derivato dalla sorgente (servizio/team/cliente).
  final bool completedColorEnabled;

  /// Colore applicato alle card degli appuntamenti "Completati"
  /// quando [completedColorEnabled] è true.
  final Color completedColor;

  AgendaDisplaySettings copyWith({
    double? cardTextScale,
    double? slotHeightScale,
    double? columnWidthScale,
    int? mobileMaxColumns,
    double? cardColorOpacity,
    double? extraMinutesBandIntensity,
    double? hoverUnrelatedCardDimIntensity,
    bool? useRoundedCardCorners,
    bool? expandStaffColumnsOnOverlap,
    bool? showPricesOverride,
    AgendaCardColorSource? cardColorSourceOverride,
    bool? showCancelledAppointments,
    bool? completedColorEnabled,
    Color? completedColor,
    bool clearShowPricesOverride = false,
    bool clearCardColorSourceOverride = false,
  }) {
    return AgendaDisplaySettings(
      cardTextScale: cardTextScale ?? this.cardTextScale,
      slotHeightScale: slotHeightScale ?? this.slotHeightScale,
      columnWidthScale: columnWidthScale ?? this.columnWidthScale,
      mobileMaxColumns: mobileMaxColumns ?? this.mobileMaxColumns,
      cardColorOpacity: cardColorOpacity ?? this.cardColorOpacity,
      extraMinutesBandIntensity:
          extraMinutesBandIntensity ?? this.extraMinutesBandIntensity,
      hoverUnrelatedCardDimIntensity:
          hoverUnrelatedCardDimIntensity ?? this.hoverUnrelatedCardDimIntensity,
      useRoundedCardCorners:
          useRoundedCardCorners ?? this.useRoundedCardCorners,
      expandStaffColumnsOnOverlap:
          expandStaffColumnsOnOverlap ?? this.expandStaffColumnsOnOverlap,
      showPricesOverride: clearShowPricesOverride
          ? null
          : (showPricesOverride ?? this.showPricesOverride),
      cardColorSourceOverride: clearCardColorSourceOverride
          ? null
          : (cardColorSourceOverride ?? this.cardColorSourceOverride),
      showCancelledAppointments:
          showCancelledAppointments ?? this.showCancelledAppointments,
      completedColorEnabled:
          completedColorEnabled ?? this.completedColorEnabled,
      completedColor: completedColor ?? this.completedColor,
    );
  }
}

/// Applica l'override colore per gli appuntamenti "Completati", se attivo.
/// Restituisce [completedColor] quando l'appuntamento è completato e
/// l'opzione è attiva (completedColor != null), altrimenti [base].
Color applyCompletedColorOverride(
  Color base,
  Appointment appointment,
  Color? completedColor,
) {
  if (completedColor != null && appointment.isCompleted) {
    return completedColor;
  }
  return base;
}

class AgendaDisplaySettingsNotifier extends Notifier<AgendaDisplaySettings> {
  static const _minTextScale = 0.5;
  static const _maxTextScale = 1.5;
  static const _minSlotHeightScale = 0.6;
  static const _maxSlotHeightScale = 1.6;
  static const _minColumnWidthScale = 0.75;
  static const _maxColumnWidthScale = 2.5;
  static const _minMobileMaxColumns = 1;
  static const _maxMobileMaxColumns = 3;
  static const _minCardOpacity = 0.3;
  static const _maxCardOpacity = 1.0;
  static const _minExtraMinutesBandIntensity = 0.0;
  static const _maxExtraMinutesBandIntensity = 1.0;
  static const _minHoverUnrelatedCardDimIntensity = 0.0;
  static const _maxHoverUnrelatedCardDimIntensity = 1.0;

  @override
  AgendaDisplaySettings build() {
    final businessId = ref.watch(currentBusinessIdProvider);
    final locationId = ref.watch(currentLocationIdProvider);
    final prefs = ref.watch(preferencesServiceProvider);
    if (businessId <= 0 || locationId <= 0) {
      return const AgendaDisplaySettings();
    }
    final scale = prefs
        .getAgendaCardTextScale(businessId, locationId: locationId)
        .clamp(_minTextScale, _maxTextScale);
    final slotHeightScale = prefs
        .getAgendaSlotHeightScale(businessId, locationId: locationId)
        .clamp(_minSlotHeightScale, _maxSlotHeightScale);
    final columnWidthScale = prefs
        .getAgendaColumnWidthScale(businessId, locationId: locationId)
        .clamp(_minColumnWidthScale, _maxColumnWidthScale);
    final mobileMaxColumns = prefs
        .getAgendaMobileMaxColumns(businessId, locationId: locationId)
        .clamp(_minMobileMaxColumns, _maxMobileMaxColumns);
    return AgendaDisplaySettings(
      cardTextScale: scale,
      slotHeightScale: slotHeightScale,
      columnWidthScale: columnWidthScale,
      mobileMaxColumns: mobileMaxColumns,
      cardColorOpacity: prefs
          .getAgendaCardColorOpacity(businessId, locationId: locationId)
          .clamp(_minCardOpacity, _maxCardOpacity),
      extraMinutesBandIntensity: prefs
          .getAgendaExtraMinutesBandIntensity(
            businessId,
            locationId: locationId,
          )
          .clamp(_minExtraMinutesBandIntensity, _maxExtraMinutesBandIntensity),
      hoverUnrelatedCardDimIntensity: prefs
          .getAgendaHoverUnrelatedCardDimIntensity(
            businessId,
            locationId: locationId,
          )
          .clamp(
            _minHoverUnrelatedCardDimIntensity,
            _maxHoverUnrelatedCardDimIntensity,
          ),
      useRoundedCardCorners: prefs.getAgendaUseRoundedCardCorners(
        businessId,
        locationId: locationId,
      ),
      expandStaffColumnsOnOverlap: prefs.getAgendaExpandStaffColumnsOnOverlap(
        businessId,
        locationId: locationId,
      ),
      showPricesOverride: prefs.getAgendaShowPricesOverride(
        businessId,
        locationId: locationId,
      ),
      cardColorSourceOverride: prefs.getAgendaCardColorSourceOverride(
        businessId,
        locationId: locationId,
      ),
      showCancelledAppointments: prefs.getAgendaShowCancelledAppointments(
        businessId,
        locationId: locationId,
      ),
      completedColorEnabled: prefs.getAgendaCompletedColorEnabled(
        businessId,
        locationId: locationId,
      ),
      completedColor: prefs.getAgendaCompletedColor(
        businessId,
        locationId: locationId,
      ),
    );
  }

  int _businessId() => ref.read(currentBusinessIdProvider);
  int _locationId() => ref.read(currentLocationIdProvider);

  Future<void> setCardTextScale(double value) async {
    final businessId = _businessId();
    final locationId = _locationId();
    if (businessId <= 0 || locationId <= 0) return;
    final next = value.clamp(_minTextScale, _maxTextScale);
    state = state.copyWith(cardTextScale: next);
    await ref
        .read(preferencesServiceProvider)
        .setAgendaCardTextScale(businessId, next, locationId: locationId);
  }

  Future<void> setMobileMaxColumns(int value) async {
    final businessId = _businessId();
    final locationId = _locationId();
    if (businessId <= 0 || locationId <= 0) return;
    final next = value.clamp(_minMobileMaxColumns, _maxMobileMaxColumns);
    state = state.copyWith(mobileMaxColumns: next);
    await ref
        .read(preferencesServiceProvider)
        .setAgendaMobileMaxColumns(businessId, next, locationId: locationId);
  }

  Future<void> setColumnWidthScale(double value) async {
    final businessId = _businessId();
    final locationId = _locationId();
    if (businessId <= 0 || locationId <= 0) return;
    final next = value.clamp(_minColumnWidthScale, _maxColumnWidthScale);
    state = state.copyWith(columnWidthScale: next);
    await ref
        .read(preferencesServiceProvider)
        .setAgendaColumnWidthScale(businessId, next, locationId: locationId);
  }

  Future<void> setSlotHeightScale(double value) async {
    final businessId = _businessId();
    final locationId = _locationId();
    if (businessId <= 0 || locationId <= 0) return;
    final next = value.clamp(_minSlotHeightScale, _maxSlotHeightScale);
    state = state.copyWith(slotHeightScale: next);
    await ref
        .read(preferencesServiceProvider)
        .setAgendaSlotHeightScale(businessId, next, locationId: locationId);
    ref.read(layoutConfigProvider.notifier).setSlotHeightScale(next);
  }

  Future<void> setCardColorOpacity(double value) async {
    final businessId = _businessId();
    final locationId = _locationId();
    if (businessId <= 0 || locationId <= 0) return;
    final next = value.clamp(_minCardOpacity, _maxCardOpacity);
    state = state.copyWith(cardColorOpacity: next);
    await ref
        .read(preferencesServiceProvider)
        .setAgendaCardColorOpacity(businessId, next, locationId: locationId);
  }

  Future<void> setExtraMinutesBandIntensity(double value) async {
    final businessId = _businessId();
    final locationId = _locationId();
    if (businessId <= 0 || locationId <= 0) return;
    final next = value.clamp(
      _minExtraMinutesBandIntensity,
      _maxExtraMinutesBandIntensity,
    );
    state = state.copyWith(extraMinutesBandIntensity: next);
    await ref
        .read(preferencesServiceProvider)
        .setAgendaExtraMinutesBandIntensity(
          businessId,
          next,
          locationId: locationId,
        );
  }

  Future<void> setHoverUnrelatedCardDimIntensity(double value) async {
    final businessId = _businessId();
    final locationId = _locationId();
    if (businessId <= 0 || locationId <= 0) return;
    final next = value.clamp(
      _minHoverUnrelatedCardDimIntensity,
      _maxHoverUnrelatedCardDimIntensity,
    );
    state = state.copyWith(hoverUnrelatedCardDimIntensity: next);
    await ref
        .read(preferencesServiceProvider)
        .setAgendaHoverUnrelatedCardDimIntensity(
          businessId,
          next,
          locationId: locationId,
        );
  }

  Future<void> setShowPricesOverride(bool? value) async {
    final businessId = _businessId();
    final locationId = _locationId();
    if (businessId <= 0 || locationId <= 0) return;
    state = value == null
        ? state.copyWith(clearShowPricesOverride: true)
        : state.copyWith(showPricesOverride: value);
    await ref
        .read(preferencesServiceProvider)
        .setAgendaShowPricesOverride(businessId, value, locationId: locationId);
  }

  Future<void> setUseRoundedCardCorners(bool value) async {
    final businessId = _businessId();
    final locationId = _locationId();
    if (businessId <= 0 || locationId <= 0) return;
    state = state.copyWith(useRoundedCardCorners: value);
    await ref
        .read(preferencesServiceProvider)
        .setAgendaUseRoundedCardCorners(
          businessId,
          value,
          locationId: locationId,
        );
  }

  Future<void> setExpandStaffColumnsOnOverlap(bool value) async {
    final businessId = _businessId();
    final locationId = _locationId();
    if (businessId <= 0 || locationId <= 0) return;
    state = state.copyWith(expandStaffColumnsOnOverlap: value);
    await ref
        .read(preferencesServiceProvider)
        .setAgendaExpandStaffColumnsOnOverlap(
          businessId,
          value,
          locationId: locationId,
        );
  }

  Future<void> setCardColorSourceOverride(AgendaCardColorSource? value) async {
    final businessId = _businessId();
    final locationId = _locationId();
    if (businessId <= 0 || locationId <= 0) return;
    state = value == null
        ? state.copyWith(clearCardColorSourceOverride: true)
        : state.copyWith(cardColorSourceOverride: value);
    await ref
        .read(preferencesServiceProvider)
        .setAgendaCardColorSourceOverride(
          businessId,
          value,
          locationId: locationId,
        );
    if (value != null) {
      ref
          .read(layoutConfigProvider.notifier)
          .setUseServiceColors(value == AgendaCardColorSource.services);
    }
  }

  Future<void> setShowCancelledAppointments(bool value) async {
    final businessId = _businessId();
    final locationId = _locationId();
    if (businessId <= 0 || locationId <= 0) return;
    state = state.copyWith(showCancelledAppointments: value);
    await ref
        .read(preferencesServiceProvider)
        .setAgendaShowCancelledAppointments(
          businessId,
          value,
          locationId: locationId,
        );
  }

  Future<void> setCompletedColorEnabled(bool value) async {
    final businessId = _businessId();
    final locationId = _locationId();
    if (businessId <= 0 || locationId <= 0) return;
    state = state.copyWith(completedColorEnabled: value);
    await ref
        .read(preferencesServiceProvider)
        .setAgendaCompletedColorEnabled(
          businessId,
          value,
          locationId: locationId,
        );
  }

  Future<void> setCompletedColor(Color value) async {
    final businessId = _businessId();
    final locationId = _locationId();
    if (businessId <= 0 || locationId <= 0) return;
    state = state.copyWith(completedColor: value);
    await ref
        .read(preferencesServiceProvider)
        .setAgendaCompletedColor(businessId, value, locationId: locationId);
  }

  Future<void> resetToDefaults() async {
    final businessId = _businessId();
    final locationId = _locationId();
    if (businessId <= 0 || locationId <= 0) return;
    state = const AgendaDisplaySettings();
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setAgendaCardTextScale(businessId, 1.0, locationId: locationId);
    await prefs.setAgendaSlotHeightScale(
      businessId,
      1.0,
      locationId: locationId,
    );
    await prefs.setAgendaColumnWidthScale(
      businessId,
      1.0,
      locationId: locationId,
    );
    await prefs.setAgendaMobileMaxColumns(
      businessId,
      3,
      locationId: locationId,
    );
    await prefs.setAgendaCardColorOpacity(
      businessId,
      1.0,
      locationId: locationId,
    );
    await prefs.setAgendaExtraMinutesBandIntensity(
      businessId,
      0.5,
      locationId: locationId,
    );
    await prefs.setAgendaHoverUnrelatedCardDimIntensity(
      businessId,
      0.0,
      locationId: locationId,
    );
    await prefs.setAgendaShowPricesOverride(
      businessId,
      null,
      locationId: locationId,
    );
    await prefs.setAgendaUseRoundedCardCorners(
      businessId,
      false,
      locationId: locationId,
    );
    await prefs.setAgendaExpandStaffColumnsOnOverlap(
      businessId,
      false,
      locationId: locationId,
    );
    await prefs.setAgendaCardColorSourceOverride(
      businessId,
      null,
      locationId: locationId,
    );
    final defaultSource = _defaultCardColorSourceForBusiness(businessId);
    ref
        .read(layoutConfigProvider.notifier)
        .setUseServiceColors(defaultSource == AgendaCardColorSource.services);
    ref.read(layoutConfigProvider.notifier).setSlotHeightScale(1.0);
    await prefs.setAgendaShowCancelledAppointments(
      businessId,
      false,
      locationId: locationId,
    );
    await prefs.setAgendaCompletedColorEnabled(
      businessId,
      false,
      locationId: locationId,
    );
    await prefs.setAgendaCompletedColor(
      businessId,
      kDefaultCompletedAppointmentColor,
      locationId: locationId,
    );
  }
}

final agendaDisplaySettingsProvider =
    NotifierProvider<AgendaDisplaySettingsNotifier, AgendaDisplaySettings>(
      AgendaDisplaySettingsNotifier.new,
    );

final agendaCardTextScaleProvider = Provider<double>((ref) {
  return ref.watch(agendaDisplaySettingsProvider).cardTextScale;
});

final agendaSlotHeightScaleProvider = Provider<double>((ref) {
  return ref.watch(agendaDisplaySettingsProvider).slotHeightScale;
});

final agendaCardColorOpacityProvider = Provider<double>((ref) {
  return ref.watch(agendaDisplaySettingsProvider).cardColorOpacity;
});

final agendaExtraMinutesBandIntensityProvider = Provider<double>((ref) {
  return ref.watch(agendaDisplaySettingsProvider).extraMinutesBandIntensity;
});

final agendaHoverUnrelatedCardDimIntensityProvider = Provider<double>((ref) {
  return ref
      .watch(agendaDisplaySettingsProvider)
      .hoverUnrelatedCardDimIntensity;
});

final agendaUseRoundedCardCornersProvider = Provider<bool>((ref) {
  return false;
});

final agendaMobileMaxColumnsProvider = Provider<int>((ref) {
  return ref.watch(
    agendaDisplaySettingsProvider.select((s) => s.mobileMaxColumns),
  );
});

final agendaColumnWidthScaleProvider = Provider<double>((ref) {
  return ref.watch(
    agendaDisplaySettingsProvider.select((s) => s.columnWidthScale),
  );
});

final agendaExpandStaffColumnsOnOverlapProvider = Provider<bool>((ref) {
  return ref.watch(
    agendaDisplaySettingsProvider.select((s) => s.expandStaffColumnsOnOverlap),
  );
});

final effectiveShowAppointmentPriceInCardProvider = Provider<bool>((ref) {
  if (!ref.watch(canViewPricesProvider)) return false;
  final businessShowPrice = ref
      .watch(currentBusinessProvider)
      .showAppointmentPriceInCard;
  final override = ref.watch(agendaDisplaySettingsProvider).showPricesOverride;
  return override ?? businessShowPrice;
});

final effectiveUseServiceColorsForAppointmentsProvider = Provider<bool>((ref) {
  final source = ref.watch(effectiveAgendaCardColorSourceProvider);
  return source == AgendaCardColorSource.services;
});

final effectiveAgendaCardColorSourceProvider = Provider<AgendaCardColorSource>((
  ref,
) {
  final businessId = ref.watch(currentBusinessIdProvider);
  final base = _defaultCardColorSourceForBusiness(businessId);
  final override = ref.watch(
    agendaDisplaySettingsProvider.select((s) => s.cardColorSourceOverride),
  );
  return override ?? base;
});

final effectiveShowCancelledAppointmentsProvider = Provider<bool>((ref) {
  return ref.watch(
    agendaDisplaySettingsProvider.select((s) => s.showCancelledAppointments),
  );
});

/// Colore da usare per le card degli appuntamenti "Completati", oppure null
/// se l'override è disattivato (in tal caso vale il colore della sorgente).
final effectiveCompletedCardColorProvider = Provider<Color?>((ref) {
  final enabled = ref.watch(
    agendaDisplaySettingsProvider.select((s) => s.completedColorEnabled),
  );
  if (!enabled) return null;
  return ref.watch(
    agendaDisplaySettingsProvider.select((s) => s.completedColor),
  );
});
