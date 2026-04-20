import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/agenda/domain/agenda_card_color_source.dart';

/// Provider per SharedPreferences (inizializzato in main.dart)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope',
  );
});

/// Chiavi per le preferenze salvate.
/// Le preferenze sono salvate per business_id per supportare superadmin
/// che gestiscono più business.
class PrefsKeys {
  static String _scope(int businessId, int? locationId) =>
      locationId != null && locationId > 0
      ? '${businessId}_loc_$locationId'
      : '$businessId';

  /// Genera la chiave per staff filter mode per un business specifico
  static String staffFilterMode(int businessId, {int? locationId}) =>
      'staff_filter_mode_${_scope(businessId, locationId)}';

  /// Genera la chiave per selected staff IDs per un business specifico
  static String selectedStaffIds(int businessId, {int? locationId}) =>
      'selected_staff_ids_${_scope(businessId, locationId)}';

  /// Genera la chiave per current location ID per un business specifico
  static String currentLocationId(int businessId) =>
      'current_location_id_$businessId';

  /// Genera la chiave per la data agenda per business + location
  static String agendaDate(int businessId, {required int locationId}) =>
      'agenda_date_${_scope(businessId, locationId)}';

  /// Genera la chiave per l'ultimo "oggi" visualizzato in agenda
  /// per business + location.
  static String agendaTodaySeenDate(
    int businessId, {
    required int locationId,
  }) => 'agenda_today_seen_date_${_scope(businessId, locationId)}';

  /// Genera la chiave per la modalità vista agenda per business + location
  static String agendaViewMode(int businessId, {required int locationId}) =>
      'agenda_view_mode_${_scope(businessId, locationId)}';

  /// Zoom testo card agenda (scope business + location)
  static String agendaCardTextScale(
    int businessId, {
    required int locationId,
  }) => 'agenda_card_text_scale_${_scope(businessId, locationId)}';

  /// Intensità colore card agenda (opacità) (scope business + location)
  static String agendaCardColorOpacity(
    int businessId, {
    required int locationId,
  }) => 'agenda_card_color_opacity_${_scope(businessId, locationId)}';

  /// Intensità fascia minuti extra in card agenda (scope business + location)
  static String agendaExtraMinutesBandIntensity(
    int businessId, {
    required int locationId,
  }) => 'agenda_extra_minutes_band_intensity_${_scope(businessId, locationId)}';

  /// Intensità de-enfasi card non correlate durante hover (scope business + location)
  static String agendaHoverUnrelatedCardDimIntensity(
    int businessId, {
    required int locationId,
  }) =>
      'agenda_hover_unrelated_card_dim_intensity_${_scope(businessId, locationId)}';

  /// Mostra card con angoli arrotondati (scope business + location)
  static String agendaUseRoundedCardCorners(
    int businessId, {
    required int locationId,
  }) => 'agenda_use_rounded_card_corners_${_scope(businessId, locationId)}';

  /// Override superadmin: mostra prezzi in card (scope business + location)
  static String agendaShowPricesOverride(
    int businessId, {
    required int locationId,
  }) => 'agenda_show_prices_override_${_scope(businessId, locationId)}';

  /// Override superadmin: usa colori servizio nelle card (scope business + location)
  static String agendaUseServiceColorsOverride(
    int businessId, {
    required int locationId,
  }) => 'agenda_use_service_colors_override_${_scope(businessId, locationId)}';

  /// Mostra appuntamenti cancellati (scope business + location)
  static String agendaShowCancelledAppointments(
    int businessId, {
    required int locationId,
  }) => 'agenda_show_cancelled_appointments_${_scope(businessId, locationId)}';

  /// Espande le colonne staff in base al picco di sovrapposizioni card
  /// (scope business + location)
  static String agendaExpandStaffColumnsOnOverlap(
    int businessId, {
    required int locationId,
  }) =>
      'agenda_expand_staff_columns_on_overlap_${_scope(businessId, locationId)}';

