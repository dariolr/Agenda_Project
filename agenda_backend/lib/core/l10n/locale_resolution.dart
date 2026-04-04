import 'package:flutter/widgets.dart';

import 'l10n.dart';

const Locale _fallbackLocale = Locale('it');

Locale resolveSupportedLocale(
  Locale? candidate, {
  Iterable<Locale>? supportedLocales,
}) {
  final supported = (supportedLocales ?? L10n.delegate.supportedLocales)
      .toList(growable: false);
  if (candidate != null) {
    for (final locale in supported) {
      if (locale.languageCode.toLowerCase() ==
          candidate.languageCode.toLowerCase()) {
        return locale;
      }
    }
  }
  for (final locale in supported) {
    if (locale.languageCode.toLowerCase() ==
        _fallbackLocale.languageCode.toLowerCase()) {
      return locale;
    }
  }
  return supported.first;
}

Locale? supportedLocaleOrNull(
  Locale? candidate, {
  Iterable<Locale>? supportedLocales,
}) {
  if (candidate == null) return null;
  final supported = (supportedLocales ?? L10n.delegate.supportedLocales)
      .toList(growable: false);
  for (final locale in supported) {
    if (locale.languageCode.toLowerCase() ==
        candidate.languageCode.toLowerCase()) {
      return locale;
    }
  }
  return null;
}
