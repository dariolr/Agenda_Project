import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Richiesta one-shot di mostrare lo spotlight che indica dove sono le
/// prenotazioni (icona profilo in alto a destra). Viene impostata a `true`
/// dallo step di conferma alla primissima prenotazione e consumata (riportata
/// a `false`) dall'app bar che possiede l'icona.
final profileTutorialRequestProvider = StateProvider<bool>((ref) => false);

/// Persistenza del flag "tutorial profilo già mostrato", così lo spotlight
/// compare una sola volta per ciascun utente (la chiave include l'id utente).
class BookingTutorialStorage {
  static String _profileSpotlightShownKey(int userId) =>
      'profile_bookings_tutorial_shown_$userId';

  static Future<bool> hasShownProfileSpotlight(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_profileSpotlightShownKey(userId)) ?? false;
  }

  static Future<void> markProfileSpotlightShown(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_profileSpotlightShownKey(userId), true);
  }
}
