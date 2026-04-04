import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/locale_resolution.dart';
import '../../core/services/preferences_service.dart';

class AppLocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    final code = ref.read(preferencesServiceProvider).getAdminLocaleCode();
    if (code == null) {
      return null;
    }
    return supportedLocaleOrNull(Locale(code));
  }

  Future<void> setLocale(Locale? locale) async {
    final resolved = supportedLocaleOrNull(locale);
    state = resolved;
    unawaited(
      ref.read(preferencesServiceProvider).setAdminLocaleCode(
        resolved?.languageCode,
      ),
    );
  }

  Future<void> clearLocalePreference() => setLocale(null);
}

final appLocaleProvider = NotifierProvider<AppLocaleNotifier, Locale?>(
  AppLocaleNotifier.new,
);

