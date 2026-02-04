// Gestione delle festività nazionali per paese.
//
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
  /// Mappa dei codici paese supportati.
  static const supportedCountries = {'IT': 'Italia', 'Italy': 'Italia'};

  /// Restituisce il provider di festività per il paese specificato.
  /// Se il paese non è supportato, restituisce null.
  static PublicHolidaysProvider? getProvider(String? countryCode) {
    if (countryCode == null) return null;

    final normalized = countryCode.toUpperCase().trim();

    if (normalized == 'IT' || normalized == 'ITALY' || normalized == 'ITALIA') {
      return ItalianHolidaysProvider();
    }

    // Aggiungi altri paesi qui in futuro
    // if (normalized == 'FR' || normalized == 'FRANCE') {
    //   return FrenchHolidaysProvider();
    // }

    return null;
  }

  /// Restituisce true se il paese è supportato.
  static bool isSupported(String? countryCode) {
    return getProvider(countryCode) != null;
  }

  /// Restituisce il nome del paese dal codice.
  static String? getCountryName(String? countryCode) {
    if (countryCode == null) return null;

    final normalized = countryCode.toUpperCase().trim();

    if (normalized == 'IT' || normalized == 'ITALY' || normalized == 'ITALIA') {
      return 'Italia';
    }

    return null;
  }
}
