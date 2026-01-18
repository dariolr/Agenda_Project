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

  static String m7(days) =>
      "${Intl.plural(days, one: 'Modificabile fino a domani', other: 'Modificabile fino a ${days} giorni')}";

  static String m8(hours) =>
      "${Intl.plural(hours, one: 'Modificabile fino a 1 ora', other: 'Modificabile fino a ${hours} ore')}";

  static String m9(minutes) =>
      "${Intl.plural(minutes, one: 'Modificabile fino a 1 minuto', other: 'Modificabile fino a ${minutes} minuti')}";

  static String m10(price) => "€${price}";

  static String m11(duration) => "${duration} min";

  static String m12(price) => "da ${price}";

  static String m13(count) =>
      "${Intl.plural(count, zero: 'Nessun servizio selezionato', one: '1 servizio selezionato', other: '${count} servizi selezionati')}";

  static String m14(total) => "Totale: ${total}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "actionBack": MessageLookupByLibrary.simpleMessage("Indietro"),
    "actionCancel": MessageLookupByLibrary.simpleMessage("Annulla"),
    "actionClose": MessageLookupByLibrary.simpleMessage("Chiudi"),
    "actionConfirm": MessageLookupByLibrary.simpleMessage("Conferma"),
    "actionDelete": MessageLookupByLibrary.simpleMessage("Cancella"),
    "actionLogin": MessageLookupByLibrary.simpleMessage("Accedi"),
    "actionLogout": MessageLookupByLibrary.simpleMessage("Esci"),
    "actionNext": MessageLookupByLibrary.simpleMessage("Avanti"),
    "actionRegister": MessageLookupByLibrary.simpleMessage("Registrati"),
    "actionRetry": MessageLookupByLibrary.simpleMessage("Riprova"),
    "appTitle": MessageLookupByLibrary.simpleMessage("Prenota Online"),
    "authChangePassword": MessageLookupByLibrary.simpleMessage(
      "Cambia password",
    ),
    "authChangePasswordError": MessageLookupByLibrary.simpleMessage(
      "Password attuale non corretta",
    ),
    "authChangePasswordSuccess": MessageLookupByLibrary.simpleMessage(
      "Password modificata con successo",
    ),
    "authChangePasswordTitle": MessageLookupByLibrary.simpleMessage(
      "Cambia password",
    ),
    "authConfirmPassword": MessageLookupByLibrary.simpleMessage(
      "Conferma password",
    ),
    "authCurrentPassword": MessageLookupByLibrary.simpleMessage(
      "Password attuale",
    ),
    "authEmail": MessageLookupByLibrary.simpleMessage("Email"),
    "authEmailAlreadyRegistered": MessageLookupByLibrary.simpleMessage(
      "Questa email è già registrata. Prova ad accedere.",
    ),
    "authErrorAccountDisabled": MessageLookupByLibrary.simpleMessage(
      "Il tuo account è disabilitato",
    ),
    "authErrorEmailAlreadyExists": MessageLookupByLibrary.simpleMessage(
      "Questa email è già registrata. Prova ad accedere.",
    ),
    "authErrorInvalidCredentials": MessageLookupByLibrary.simpleMessage(
      "Email o password non valide",
    ),
    "authErrorInvalidResetToken": MessageLookupByLibrary.simpleMessage(
      "Token di reset password non valido",
    ),
    "authErrorResetTokenExpired": MessageLookupByLibrary.simpleMessage(
      "Token di reset password scaduto",
    ),
    "authErrorSessionRevoked": MessageLookupByLibrary.simpleMessage(
      "Sessione revocata. Effettua di nuovo il login.",
    ),
    "authErrorTokenExpired": MessageLookupByLibrary.simpleMessage(
      "Sessione scaduta. Effettua di nuovo il login.",
    ),
    "authErrorTokenInvalid": MessageLookupByLibrary.simpleMessage(
      "Sessione non valida. Effettua di nuovo il login.",
    ),
    "authErrorWeakPassword": MessageLookupByLibrary.simpleMessage(
      "Password troppo debole. Scegline una più sicura.",
    ),
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
    "authNewPassword": MessageLookupByLibrary.simpleMessage("Nuova password"),
    "authNoAccount": MessageLookupByLibrary.simpleMessage(
      "Non hai un account?",
    ),
    "authPassword": MessageLookupByLibrary.simpleMessage("Password"),
    "authPasswordMismatch": MessageLookupByLibrary.simpleMessage(
      "Le password non coincidono",
    ),
    "authPasswordRequirements": MessageLookupByLibrary.simpleMessage(
      "La password deve contenere: maiuscola, minuscola, numero",
    ),
    "authPasswordTooShort": MessageLookupByLibrary.simpleMessage(
      "Password troppo corta (min. 8 caratteri)",
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
    "authResetPasswordConfirmError": MessageLookupByLibrary.simpleMessage(
      "Token non valido o scaduto",
    ),
    "authResetPasswordConfirmMessage": MessageLookupByLibrary.simpleMessage(
      "Inserisci la nuova password",
    ),
    "authResetPasswordConfirmSuccess": MessageLookupByLibrary.simpleMessage(
      "Password reimpostata con successo!",
    ),
    "authResetPasswordConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Reimposta password",
    ),
    "authResetPasswordEmailNotFound": MessageLookupByLibrary.simpleMessage(
      "Email non trovata nel sistema. Verifica l\'indirizzo o registrati.",
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
    "bookingCancelFailed": MessageLookupByLibrary.simpleMessage(
      "Errore durante la cancellazione",
    ),
    "bookingCancelled": MessageLookupByLibrary.simpleMessage(
      "Prenotazione cancellata con successo",
    ),
    "bookingErrorInvalidClient": MessageLookupByLibrary.simpleMessage(
      "Il cliente selezionato non è valido",
    ),
    "bookingErrorInvalidLocation": MessageLookupByLibrary.simpleMessage(
      "La sede selezionata non è disponibile",
    ),
    "bookingErrorInvalidService": MessageLookupByLibrary.simpleMessage(
      "Uno o più servizi selezionati non sono disponibili",
    ),
    "bookingErrorInvalidStaff": MessageLookupByLibrary.simpleMessage(
      "L\'operatore selezionato non è disponibile per questi servizi",
    ),
    "bookingErrorInvalidTime": MessageLookupByLibrary.simpleMessage(
      "L\'orario selezionato non è valido",
    ),
    "bookingErrorNotFound": MessageLookupByLibrary.simpleMessage(
      "Prenotazione non trovata",
    ),
    "bookingErrorOutsideWorkingHours": MessageLookupByLibrary.simpleMessage(
      "L\'orario selezionato è fuori dall\'orario di lavoro",
    ),
    "bookingErrorServer": MessageLookupByLibrary.simpleMessage(
      "Si è verificato un errore. Riprova più tardi",
    ),
    "bookingErrorSlotConflict": MessageLookupByLibrary.simpleMessage(
      "L\'orario selezionato non è più disponibile",
    ),
    "bookingErrorStaffUnavailable": MessageLookupByLibrary.simpleMessage(
      "L\'operatore selezionato non è disponibile in questo orario",
    ),
    "bookingErrorUnauthorized": MessageLookupByLibrary.simpleMessage(
      "Non sei autorizzato a completare questa azione",
    ),
    "bookingErrorValidation": MessageLookupByLibrary.simpleMessage(
      "Controlla i dati inseriti",
    ),
    "bookingRescheduled": MessageLookupByLibrary.simpleMessage(
      "Prenotazione modificata con successo",
    ),
    "bookingStepDateTime": MessageLookupByLibrary.simpleMessage("Data e ora"),
    "bookingStepLocation": MessageLookupByLibrary.simpleMessage("Sede"),
    "bookingStepServices": MessageLookupByLibrary.simpleMessage("Servizi"),
    "bookingStepStaff": MessageLookupByLibrary.simpleMessage("Operatore"),
    "bookingStepSummary": MessageLookupByLibrary.simpleMessage("Riepilogo"),
    "bookingTitle": MessageLookupByLibrary.simpleMessage(
      "Prenota appuntamento",
    ),
    "bookingUpdatedTitle": MessageLookupByLibrary.simpleMessage(
      "Prenotazione aggiornata",
    ),
    "businessNotFound": MessageLookupByLibrary.simpleMessage(
      "Attività non trovata",
    ),
    "businessNotFoundHint": MessageLookupByLibrary.simpleMessage(
      "Verifica l\'indirizzo o contatta direttamente l\'attività.",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("Annulla"),
    "cancelBookingConfirm": MessageLookupByLibrary.simpleMessage(
      "Sei sicuro di voler cancellare questa prenotazione?",
    ),
    "cancelBookingTitle": MessageLookupByLibrary.simpleMessage(
      "Cancella prenotazione",
    ),
    "confirmReschedule": MessageLookupByLibrary.simpleMessage(
      "Conferma modifica",
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
    "currentBooking": MessageLookupByLibrary.simpleMessage(
      "Prenotazione attuale",
    ),
    "dateTimeAfternoon": MessageLookupByLibrary.simpleMessage("Pomeriggio"),
    "dateTimeEvening": MessageLookupByLibrary.simpleMessage("Sera"),
    "dateTimeFirstAvailable": m1,
    "dateTimeGoToFirst": MessageLookupByLibrary.simpleMessage(
      "Vai alla prima data disponibile",
    ),
    "dateTimeGoToNext": MessageLookupByLibrary.simpleMessage(
      "Vai alla prossima data disponibile",
    ),
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
    "errorBusinessNotActive": MessageLookupByLibrary.simpleMessage(
      "Attività non attiva",
    ),
    "errorBusinessNotActiveSubtitle": MessageLookupByLibrary.simpleMessage(
      "Questa attività non è ancora configurata per le prenotazioni online. Contatta direttamente l\'attività.",
    ),
    "errorBusinessNotFound": MessageLookupByLibrary.simpleMessage(
      "Attività non trovata",
    ),
    "errorBusinessNotFoundSubtitle": MessageLookupByLibrary.simpleMessage(
      "L\'attività richiesta non esiste. Verifica l\'indirizzo o contatta direttamente l\'attività.",
    ),
    "errorConnectionTimeout": MessageLookupByLibrary.simpleMessage(
      "La connessione sta impiegando troppo tempo. Riprova.",
    ),
    "errorGeneric": MessageLookupByLibrary.simpleMessage(
      "Si è verificato un errore",
    ),
    "errorLoadingAvailability": MessageLookupByLibrary.simpleMessage(
      "Impossibile caricare le disponibilità. Verifica la connessione e riprova.",
    ),
    "errorLoadingBookings": MessageLookupByLibrary.simpleMessage(
      "Errore nel caricamento delle prenotazioni",
    ),
    "errorLoadingServices": MessageLookupByLibrary.simpleMessage(
      "Impossibile caricare i servizi. Verifica la connessione e riprova.",
    ),
    "errorLoadingStaff": MessageLookupByLibrary.simpleMessage(
      "Impossibile caricare gli operatori. Verifica la connessione e riprova.",
    ),
    "errorLocationNotFound": MessageLookupByLibrary.simpleMessage(
      "Sede non disponibile",
    ),
    "errorLocationNotFoundSubtitle": MessageLookupByLibrary.simpleMessage(
      "La sede selezionata non è attiva. Contatta l\'attività per maggiori informazioni.",
    ),
    "errorNoAvailability": MessageLookupByLibrary.simpleMessage(
      "Nessuna disponibilità per la data selezionata",
    ),
    "errorNotFound": m6,
    "errorServiceUnavailable": MessageLookupByLibrary.simpleMessage(
      "Servizio temporaneamente non disponibile",
    ),
    "errorServiceUnavailableSubtitle": MessageLookupByLibrary.simpleMessage(
      "Stiamo lavorando per risolvere il problema. Riprova tra qualche minuto.",
    ),
    "errorTitle": MessageLookupByLibrary.simpleMessage("Errore"),
    "loadingAvailability": MessageLookupByLibrary.simpleMessage(
      "Caricamento disponibilità...",
    ),
    "locationEmpty": MessageLookupByLibrary.simpleMessage(
      "Nessuna sede disponibile",
    ),
    "locationSubtitle": MessageLookupByLibrary.simpleMessage(
      "Seleziona dove vuoi effettuare la prenotazione",
    ),
    "locationTitle": MessageLookupByLibrary.simpleMessage("Scegli la sede"),
    "modifiable": MessageLookupByLibrary.simpleMessage("Modificabile"),
    "modifiableUntilDays": m7,
    "modifiableUntilHours": m8,
    "modifiableUntilMinutes": m9,
    "modify": MessageLookupByLibrary.simpleMessage("Modifica"),
    "modifyNotImplemented": MessageLookupByLibrary.simpleMessage(
      "Funzione di modifica in sviluppo",
    ),
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
    "myBookings": MessageLookupByLibrary.simpleMessage("Le mie prenotazioni"),
    "no": MessageLookupByLibrary.simpleMessage("No"),
    "noPastBookings": MessageLookupByLibrary.simpleMessage(
      "Non hai prenotazioni passate",
    ),
    "noStaffForAllServices": MessageLookupByLibrary.simpleMessage(
      "Nessun operatore può eseguire tutti i servizi selezionati. Prova a selezionare meno servizi o servizi diversi.",
    ),
    "noUpcomingBookings": MessageLookupByLibrary.simpleMessage(
      "Non hai prenotazioni in programma",
    ),
    "notModifiable": MessageLookupByLibrary.simpleMessage("Non modificabile"),
    "pastBookings": MessageLookupByLibrary.simpleMessage("Passate"),
    "priceFormat": m10,
    "profileTitle": MessageLookupByLibrary.simpleMessage("Profilo"),
    "rescheduleBookingTitle": MessageLookupByLibrary.simpleMessage(
      "Modifica prenotazione",
    ),
    "selectDate": MessageLookupByLibrary.simpleMessage("Seleziona data"),
    "selectNewDate": MessageLookupByLibrary.simpleMessage(
      "Seleziona nuova data",
    ),
    "selectNewTime": MessageLookupByLibrary.simpleMessage(
      "Seleziona nuovo orario",
    ),
    "servicesDuration": m11,
    "servicesEmpty": MessageLookupByLibrary.simpleMessage(
      "Nessun servizio disponibile al momento",
    ),
    "servicesEmptySubtitle": MessageLookupByLibrary.simpleMessage(
      "Non ci sono servizi prenotabili online per questa attività",
    ),
    "servicesFree": MessageLookupByLibrary.simpleMessage("Gratis"),
    "servicesPriceFrom": m12,
    "servicesSelected": m13,
    "servicesSubtitle": MessageLookupByLibrary.simpleMessage(
      "Puoi selezionare uno o più servizi",
    ),
    "servicesTitle": MessageLookupByLibrary.simpleMessage("Scegli i servizi"),
    "servicesTotal": m14,
    "slotNoLongerAvailable": MessageLookupByLibrary.simpleMessage(
      "Lo slot non è più disponibile. La prenotazione originale è rimasta invariata.",
    ),
    "staffAnyOperator": MessageLookupByLibrary.simpleMessage(
      "Qualsiasi operatore disponibile",
    ),
    "staffAnyOperatorSubtitle": MessageLookupByLibrary.simpleMessage(
      "Ti assegneremo il primo operatore libero",
    ),
    "staffEmpty": MessageLookupByLibrary.simpleMessage(
      "Nessun operatore disponibile al momento",
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
    "upcomingBookings": MessageLookupByLibrary.simpleMessage("Prossime"),
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
    "yes": MessageLookupByLibrary.simpleMessage("Sì"),
  };
}
