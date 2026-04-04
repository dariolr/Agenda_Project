import 'package:agenda_frontend/core/l10n/booking_locale_resolver.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const supported = [Locale('it'), Locale('en')];

  test('URL lang override has highest priority', () {
    final resolved = BookingLocaleResolver.resolveLanguageCode(
      supportedLocales: supported,
      urlLang: 'en',
      locationDefaultLocale: 'it',
      deviceLocales: const [Locale('it')],
      locationCountry: 'IT',
    );
    expect(resolved, 'en');
  });

  test('location booking default locale is used when URL lang is missing', () {
    final resolved = BookingLocaleResolver.resolveLanguageCode(
      supportedLocales: supported,
      locationDefaultLocale: 'en',
      deviceLocales: const [Locale('it')],
      locationCountry: 'IT',
    );
    expect(resolved, 'en');
  });

  test('browser/device locale is used as fallback when supported', () {
    final resolved = BookingLocaleResolver.resolveLanguageCode(
      supportedLocales: supported,
      deviceLocales: const [Locale('en', 'US')],
      locationCountry: 'IT',
    );
    expect(resolved, 'en');
  });

  test('country hint is used only when previous sources are missing', () {
    final resolved = BookingLocaleResolver.resolveLanguageCode(
      supportedLocales: supported,
      deviceLocales: const [Locale('fr')],
      locationCountry: 'IT',
    );
    expect(resolved, 'it');
  });

  test('deterministic final fallback is it', () {
    final resolved = BookingLocaleResolver.resolveLanguageCode(
      supportedLocales: supported,
      deviceLocales: const [Locale('fr')],
      locationCountry: 'TH',
    );
    expect(resolved, 'it');
  });
}