  /// Chiave per ultimo business visitato dal superadmin
  static const superadminLastBusinessId = 'superadmin_last_business_id';
  static const superadminShowBusinessPickerOnLogin =
      'superadmin_show_business_picker_on_login';
  static String lastVisitedRouteForUser(int userId) =>
      'last_visited_route_user_$userId';
  static String lastVisitedRouteUpdatedAtForUser(int userId) =>
      'last_visited_route_updated_at_user_$userId';

  /// Chiave legacy (senza business_id) per migrazione
  static const legacyStaffFilterMode = 'staff_filter_mode';
  static const legacySelectedStaffIds = 'selected_staff_ids';
  static const legacyCurrentLocationId = 'current_location_id';
  static const legacyAgendaDate = 'agenda_date';
  static const legacyAgendaViewMode = 'agenda_view_mode';

  /// Preferenza globale UI: rail desktop dall'alto o sotto toolbar.
  static const desktopRailStartsAtTop = 'desktop_rail_starts_at_top';
  static const adminLocaleCode = 'admin_locale_code';
}

/// Service per gestire le preferenze utente.
/// Le preferenze sono salvate per business per supportare operatori
/// che lavorano su più business (superadmin).
class PreferencesService {
  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  // ============================================
  // Staff Filter Mode
  // ============================================

  /// Ottiene il filtro staff salvato per il business.
  /// Cerca prima la chiave per business, poi fallback su legacy.
  String? getStaffFilterMode(int businessId, {int? locationId}) {
    // Prima prova chiave per business
    var value = _prefs.getString(
      PrefsKeys.staffFilterMode(businessId, locationId: locationId),
    );
    if (value != null) return value;

    if (locationId != null && locationId > 0) {
      value = _prefs.getString(PrefsKeys.staffFilterMode(businessId));
      if (value != null) {
        setStaffFilterMode(businessId, value, locationId: locationId);
        return value;
      }
    }

    // Fallback su chiave legacy (migrazione)
    value = _prefs.getString(PrefsKeys.legacyStaffFilterMode);
    if (value != null) {
      // Migra alla nuova chiave
      setStaffFilterMode(businessId, value, locationId: locationId);
      _prefs.remove(PrefsKeys.legacyStaffFilterMode);
    }
    return value;
  }

  Future<void> setStaffFilterMode(
    int businessId,
    String mode, {
    int? locationId,
  }) async {
    await _prefs.setString(
      PrefsKeys.staffFilterMode(businessId, locationId: locationId),
      mode,
    );
  }

  // ============================================
  // Selected Staff IDs
  // ============================================

  /// Ottiene gli ID staff selezionati per il business.
  /// Gli ID vengono validati: ID <= 0 sono filtrati.
  List<int> getSelectedStaffIds(int businessId, {int? locationId}) {
    // Prima prova chiave per business
    var json = _prefs.getString(
      PrefsKeys.selectedStaffIds(businessId, locationId: locationId),
    );

    if (json == null && locationId != null && locationId > 0) {
      json = _prefs.getString(PrefsKeys.selectedStaffIds(businessId));
      if (json != null) {
        _prefs.setString(
          PrefsKeys.selectedStaffIds(businessId, locationId: locationId),
          json,
        );
      }
    }

    // Fallback su chiave legacy
    if (json == null) {
      json = _prefs.getString(PrefsKeys.legacySelectedStaffIds);
      if (json != null) {
        // Migra alla nuova chiave
        _prefs.setString(
          PrefsKeys.selectedStaffIds(businessId, locationId: locationId),
          json,
        );
        _prefs.remove(PrefsKeys.legacySelectedStaffIds);
      }
    }

    if (json == null || json.isEmpty) return [];

    // Parse sicuro: ignora valori non validi
    return json
        .split(',')
        .map((s) => int.tryParse(s.trim()) ?? 0)
        .where((id) => id > 0)
        .toList();
  }

  Future<void> setSelectedStaffIds(
    int businessId,
    Set<int> ids, {
    int? locationId,
  }) async {
    if (ids.isEmpty) {
      // Rimuovi la chiave se vuota per risparmiare spazio
      await _prefs.remove(
        PrefsKeys.selectedStaffIds(businessId, locationId: locationId),
      );
    } else {
      await _prefs.setString(
        PrefsKeys.selectedStaffIds(businessId, locationId: locationId),
        ids.join(','),
      );
    }
  }

