import 'dart:convert';

import 'package:http/http.dart' as http;

// Gestione delle festività nazionali per paese.
// Supporta festività fisse e mobili (come Pasqua e derivate).

/// Rappresenta una festività nazionale.
class PublicHoliday {
  final DateTime date;
  final String name;
  final String nameEn;

  const PublicHoliday({
    required this.date,
    required this.name,
    required this.nameEn,
  });
}

/// Calcola le festività per un determinato paese e anno.
abstract class PublicHolidaysProvider {
  /// Restituisce tutte le festività per l'anno specificato.
  List<PublicHoliday> getHolidays(int year);

  /// Calcola la data di Pasqua per un anno (algoritmo di Gauss/Meeus).
  static DateTime calculateEaster(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(year, month, day);
  }
}

/// Festività italiane.
class ItalianHolidaysProvider extends PublicHolidaysProvider {
  @override
  List<PublicHoliday> getHolidays(int year) {
    final easter = PublicHolidaysProvider.calculateEaster(year);

    return [
      // Festività fisse
      PublicHoliday(
        date: DateTime(year, 1, 1),
        name: 'Capodanno',
        nameEn: "New Year's Day",
      ),
      PublicHoliday(
        date: DateTime(year, 1, 6),
        name: 'Epifania',
        nameEn: 'Epiphany',
      ),
      PublicHoliday(
        date: DateTime(year, 4, 25),
        name: 'Festa della Liberazione',
        nameEn: 'Liberation Day',
      ),
      PublicHoliday(
        date: DateTime(year, 5, 1),
        name: 'Festa dei Lavoratori',
        nameEn: 'Labour Day',
      ),
      PublicHoliday(
        date: DateTime(year, 6, 2),
        name: 'Festa della Repubblica',
        nameEn: 'Republic Day',
      ),
      PublicHoliday(
        date: DateTime(year, 8, 15),
        name: 'Ferragosto',
        nameEn: 'Assumption of Mary',
      ),
      PublicHoliday(
        date: DateTime(year, 11, 1),
        name: 'Tutti i Santi',
        nameEn: "All Saints' Day",
      ),
      PublicHoliday(
        date: DateTime(year, 12, 8),
        name: 'Immacolata Concezione',
        nameEn: 'Immaculate Conception',
      ),
      PublicHoliday(
        date: DateTime(year, 12, 25),
        name: 'Natale',
        nameEn: 'Christmas Day',
      ),
      PublicHoliday(
        date: DateTime(year, 12, 26),
        name: 'Santo Stefano',
        nameEn: "St. Stephen's Day",
      ),
      // Festività mobili (dipendono da Pasqua)
      PublicHoliday(date: easter, name: 'Pasqua', nameEn: 'Easter Sunday'),
      PublicHoliday(
        date: easter.add(const Duration(days: 1)),
        name: 'Lunedì dell\'Angelo',
        nameEn: 'Easter Monday',
      ),
    ]..sort((a, b) => a.date.compareTo(b.date));
  }
}

/// Factory per ottenere il provider di festività per un paese.
class PublicHolidaysFactory {
  static const Map<String, String> _countryAliases = {
    'IT': 'IT',
    'ITALY': 'IT',
    'ITALIA': 'IT',
    'FR': 'FR',
    'FRANCE': 'FR',
    'FRANCIA': 'FR',
    'ES': 'ES',
    'SPAIN': 'ES',
    'SPAGNA': 'ES',
    'DE': 'DE',
    'GERMANY': 'DE',
    'GERMANIA': 'DE',
    'GB': 'GB',
    'UK': 'GB',
    'UNITED KINGDOM': 'GB',
    'REGNO UNITO': 'GB',
    'US': 'US',
    'USA': 'US',
    'UNITED STATES': 'US',
    'STATI UNITI': 'US',
    'CH': 'CH',
    'SWITZERLAND': 'CH',
    'SVIZZERA': 'CH',
    'AT': 'AT',
    'AUSTRIA': 'AT',
    'PT': 'PT',
    'PORTUGAL': 'PT',
    'PORTOGALLO': 'PT',
    'NL': 'NL',
    'NETHERLANDS': 'NL',
    'PAESI BASSI': 'NL',
    'BE': 'BE',
    'BELGIUM': 'BE',
    'BELGIO': 'BE',
  };

