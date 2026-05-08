import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/preferences_service.dart';
import '../../agenda/providers/business_providers.dart';
import '../../agenda/providers/tenant_time_provider.dart';
import 'billing_provider.dart';

const _problematicStatuses = {
  'inactive',
  'pending_checkout',
  'past_due',
  'unpaid',
  'canceled',
  'error',
};

String _todayKey(int businessId, DateTime today) {
  final dateStr =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  return PrefsKeys.billingNoticeSeen(businessId, dateStr);
}

/// Restituisce true se il banner billing agenda deve essere visibile oggi.
///
/// Ritorna false in caso di:
/// - business non caricato / billing in caricamento o errore
/// - billing non richiesto o attivo
/// - banner già chiuso oggi (chiave SharedPreferences impostata)
final shouldShowBillingAgendaNoticeProvider = FutureProvider<bool>((ref) async {
  final businessId = ref.watch(currentBusinessIdProvider);
  if (businessId <= 0) return false;

  final billingAsync = ref.watch(billingSubscriptionProvider);
  final billing = billingAsync.asData?.value;
  if (billing == null) return false;

  if (!billing.billingEnabled) return false;
  if (!_problematicStatuses.contains(billing.status)) return false;

  final today = ref.watch(tenantTodayProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  if (prefs.getBool(_todayKey(businessId, today)) == true) return false;

  return true;
});

/// Restituisce true se il billing è ancora problematico ma il banner
/// è già stato chiuso oggi → mostrare solo l'icona di warning in toolbar.
final shouldShowBillingAgendaWarningIconProvider =
    FutureProvider<bool>((ref) async {
  final businessId = ref.watch(currentBusinessIdProvider);
  if (businessId <= 0) return false;

  final billingAsync = ref.watch(billingSubscriptionProvider);
  final billing = billingAsync.asData?.value;
  if (billing == null) return false;

  if (!billing.billingEnabled) return false;
  if (!_problematicStatuses.contains(billing.status)) return false;

  final today = ref.watch(tenantTodayProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool(_todayKey(businessId, today)) == true;
});