  // ============================================
  // Current Location ID
  // ============================================

  /// Ottiene la location corrente salvata per il business.
  int? getCurrentLocationId(int businessId) {
    // Prima prova chiave per business
    var value = _prefs.getInt(PrefsKeys.currentLocationId(businessId));
    if (value != null) return value;

    // Fallback su chiave legacy
    value = _prefs.getInt(PrefsKeys.legacyCurrentLocationId);
    if (value != null) {
      // Migra alla nuova chiave
      setCurrentLocationId(businessId, value);
      _prefs.remove(PrefsKeys.legacyCurrentLocationId);
    }
    return value;
  }

  Future<void> setCurrentLocationId(int businessId, int id) async {
    await _prefs.setInt(PrefsKeys.currentLocationId(businessId), id);
  }

  DateTime? getAgendaDate(int businessId, {required int locationId}) {
    var value = _prefs.getString(
      PrefsKeys.agendaDate(businessId, locationId: locationId),
    );

    if (value == null) {
      value = _prefs.getString(PrefsKeys.legacyAgendaDate);
      if (value != null) {
        setAgendaDate(
          businessId,
          locationId: locationId,
          date: DateTime.tryParse(value),
        );
        _prefs.remove(PrefsKeys.legacyAgendaDate);
      }
    }

    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  Future<void> setAgendaDate(
    int businessId, {
    required int locationId,
    required DateTime? date,
  }) async {
    final key = PrefsKeys.agendaDate(businessId, locationId: locationId);
    if (date == null) {
      await _prefs.remove(key);
      return;
    }
    await _prefs.setString(key, date.toIso8601String());
  }

  DateTime? getAgendaTodaySeenDate(int businessId, {required int locationId}) {
    final value = _prefs.getString(
      PrefsKeys.agendaTodaySeenDate(businessId, locationId: locationId),
    );
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  Future<void> setAgendaTodaySeenDate(
    int businessId, {
    required int locationId,
    required DateTime? date,
  }) async {
    final key = PrefsKeys.agendaTodaySeenDate(
      businessId,
      locationId: locationId,
    );
    if (date == null) {
      await _prefs.remove(key);
      return;
    }
    await _prefs.setString(key, date.toIso8601String());
  }

  String? getAgendaViewMode(int businessId, {required int locationId}) {
    var value = _prefs.getString(
      PrefsKeys.agendaViewMode(businessId, locationId: locationId),
    );

    if (value == null) {
      value = _prefs.getString(PrefsKeys.legacyAgendaViewMode);
      if (value != null) {
        setAgendaViewMode(businessId, locationId: locationId, mode: value);
        _prefs.remove(PrefsKeys.legacyAgendaViewMode);
      }
    }

    return value;
  }

  Future<void> setAgendaViewMode(
    int businessId, {
    required int locationId,
    required String mode,
  }) async {
    await _prefs.setString(
      PrefsKeys.agendaViewMode(businessId, locationId: locationId),
      mode,
    );
  }

  // ============================================
  // Agenda Display Settings (Superadmin)
  // ============================================

  double getAgendaCardTextScale(int businessId, {required int locationId}) {
    final value = _prefs.getDouble(
      PrefsKeys.agendaCardTextScale(businessId, locationId: locationId),
    );
    return value ?? 1.0;
  }

  Future<void> setAgendaCardTextScale(
    int businessId,
    double scale, {
    required int locationId,
  }) async {
    await _prefs.setDouble(
      PrefsKeys.agendaCardTextScale(businessId, locationId: locationId),
      scale,
    );
  }

  double getAgendaCardColorOpacity(int businessId, {required int locationId}) {
    final value = _prefs.getDouble(
      PrefsKeys.agendaCardColorOpacity(businessId, locationId: locationId),
    );
    return value ?? 1.0;
  }

  Future<void> setAgendaCardColorOpacity(
    int businessId,
    double opacity, {
    required int locationId,
  }) async {
    await _prefs.setDouble(
      PrefsKeys.agendaCardColorOpacity(businessId, locationId: locationId),
      opacity,
    );
  }

  double getAgendaExtraMinutesBandIntensity(
    int businessId, {
    required int locationId,
  }) {
    final value = _prefs.getDouble(
      PrefsKeys.agendaExtraMinutesBandIntensity(
        businessId,
        locationId: locationId,
      ),
    );
    return value ?? 0.5;
  }

  Future<void> setAgendaExtraMinutesBandIntensity(
    int businessId,
    double intensity, {
    required int locationId,
  }) async {
    await _prefs.setDouble(
      PrefsKeys.agendaExtraMinutesBandIntensity(
        businessId,
        locationId: locationId,
      ),
      intensity,
    );
  }

  double getAgendaHoverUnrelatedCardDimIntensity(
    int businessId, {
    required int locationId,
  }) {
    final value = _prefs.getDouble(
      PrefsKeys.agendaHoverUnrelatedCardDimIntensity(
        businessId,
        locationId: locationId,
      ),
    );
    return value ?? 0.0;
  }

  Future<void> setAgendaHoverUnrelatedCardDimIntensity(
    int businessId,
    double intensity, {
    required int locationId,
  }) async {
    await _prefs.setDouble(
      PrefsKeys.agendaHoverUnrelatedCardDimIntensity(
        businessId,
        locationId: locationId,
      ),
      intensity,
    );
  }

  bool getAgendaUseRoundedCardCorners(
    int businessId, {
    required int locationId,
  }) {
    return _prefs.getBool(
          PrefsKeys.agendaUseRoundedCardCorners(
            businessId,
            locationId: locationId,
          ),
        ) ??
        false;
  }

  Future<void> setAgendaUseRoundedCardCorners(
    int businessId,
    bool value, {
    required int locationId,
  }) async {
    await _prefs.setBool(
      PrefsKeys.agendaUseRoundedCardCorners(businessId, locationId: locationId),
      value,
    );
  }

  bool? getAgendaShowPricesOverride(int businessId, {required int locationId}) {
    return _prefs.getBool(
      PrefsKeys.agendaShowPricesOverride(businessId, locationId: locationId),
    );
  }

  Future<void> setAgendaShowPricesOverride(
    int businessId,
    bool? value, {
    required int locationId,
  }) async {
    final key = PrefsKeys.agendaShowPricesOverride(
      businessId,
      locationId: locationId,
    );
    if (value == null) {
      await _prefs.remove(key);
      return;
    }
    await _prefs.setBool(key, value);
  }

  AgendaCardColorSource? getAgendaCardColorSourceOverride(
    int businessId, {
    required int locationId,
  }) {
    final key = PrefsKeys.agendaUseServiceColorsOverride(
      businessId,
      locationId: locationId,
    );
    return agendaCardColorSourceFromStorage(_prefs.get(key));
  }

  Future<void> setAgendaCardColorSourceOverride(
    int businessId,
    AgendaCardColorSource? value, {
    required int locationId,
  }) async {
    final key = PrefsKeys.agendaUseServiceColorsOverride(
      businessId,
      locationId: locationId,
    );
    if (value == null) {
      await _prefs.remove(key);
      return;
    }
    await _prefs.setString(key, value.storageValue);
  }

  bool getAgendaShowCancelledAppointments(
    int businessId, {
    required int locationId,
  }) {
    return _prefs.getBool(
          PrefsKeys.agendaShowCancelledAppointments(
            businessId,
            locationId: locationId,
          ),
        ) ??
        false;
  }

  Future<void> setAgendaShowCancelledAppointments(
    int businessId,
    bool value, {
    required int locationId,
  }) async {
    await _prefs.setBool(
      PrefsKeys.agendaShowCancelledAppointments(
        businessId,
        locationId: locationId,
      ),
      value,
    );
  }

  bool getAgendaExpandStaffColumnsOnOverlap(
    int businessId, {
    required int locationId,
  }) {
    return _prefs.getBool(
          PrefsKeys.agendaExpandStaffColumnsOnOverlap(
            businessId,
            locationId: locationId,
          ),
        ) ??
        true;
  }

  Future<void> setAgendaExpandStaffColumnsOnOverlap(
    int businessId,
    bool value, {
    required int locationId,
  }) async {
    await _prefs.setBool(
      PrefsKeys.agendaExpandStaffColumnsOnOverlap(
        businessId,
        locationId: locationId,
      ),
      value,
    );
  }

  // ============================================
  // Desktop Rail Position
  // ============================================

  bool getDesktopRailStartsAtTop() {
    return _prefs.getBool(PrefsKeys.desktopRailStartsAtTop) ?? true;
  }

  Future<void> setDesktopRailStartsAtTop(bool value) async {
    await _prefs.setBool(PrefsKeys.desktopRailStartsAtTop, value);
  }

  // ============================================
  // Admin Locale
  // ============================================

  String? getAdminLocaleCode() {
    final value = _prefs.getString(PrefsKeys.adminLocaleCode)?.trim();
    if (value == null || value.isEmpty) return null;
    return value.toLowerCase();
  }

  Future<void> setAdminLocaleCode(String? code) async {
    final normalized = code?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      await _prefs.remove(PrefsKeys.adminLocaleCode);
      return;
    }
    await _prefs.setString(PrefsKeys.adminLocaleCode, normalized);
  }

  // ============================================
  // Superadmin Last Business ID
  // ============================================

  /// Ottiene l'ultimo business visitato dal superadmin.
  int? getSuperadminLastBusinessId() {
    return _prefs.getInt(PrefsKeys.superadminLastBusinessId);
  }

  /// Salva l'ultimo business visitato dal superadmin.
  Future<void> setSuperadminLastBusinessId(int businessId) async {
    await _prefs.setInt(PrefsKeys.superadminLastBusinessId, businessId);
  }

  /// Rimuove l'ultimo business salvato (es. se il business viene eliminato).
  Future<void> clearSuperadminLastBusinessId() async {
    await _prefs.remove(PrefsKeys.superadminLastBusinessId);
  }

  /// Se true, al prossimo login del superadmin viene mostrata la lista business
  /// invece dell'ultimo business visitato.
  bool getSuperadminShowBusinessPickerOnLogin() {
    return _prefs.getBool(PrefsKeys.superadminShowBusinessPickerOnLogin) ??
        false;
  }

  Future<void> setSuperadminShowBusinessPickerOnLogin(bool value) async {
    await _prefs.setBool(PrefsKeys.superadminShowBusinessPickerOnLogin, value);
  }

  Future<void> clearSuperadminShowBusinessPickerOnLogin() async {
    await _prefs.remove(PrefsKeys.superadminShowBusinessPickerOnLogin);
  }

  // ============================================
  // Last Visited Route (per user)
  // ============================================

  /// Restituisce l'ultima route visitata dall'utente se ancora valida.
  /// Se scaduta o corrotta, la rimuove e ritorna null.
  String? getLastVisitedRouteForUser(int userId, {required Duration maxAge}) {
    final route = _prefs.getString(PrefsKeys.lastVisitedRouteForUser(userId));
    final updatedAtMs = _prefs.getInt(
      PrefsKeys.lastVisitedRouteUpdatedAtForUser(userId),
    );
    if (route == null || updatedAtMs == null) {
      return null;
    }

    final normalizedRoute = route.trim();
    if (normalizedRoute.isEmpty || !normalizedRoute.startsWith('/')) {
      return null;
    }

    final updatedAt = DateTime.fromMillisecondsSinceEpoch(updatedAtMs);
    final isExpired = DateTime.now().difference(updatedAt) > maxAge;
    if (isExpired) {
      return null;
    }

    return normalizedRoute;
  }

  /// Salva l'ultima route visitata dall'utente con timestamp.
  Future<void> setLastVisitedRouteForUser(int userId, String route) async {
    final normalizedRoute = route.trim();
    if (normalizedRoute.isEmpty || !normalizedRoute.startsWith('/')) {
      return;
    }

    await _prefs.setString(
      PrefsKeys.lastVisitedRouteForUser(userId),
      normalizedRoute,
    );
    await _prefs.setInt(
      PrefsKeys.lastVisitedRouteUpdatedAtForUser(userId),
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Rimuove l'ultima route salvata per l'utente.
  Future<void> clearLastVisitedRouteForUser(int userId) async {
    await _prefs.remove(PrefsKeys.lastVisitedRouteForUser(userId));
    await _prefs.remove(PrefsKeys.lastVisitedRouteUpdatedAtForUser(userId));
  }

  // ============================================
  // Clear / Cleanup
  // ============================================

  /// Pulisce le preferenze per un business specifico.
  /// Utile quando il superadmin esce da un business.
  Future<void> clearForBusiness(int businessId) async {
    await _prefs.remove(PrefsKeys.currentLocationId(businessId));
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('staff_filter_mode_${businessId}_') ||
          key == PrefsKeys.staffFilterMode(businessId) ||
          key.startsWith('selected_staff_ids_${businessId}_') ||
          key == PrefsKeys.selectedStaffIds(businessId) ||
          key.startsWith('agenda_date_${businessId}_') ||
          key.startsWith('agenda_today_seen_date_${businessId}_') ||
          key.startsWith('agenda_view_mode_${businessId}_') ||
          key.startsWith('agenda_card_text_scale_${businessId}_') ||
          key == 'agenda_card_text_scale_$businessId' ||
          key.startsWith('agenda_card_color_opacity_${businessId}_') ||
          key == 'agenda_card_color_opacity_$businessId' ||
          key.startsWith(
            'agenda_extra_minutes_band_intensity_${businessId}_',
          ) ||
          key == 'agenda_extra_minutes_band_intensity_$businessId' ||
          key.startsWith(
            'agenda_hover_unrelated_card_dim_intensity_${businessId}_',
          ) ||
          key == 'agenda_hover_unrelated_card_dim_intensity_$businessId' ||
          key.startsWith('agenda_use_rounded_card_corners_${businessId}_') ||
          key == 'agenda_use_rounded_card_corners_$businessId' ||
          key.startsWith('agenda_show_prices_override_${businessId}_') ||
          key == 'agenda_show_prices_override_$businessId' ||
          key.startsWith('agenda_use_service_colors_override_${businessId}_') ||
          key == 'agenda_use_service_colors_override_$businessId' ||
          key.startsWith('agenda_show_cancelled_appointments_${businessId}_') ||
          key.startsWith(
            'agenda_expand_staff_columns_on_overlap_${businessId}_',
          )) {
        await _prefs.remove(key);
      }
    }
  }

  /// Pulisce tutte le preferenze (logout completo).
  Future<void> clearAll() async {
    // Rimuovi tutte le chiavi che iniziano con i nostri prefix
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('staff_filter_mode') ||
          key.startsWith('selected_staff_ids') ||
          key.startsWith('agenda_date') ||
          key.startsWith('agenda_today_seen_date') ||
          key.startsWith('agenda_view_mode') ||
          key.startsWith('agenda_card_text_scale_') ||
          key.startsWith('agenda_card_color_opacity_') ||
          key.startsWith('agenda_extra_minutes_band_intensity_') ||
          key.startsWith('agenda_hover_unrelated_card_dim_intensity_') ||
          key.startsWith('agenda_use_rounded_card_corners_') ||
          key.startsWith('agenda_show_prices_override_') ||
          key.startsWith('agenda_use_service_colors_override_') ||
          key.startsWith('agenda_show_cancelled_appointments_') ||
          key.startsWith('agenda_expand_staff_columns_on_overlap_') ||
          key.startsWith('last_visited_route_user_') ||
          key.startsWith('last_visited_route_updated_at_user_') ||
          key.startsWith('current_location_id') ||
          key == PrefsKeys.desktopRailStartsAtTop ||
          key == PrefsKeys.adminLocaleCode) {
        await _prefs.remove(key);
      }
    }
  }
}

/// Provider per PreferencesService
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PreferencesService(prefs);
});