  static String? normalizeCountryCode(String? countryCode) {
    if (countryCode == null) return null;
    final normalized = countryCode.toUpperCase().trim();
    return _countryAliases[normalized];
  }

  /// Restituisce il provider di festività per il paese specificato.
  /// Se il paese non è supportato, restituisce null.
  static PublicHolidaysProvider? getProvider(String? countryCode) {
    final isoCode = normalizeCountryCode(countryCode);
    if (isoCode == 'IT') {
      return ItalianHolidaysProvider();
    }
    return null; // Fallback locale attualmente disponibile solo per Italia.
  }

  /// Restituisce true se il paese è supportato.
  static bool isSupported(String? countryCode) {
    return normalizeCountryCode(countryCode) != null;
  }

  /// Restituisce il nome del paese dal codice.
  static String? getCountryName(String? countryCode) {
    switch (normalizeCountryCode(countryCode)) {
      case 'IT':
        return 'Italia';
      case 'FR':
        return 'Francia';
      case 'ES':
        return 'Spagna';
      case 'DE':
        return 'Germania';
      case 'GB':
        return 'Regno Unito';
      case 'US':
        return 'Stati Uniti';
      case 'CH':
        return 'Svizzera';
      case 'AT':
        return 'Austria';
      case 'PT':
        return 'Portogallo';
      case 'NL':
        return 'Paesi Bassi';
      case 'BE':
        return 'Belgio';
      default:
        return null;
    }
  }

  /// Recupera festività nazionali da API pubblica (Nager.Date).
  /// Endpoint: /api/v3/PublicHolidays/{year}/{countryCode}
  static Future<List<PublicHoliday>> fetchHolidaysFromApi({
    required String countryCode,
    required List<int> years,
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;
    final normalizedCountryCode = countryCode.toUpperCase().trim();
    final holidays = <PublicHoliday>[];

    try {
      for (final year in years) {
        final uri = Uri.parse(
          'https://date.nager.at/api/v3/PublicHolidays/$year/$normalizedCountryCode',
        );
        final response = await httpClient
            .get(uri)
            .timeout(const Duration(seconds: 10));
        if (response.statusCode != 200) {
          continue;
        }

        final decoded = jsonDecode(response.body);
        if (decoded is! List) {
          continue;
        }

        for (final rawHoliday in decoded) {
          if (rawHoliday is! Map<String, dynamic>) {
            continue;
          }

          // Considera solo festività nazionali realmente "public":
          // - global == true (non regionali/locali)
          // - types contiene "Public"
          final isGlobal = rawHoliday['global'] == true;
          final types = rawHoliday['types'];
          final isPublicType =
              types is List &&
              types.any(
                (t) => t is String && t.toLowerCase() == 'public',
              );
          final counties = rawHoliday['counties'];
          final hasRegionalCounties =
              counties is List && counties.isNotEmpty;
          if (!isGlobal || !isPublicType || hasRegionalCounties) {
            continue;
          }

          final dateRaw = rawHoliday['date'] as String?;
          final parsedDate = dateRaw != null ? DateTime.tryParse(dateRaw) : null;
          if (parsedDate == null) {
            continue;
          }

          final localName = (rawHoliday['localName'] as String?)?.trim();
          final englishName = (rawHoliday['name'] as String?)?.trim();
          final displayName =
              (localName != null && localName.isNotEmpty)
              ? localName
              : (englishName ?? '');
          if (displayName.isEmpty) {
            continue;
          }

          holidays.add(
            PublicHoliday(
              date: DateTime(
                parsedDate.year,
                parsedDate.month,
                parsedDate.day,
              ),
              name: displayName,
              nameEn:
                  (englishName != null && englishName.isNotEmpty)
                  ? englishName
                  : displayName,
            ),
          );
        }
      }
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }

    final seen = <String>{};
    final deduplicated = <PublicHoliday>[];
    for (final holiday in holidays) {
      final key =
          '${holiday.date.year}-${holiday.date.month}-${holiday.date.day}-${holiday.name.toLowerCase()}';
      if (seen.add(key)) {
        deduplicated.add(holiday);
      }
    }
    deduplicated.sort((a, b) => a.date.compareTo(b.date));
    return deduplicated;
  }
}
