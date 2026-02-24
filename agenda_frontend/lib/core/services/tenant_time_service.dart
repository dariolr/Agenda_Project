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

  static DateTime todayInTimezone(String? timezone) {
    final now = nowInTimezone(timezone);
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime fromUtcToTenant(DateTime value, String? timezone) {
    return tz.TZDateTime.from(value.toUtc(), locationFor(timezone));
  }

  static DateTime parseAsLocationTime(String isoString) {
    final withoutOffset = isoString.replaceAll(RegExp(r'[+-]\d{2}:\d{2}$'), '');
    final cleaned = withoutOffset.replaceAll('Z', '');
    return DateTime.parse(cleaned);
  }
}
