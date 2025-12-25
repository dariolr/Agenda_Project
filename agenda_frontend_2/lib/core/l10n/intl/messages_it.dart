// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a it locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'it';

  static String m0(id) => "Codice prenotazione: ${id}";

  static String m1(date) => "Prima disponibilità: ${date}";

  static String m2(hours) => "${hours} ora";

  static String m3(hours, minutes) => "${hours} ora ${minutes} min";

  static String m4(minutes) => "${minutes} min";

  static String m5(minutes) => "${minutes} min";

  static String m6(path) => "Pagina non trovata: ${path}";

  static String m7(price) => "€${price}";

  static String m8(duration) => "${duration} min";

  static String m9(price) => "da ${price}";

  static String m10(count) =>
      "${Intl.plural(count, zero: 'Nessun servizio selezionato', one: '1 servizio selezionato', other: '${count} servizi selezionati')}";

  static String m11(total) => "Totale: ${total}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "actionBack": MessageLookupByLibrary.simpleMessage("Indietro"),
    "actionCancel": MessageLookupByLibrary.simpleMessage("Annulla"),
    "actionClose": MessageLookupByLibrary.simpleMessage("Chiudi"),
    "actionConfirm": MessageLookupByLibrary.simpleMessage("Conferma"),
    "actionLogin": MessageLookupByLibrary.simpleMessage("Accedi"),
    "actionLogout": MessageLookupByLibrary.simpleMessage("Esci"),
    "actionNext": MessageLookupByLibrary.simpleMessage("Avanti"),
    "actionRegister": MessageLookupByLibrary.simpleMessage("Registrati"),
    "actionRetry": MessageLookupByLibrary.simpleMessage("Riprova"),
    "appTitle": MessageLookupByLibrary.simpleMessage("Prenota Online"),
    "authConfirmPassword": MessageLookupByLibrary.simpleMessage(
      "Conferma password",
    ),
    "authEmail": MessageLookupByLibrary.simpleMessage("Email"),
    "authFirstName": MessageLookupByLibrary.simpleMessage("Nome"),
    "authForgotPassword": MessageLookupByLibrary.simpleMessage(
      "Password dimenticata?",
    ),
    "authHaveAccount": MessageLookupByLibrary.simpleMessage(
      "Hai già un account?",
    ),
    "authInvalidEmail": MessageLookupByLibrary.simpleMessage(
      "Email non valida",
    ),
    "authInvalidPassword": MessageLookupByLibrary.simpleMessage(
      "Password troppo corta (min. 6 caratteri)",
    ),
    "authInvalidPhone": MessageLookupByLibrary.simpleMessage(
      "Numero di telefono non valido",
    ),
    "authLastName": MessageLookupByLibrary.simpleMessage("Cognome"),
    "authLoginFailed": MessageLookupByLibrary.simpleMessage(
      "Credenziali non valide",
    ),
    "authLoginSuccess": MessageLookupByLibrary.simpleMessage(
      "Accesso effettuato",
    ),
    "authLoginTitle": MessageLookupByLibrary.simpleMessage(
      "Accedi al tuo account",
    ),
    "authNoAccount": MessageLookupByLibrary.simpleMessage(
      "Non hai un account?",
    ),
    "authPassword": MessageLookupByLibrary.simpleMessage("Password"),
    "authPasswordMismatch": MessageLookupByLibrary.simpleMessage(
      "Le password non coincidono",
    ),
    "authPhone": MessageLookupByLibrary.simpleMessage("Telefono"),
    "authRegisterFailed": MessageLookupByLibrary.simpleMessage(
      "Registrazione fallita",
    ),
    "authRegisterSuccess": MessageLookupByLibrary.simpleMessage(
      "Registrazione completata",
    ),
    "authRegisterTitle": MessageLookupByLibrary.simpleMessage(
      "Crea un nuovo account",
    ),
    "authRequiredField": MessageLookupByLibrary.simpleMessage(
      "Campo obbligatorio",
    ),
    "authResetPasswordError": MessageLookupByLibrary.simpleMessage(
      "Errore durante l\'invio. Riprova.",
    ),
    "authResetPasswordMessage": MessageLookupByLibrary.simpleMessage(
      "Inserisci la tua email e ti invieremo le istruzioni per reimpostare la password.",
    ),
    "authResetPasswordSend": MessageLookupByLibrary.simpleMessage("Invia"),
    "authResetPasswordSuccess": MessageLookupByLibrary.simpleMessage(
      "Email inviata! Controlla la tua casella di posta.",
    ),
    "authResetPasswordTitle": MessageLookupByLibrary.simpleMessage(
      "Recupera password",
    ),
    "authWelcome": MessageLookupByLibrary.simpleMessage("Benvenuto"),
    "bookingStepDateTime": MessageLookupByLibrary.simpleMessage("Data e ora"),
    "bookingStepServices": MessageLookupByLibrary.simpleMessage("Servizi"),
    "bookingStepStaff": MessageLookupByLibrary.simpleMessage("Operatore"),
    "bookingStepSummary": MessageLookupByLibrary.simpleMessage("Riepilogo"),
    "bookingTitle": MessageLookupByLibrary.simpleMessage(
      "Prenota appuntamento",
    ),
    "confirmationBookingId": m0,
    "confirmationGoHome": MessageLookupByLibrary.simpleMessage(
      "Torna alla home",
    ),
    "confirmationNewBooking": MessageLookupByLibrary.simpleMessage(
      "Nuova prenotazione",
    ),
    "confirmationSubtitle": MessageLookupByLibrary.simpleMessage(
      "Ti abbiamo inviato un\'email di conferma",
    ),
    "confirmationTitle": MessageLookupByLibrary.simpleMessage(
      "Prenotazione confermata!",
    ),
    "dateTimeAfternoon": MessageLookupByLibrary.simpleMessage("Pomeriggio"),
    "dateTimeEvening": MessageLookupByLibrary.simpleMessage("Sera"),
    "dateTimeFirstAvailable": m1,
    "dateTimeMorning": MessageLookupByLibrary.simpleMessage("Mattina"),
    "dateTimeNoSlots": MessageLookupByLibrary.simpleMessage(
      "Nessun orario disponibile per questa data",
    ),
    "dateTimeSelectDate": MessageLookupByLibrary.simpleMessage(
      "Seleziona una data",
    ),
    "dateTimeSubtitle": MessageLookupByLibrary.simpleMessage(
      "Seleziona quando desideri prenotare",
    ),
    "dateTimeTitle": MessageLookupByLibrary.simpleMessage("Scegli data e ora"),
    "durationHour": m2,
    "durationHourMinute": m3,
    "durationMinute": m4,
    "durationMinutes": m5,
    "errorGeneric": MessageLookupByLibrary.simpleMessage(
      "Si è verificato un errore",
    ),
    "errorLoadingAvailability": MessageLookupByLibrary.simpleMessage(
      "Errore nel caricamento delle disponibilità",
    ),
    "errorLoadingServices": MessageLookupByLibrary.simpleMessage(
      "Errore nel caricamento dei servizi",
    ),
    "errorLoadingStaff": MessageLookupByLibrary.simpleMessage(
      "Errore nel caricamento degli operatori",
    ),
    "errorNoAvailability": MessageLookupByLibrary.simpleMessage(
      "Nessuna disponibilità per la data selezionata",
    ),
    "errorNotFound": m6,
    "errorTitle": MessageLookupByLibrary.simpleMessage("Errore"),
    "monthApril": MessageLookupByLibrary.simpleMessage("Aprile"),
    "monthAugust": MessageLookupByLibrary.simpleMessage("Agosto"),
    "monthDecember": MessageLookupByLibrary.simpleMessage("Dicembre"),
    "monthFebruary": MessageLookupByLibrary.simpleMessage("Febbraio"),
    "monthJanuary": MessageLookupByLibrary.simpleMessage("Gennaio"),
    "monthJuly": MessageLookupByLibrary.simpleMessage("Luglio"),
    "monthJune": MessageLookupByLibrary.simpleMessage("Giugno"),
    "monthMarch": MessageLookupByLibrary.simpleMessage("Marzo"),
    "monthMay": MessageLookupByLibrary.simpleMessage("Maggio"),
    "monthNovember": MessageLookupByLibrary.simpleMessage("Novembre"),
    "monthOctober": MessageLookupByLibrary.simpleMessage("Ottobre"),
    "monthSeptember": MessageLookupByLibrary.simpleMessage("Settembre"),
    "priceFormat": m7,
    "servicesDuration": m8,
    "servicesFree": MessageLookupByLibrary.simpleMessage("Gratis"),
    "servicesPriceFrom": m9,
    "servicesSelected": m10,
    "servicesSubtitle": MessageLookupByLibrary.simpleMessage(
      "Puoi selezionare uno o più servizi",
    ),
    "servicesTitle": MessageLookupByLibrary.simpleMessage("Scegli i servizi"),
    "servicesTotal": m11,
    "staffAnyOperator": MessageLookupByLibrary.simpleMessage(
      "Qualsiasi operatore disponibile",
    ),
    "staffAnyOperatorSubtitle": MessageLookupByLibrary.simpleMessage(
      "Ti assegneremo il primo operatore libero",
    ),
    "staffSubtitle": MessageLookupByLibrary.simpleMessage(
      "Seleziona con chi desideri essere servito",
    ),
    "staffTitle": MessageLookupByLibrary.simpleMessage("Scegli l\'operatore"),
    "summaryDateTime": MessageLookupByLibrary.simpleMessage("Data e ora"),
    "summaryDuration": MessageLookupByLibrary.simpleMessage("Durata totale"),
    "summaryNotes": MessageLookupByLibrary.simpleMessage("Note (opzionale)"),
    "summaryNotesHint": MessageLookupByLibrary.simpleMessage(
      "Aggiungi eventuali note per l\'appuntamento...",
    ),
    "summaryOperator": MessageLookupByLibrary.simpleMessage("Operatore"),
    "summaryPrice": MessageLookupByLibrary.simpleMessage("Prezzo totale"),
    "summaryServices": MessageLookupByLibrary.simpleMessage(
      "Servizi selezionati",
    ),
    "summarySubtitle": MessageLookupByLibrary.simpleMessage(
      "Controlla i dettagli prima di confermare",
    ),
    "summaryTitle": MessageLookupByLibrary.simpleMessage(
      "Riepilogo prenotazione",
    ),
    "validationInvalidEmail": MessageLookupByLibrary.simpleMessage(
      "Email non valida",
    ),
    "validationInvalidPhone": MessageLookupByLibrary.simpleMessage(
      "Telefono non valido",
    ),
    "validationRequired": MessageLookupByLibrary.simpleMessage(
      "Campo obbligatorio",
    ),
    "weekdayFri": MessageLookupByLibrary.simpleMessage("Ven"),
    "weekdayMon": MessageLookupByLibrary.simpleMessage("Lun"),
    "weekdaySat": MessageLookupByLibrary.simpleMessage("Sab"),
    "weekdaySun": MessageLookupByLibrary.simpleMessage("Dom"),
    "weekdayThu": MessageLookupByLibrary.simpleMessage("Gio"),
    "weekdayTue": MessageLookupByLibrary.simpleMessage("Mar"),
    "weekdayWed": MessageLookupByLibrary.simpleMessage("Mer"),
  };
}
