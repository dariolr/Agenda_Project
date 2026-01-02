import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  /// Genera la chiave per staff filter mode per un business specifico
  static String staffFilterMode(int businessId) =>
      'staff_filter_mode_$businessId';

  /// Genera la chiave per selected staff IDs per un business specifico
  static String selectedStaffIds(int businessId) =>
      'selected_staff_ids_$businessId';

  /// Genera la chiave per current location ID per un business specifico
  static String currentLocationId(int businessId) =>
      'current_location_id_$businessId';

  /// Chiave legacy (senza business_id) per migrazione
  static const legacyStaffFilterMode = 'staff_filter_mode';
  static const legacySelectedStaffIds = 'selected_staff_ids';
  static const legacyCurrentLocationId = 'current_location_id';
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
  String? getStaffFilterMode(int businessId) {
    // Prima prova chiave per business
    var value = _prefs.getString(PrefsKeys.staffFilterMode(businessId));
    if (value != null) return value;

    // Fallback su chiave legacy (migrazione)
    value = _prefs.getString(PrefsKeys.legacyStaffFilterMode);
    if (value != null) {
      // Migra alla nuova chiave
      setStaffFilterMode(businessId, value);
      _prefs.remove(PrefsKeys.legacyStaffFilterMode);
    }
    return value;
  }

  Future<void> setStaffFilterMode(int businessId, String mode) async {
    await _prefs.setString(PrefsKeys.staffFilterMode(businessId), mode);
  }

  // ============================================
  // Selected Staff IDs
  // ============================================

  /// Ottiene gli ID staff selezionati per il business.
  /// Gli ID vengono validati: ID <= 0 sono filtrati.
  List<int> getSelectedStaffIds(int businessId) {
    // Prima prova chiave per business
    var json = _prefs.getString(PrefsKeys.selectedStaffIds(businessId));

    // Fallback su chiave legacy
    if (json == null) {
      json = _prefs.getString(PrefsKeys.legacySelectedStaffIds);
      if (json != null) {
        // Migra alla nuova chiave
        _prefs.setString(PrefsKeys.selectedStaffIds(businessId), json);
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

  Future<void> setSelectedStaffIds(int businessId, Set<int> ids) async {
    if (ids.isEmpty) {
      // Rimuovi la chiave se vuota per risparmiare spazio
      await _prefs.remove(PrefsKeys.selectedStaffIds(businessId));
    } else {
      await _prefs.setString(
        PrefsKeys.selectedStaffIds(businessId),
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

  // ============================================
  // Clear / Cleanup
  // ============================================

  /// Pulisce le preferenze per un business specifico.
  /// Utile quando il superadmin esce da un business.
  Future<void> clearForBusiness(int businessId) async {
    await _prefs.remove(PrefsKeys.staffFilterMode(businessId));
    await _prefs.remove(PrefsKeys.selectedStaffIds(businessId));
    await _prefs.remove(PrefsKeys.currentLocationId(businessId));
  }

  /// Pulisce tutte le preferenze (logout completo).
  Future<void> clearAll() async {
    // Rimuovi tutte le chiavi che iniziano con i nostri prefix
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('staff_filter_mode') ||
          key.startsWith('selected_staff_ids') ||
          key.startsWith('current_location_id')) {
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
