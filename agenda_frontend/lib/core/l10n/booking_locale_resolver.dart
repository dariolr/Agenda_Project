import 'package:flutter/widgets.dart';

class BookingLocaleResolver {
  static const String fallbackLanguageCode = 'it';
  static const Set<String> _countryHintItalian = {'IT', 'SM', 'VA'};
  static const Set<String> _countryHintEnglish = {
    'US',
    'GB',
    'IE',
    'AU',
    'CA',
    'NZ',
  };

  static String? normalizeLanguageCode(String? value) {
    final raw = value?.trim().toLowerCase();
    if (raw == null || raw.isEmpty) return null;
    if (raw.contains('-')) return raw.split('-').first;
    if (raw.contains('_')) return raw.split('_').first;
    return raw;
  }

  static String resolveLanguageCode({
    required Iterable<Locale> supportedLocales,
    String? urlLang,
    String? locationDefaultLocale,
    Iterable<Locale>? deviceLocales,
    String? locationCountry,
  }) {
    final supportedCodes = supportedLocales
        .map((l) => l.languageCode.toLowerCase())
        .toSet();

    String? pick(String? candidate) {
      final code = normalizeLanguageCode(candidate);
      if (code == null) return null;
      return supportedCodes.contains(code) ? code : null;
    }

    final fromUrl = pick(urlLang);
    if (fromUrl != null) return fromUrl;

    final fromLocation = pick(locationDefaultLocale);
    if (fromLocation != null) return fromLocation;

    for (final locale in deviceLocales ?? const <Locale>[]) {
      final fromDevice = pick(locale.toLanguageTag());
      if (fromDevice != null) return fromDevice;
    }

    final country = (locationCountry ?? '').trim().toUpperCase();
    if (_countryHintItalian.contains(country) && supportedCodes.contains('it')) {
      return 'it';
    }
    if (_countryHintEnglish.contains(country) &&
        supportedCodes.contains('en')) {
      return 'en';
    }

    if (supportedCodes.contains(fallbackLanguageCode)) {
      return fallbackLanguageCode;
    }
    return supportedLocales.first.languageCode.toLowerCase();
  }
}

