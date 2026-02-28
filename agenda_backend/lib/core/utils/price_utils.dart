import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../features/agenda/providers/business_providers.dart';
import '../../features/agenda/providers/location_providers.dart';
import '../l10n/l10_extension.dart'; // ✅ per usare context.l10n
import '../models/service_variant.dart';

/// Utility per formattazione e parsing dei prezzi, coerente con la valuta
/// effettiva del business o della location.
///
/// 🔹 Integra:
/// - Formattazione localizzata tramite [Intl.NumberFormat]
/// - Fallback automatico sul locale corrente
/// - Metodo [parse] per convertire input utente (es. “€45,90”) in `double`
/// - Metodo [formatService] per mostrare prezzo e label standard (“a partire da…”)
class PriceFormatter {
  const PriceFormatter._();

  /// Restituisce la valuta effettiva in base a location o business.
  static String effectiveCurrency(WidgetRef ref) {
    final locationCurrency = ref.watch(currentLocationProvider).currency;
    final businessCurrency = ref.watch(currentBusinessProvider).currency;
    return locationCurrency ?? businessCurrency;
  }

  /// Formatta un prezzo numerico [amount] nella valuta indicata.
  ///
  /// Utilizza sempre il simbolo della valuta e rispetta la locale dell'app.
  static String format({
    required BuildContext context,
    required double amount,
    required String currencyCode,
    String? forcedLocale,
  }) {
    // Locale derivata dal contesto o dal parametro forzato
    final localeFromContext = Localizations.localeOf(context).toString();
    final currentLocale = forcedLocale ?? localeFromContext;

    try {
      // Usa simpleCurrency per ottenere il simbolo (€, $, £, ecc.)
      final formatter = NumberFormat.simpleCurrency(
        name: currencyCode,
        locale: currentLocale,
      );
      return formatter.format(amount);
    } catch (_) {
      // Se la locale non è supportata, prova con la locale dell'app
      try {
        final fallbackFormatter = NumberFormat.simpleCurrency(
          name: currencyCode,
          locale: Intl.getCurrentLocale(),
        );
        return fallbackFormatter.format(amount);
      } catch (_) {
        // Ultimo fallback su 'it_IT' (anziché en_US)
        final lastResortFormatter = NumberFormat.simpleCurrency(
          name: currencyCode,
          locale: 'it_IT',
        );
        return lastResortFormatter.format(amount);
      }
    }
  }

  /// Restituisce il numero di decimali previsto dalla valuta.
  static int decimalDigitsForCurrency(
    String currencyCode, {
    String? forcedLocale,
  }) {
    try {
      final formatter = NumberFormat.simpleCurrency(
        name: currencyCode,
        locale: forcedLocale,
      );
      return formatter.decimalDigits ?? 2;
    } catch (_) {
      return 2;
    }
  }

  /// Converte una stringa di input (es. “€ 45,90”, “45.00”, “CHF 120”) in `double`.
  ///
  /// Rimuove simboli e caratteri non numerici, normalizzando la virgola in punto.
  static double? parse(String input) {
    if (input.trim().isEmpty) return null;

    final cleaned = input
        .replaceAll(RegExp(r'[^0-9,.\-]'), '')
        .replaceAll(',', '.');

    return double.tryParse(cleaned);
  }

  /// Formatta un [ServiceVariant] tenendo conto delle impostazioni di valuta e
  /// dei flag `isFree` e `isPriceStartingFrom`.
  static String formatVariant({
    required BuildContext context,
    required WidgetRef ref,
    required ServiceVariant variant,
  }) {
    final currency = variant.currency ?? effectiveCurrency(ref);

    if (variant.isFree) return context.l10n.freeLabel;
    if (variant.price <= 0) return context.l10n.priceNotAvailable;

    final formatted = format(
      context: context,
      amount: variant.price,
      currencyCode: currency,
    );

    return variant.isPriceStartingFrom
        ? '${context.l10n.priceStartingFromPrefix} $formatted'
        : formatted;
  }
}
