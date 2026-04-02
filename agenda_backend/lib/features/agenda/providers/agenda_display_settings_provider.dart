import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/preferences_service.dart';
import 'business_providers.dart';
import 'layout_config_provider.dart';
import 'location_providers.dart';

class AgendaDisplaySettings {
  const AgendaDisplaySettings({
    this.cardTextScale = 1.0,
    this.cardColorOpacity = 1.0,
    this.extraMinutesBandIntensity = 0.5,
    this.hoverUnrelatedCardDimIntensity = 0.0,
    this.showPricesOverride,
    this.useServiceColorsOverride,
    this.showCancelledAppointments = false,
  });

  final double cardTextScale;
  final double cardColorOpacity;
  final double extraMinutesBandIntensity;
  final double hoverUnrelatedCardDimIntensity;
  final bool? showPricesOverride;
  final bool? useServiceColorsOverride;
  final bool showCancelledAppointments;

  AgendaDisplaySettings copyWith({
    double? cardTextScale,
    double? cardColorOpacity,
    double? extraMinutesBandIntensity,
    double? hoverUnrelatedCardDimIntensity,
    bool? showPricesOverride,
    bool? useServiceColorsOverride,
    bool? showCancelledAppointments,
    bool clearShowPricesOverride = false,
    bool clearUseServiceColorsOverride = false,
  }) {
    return AgendaDisplaySettings(
      cardTextScale: cardTextScale ?? this.cardTextScale,
      cardColorOpacity: cardColorOpacity ?? this.cardColorOpacity,
      extraMinutesBandIntensity:
          extraMinutesBandIntensity ?? this.extraMinutesBandIntensity,
      hoverUnrelatedCardDimIntensity:
          hoverUnrelatedCardDimIntensity ?? this.hoverUnrelatedCardDimIntensity,
      showPricesOverride: clearShowPricesOverride
          ? null
          : (showPricesOverride ?? this.showPricesOverride),
      useServiceColorsOverride: clearUseServiceColorsOverride
          ? null
          : (useServiceColorsOverride ?? this.useServiceColorsOverride),
      showCancelledAppointments:
          showCancelledAppointments ?? this.showCancelledAppointments,
    );
  }
}

class AgendaDisplaySettingsNotifier extends Notifier<AgendaDisplaySettings> {
  static const _minTextScale = 0.5;
  static const _maxTextScale = 1.5;
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
    return AgendaDisplaySettings(
      cardTextScale: scale,
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
      showPricesOverride: prefs.getAgendaShowPricesOverride(
        businessId,
        locationId: locationId,
      ),
      useServiceColorsOverride: prefs.getAgendaUseServiceColorsOverride(
        businessId,
        locationId: locationId,
      ),
      showCancelledAppointments: prefs.getAgendaShowCancelledAppointments(
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

  Future<void> setUseServiceColorsOverride(bool? value) async {
    final businessId = _businessId();
    final locationId = _locationId();
    if (businessId <= 0 || locationId <= 0) return;
    state = value == null
        ? state.copyWith(clearUseServiceColorsOverride: true)
        : state.copyWith(useServiceColorsOverride: value);
    await ref
        .read(preferencesServiceProvider)
        .setAgendaUseServiceColorsOverride(
          businessId,
          value,
          locationId: locationId,
        );
    if (value != null) {
      ref.read(layoutConfigProvider.notifier).setUseServiceColors(value);
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

  Future<void> resetToDefaults() async {
    final businessId = _businessId();
    final locationId = _locationId();
    if (businessId <= 0 || locationId <= 0) return;
    state = const AgendaDisplaySettings();
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setAgendaCardTextScale(businessId, 1.0, locationId: locationId);
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
    await prefs.setAgendaUseServiceColorsOverride(
      businessId,
      null,
      locationId: locationId,
    );
    // Ripristina anche il valore runtime base del layout (default: colori da servizio)
    ref.read(layoutConfigProvider.notifier).setUseServiceColors(true);
    await prefs.setAgendaShowCancelledAppointments(
      businessId,
      false,
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

final effectiveShowAppointmentPriceInCardProvider = Provider<bool>((ref) {
  final businessShowPrice = ref
      .watch(currentBusinessProvider)
      .showAppointmentPriceInCard;
  final override = ref.watch(agendaDisplaySettingsProvider).showPricesOverride;
  return override ?? businessShowPrice;
});

final effectiveUseServiceColorsForAppointmentsProvider = Provider<bool>((ref) {
  final base = ref.watch(layoutConfigProvider).useServiceColorsForAppointments;
  final override = ref.watch(
    agendaDisplaySettingsProvider.select((s) => s.useServiceColorsOverride),
  );
  return override ?? base;
});

final effectiveShowCancelledAppointmentsProvider = Provider<bool>((ref) {
  return ref.watch(
    agendaDisplaySettingsProvider.select((s) => s.showCancelledAppointments),
  );
});
