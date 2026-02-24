import 'package:timezone/timezone.dart' as tz;

class TenantTimeService {
  TenantTimeService._();

  static const String defaultTimezone = 'Europe/Rome';

  static final Map<String, tz.Location> _locationCache =
      <String, tz.Location>{};

  static String normalizeTimezone(String? timezone) {
    final trimmed = timezone?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return defaultTimezone;
    }
    try {
      tz.getLocation(trimmed);
      return trimmed;
    } catch (_) {
      return defaultTimezone;
    }
  }

  static tz.Location locationFor(String? timezone) {
    final normalized = normalizeTimezone(timezone);
    return _locationCache.putIfAbsent(
      normalized,
      () => tz.getLocation(normalized),
    );
  }

  static DateTime nowInTimezone(String? timezone) {
    return tz.TZDateTime.now(locationFor(timezone));
  }

  static DateTime dateOnlyTodayInTimezone(String? timezone) {
    final now = nowInTimezone(timezone);
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime fromUtcToTenant(DateTime value, String? timezone) {
    return tz.TZDateTime.from(value.toUtc(), locationFor(timezone));
  }

  static DateTime assumeTenantLocal(DateTime value, String? timezone) {
    final location = locationFor(timezone);
    return tz.TZDateTime(
      location,
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
      value.millisecond,
      value.microsecond,
    );
  }

  static DateTime tenantLocalToUtc(DateTime value, String? timezone) {
    final tenantLocal = assumeTenantLocal(value, timezone);
    return tenantLocal.toUtc();
  }
}
