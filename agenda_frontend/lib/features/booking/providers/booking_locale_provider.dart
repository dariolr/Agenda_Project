import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/booking_locale_resolver.dart';
import '../../../core/l10n/l10n.dart';
import 'locations_provider.dart';

class BookingUrlLangNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setFromQueryParam(String? raw) {
    state = BookingLocaleResolver.normalizeLanguageCode(raw);
  }
}

final bookingUrlLangProvider = NotifierProvider<BookingUrlLangNotifier, String?>(
  BookingUrlLangNotifier.new,
);

final bookingResolvedLocaleProvider = Provider<Locale>((ref) {
  final urlLang = ref.watch(bookingUrlLangProvider);
  final location = ref.watch(effectiveLocationProvider);
  final supported = L10n.delegate.supportedLocales;
  final languageCode = BookingLocaleResolver.resolveLanguageCode(
    supportedLocales: supported,
    urlLang: urlLang,
    locationDefaultLocale: location?.bookingDefaultLocale,
    deviceLocales: WidgetsBinding.instance.platformDispatcher.locales,
    locationCountry: location?.country,
  );
  return Locale(languageCode);
});

