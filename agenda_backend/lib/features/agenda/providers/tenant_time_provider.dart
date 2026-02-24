import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/tenant_time_service.dart';
import 'business_providers.dart';
import 'location_providers.dart';

final effectiveTenantTimezoneProvider = Provider<String>((ref) {
  final location = ref.watch(currentLocationProvider);
  final locationTimezone = location.timezone.trim();
  if (locationTimezone.isNotEmpty) {
    return TenantTimeService.normalizeTimezone(locationTimezone);
  }

  final business = ref.watch(currentBusinessProvider);
  return TenantTimeService.normalizeTimezone(business.timezone);
});

final tenantTodayProvider = Provider<DateTime>((ref) {
  final timezone = ref.watch(effectiveTenantTimezoneProvider);
  return TenantTimeService.dateOnlyTodayInTimezone(timezone);
});

final tenantNowProvider = Provider<DateTime>((ref) {
  final timezone = ref.watch(effectiveTenantTimezoneProvider);
  return TenantTimeService.nowInTimezone(timezone);
});
