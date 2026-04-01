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

  static String m0(message) => "Errore di validazione: ${message}";

  static String m1(label) => "Scegli ${label}";

  static String m2(locationLabel) =>
      "${locationLabel} selezionata non è disponibile";

  static String m3(serviceLabel) =>
      "Uno o più ${serviceLabel} selezionati non sono disponibili";

  static String m4(staffLabel, serviceLabel) =>
      "${staffLabel} selezionato non è disponibile per questi ${serviceLabel}";

  static String m5(serviceLabel) =>
      "Impossibile recuperare i ${serviceLabel} della prenotazione";

  static String m6(staffLabel) =>
      "${staffLabel} selezionato non è disponibile in questo orario";

  static String m7(fields) => "Campi modificati: ${fields}";

  static String m8(type) => "Inviata email di tipo: ${type}";

  static String m9(email) => "Destinatario: ${email}";

  static String m10(dateTime) => "Data invio: ${dateTime}";

  static String m11(id) => "Codice prenotazione: ${id}";

  static String m12(date) => "Prima disponibilità: ${date}";

  static String m13(hours) => "${hours} ora";

  static String m14(hours, minutes) => "${hours} ora ${minutes} min";

  static String m15(minutes) => "${minutes} min";

  static String m16(minutes) => "${minutes} min";

  static String m17(path) => "Pagina non trovata: ${path}";

  static String m18(label) => "${label} temporaneamente non disponibile";

  static String m19(label) => "Nessun ${label} disponibile";

  static String m20(dateTime) => "Modificabile fino al ${dateTime}";

  static String m21(days) =>
      "${Intl.plural(days, one: 'Modificabile fino a domani', other: 'Modificabile fino a ${days} giorni')}";

  static String m22(hours) =>
      "${Intl.plural(hours, one: 'Modificabile fino a 1 ora', other: 'Modificabile fino a ${hours} ore')}";

  static String m23(minutes) =>
      "${Intl.plural(minutes, one: 'Modificabile fino a 1 minuto', other: 'Modificabile fino a ${minutes} minuti')}";

  static String m24(dateTime) =>
      "Il termine per modificare o annullare è scaduto il ${dateTime}.";

  static String m25(staffLabel, serviceLabel) =>
      "Nessun ${staffLabel} può eseguire tutti i ${serviceLabel} selezionati. Prova a selezionare meno ${serviceLabel} o ${serviceLabel} diversi.";

  static String m26(price) => "€${price}";

  static String m27(id) => "Categoria ${id}";

  static String m28(duration) => "${duration} min";

  static String m29(label) => "Nessun ${label} disponibile al momento";

  static String m30(label) =>
      "Non ci sono ${label} prenotabili online per questa attività";

  static String m31(price) => "da ${price}";

  static String m32(count) =>
      "${Intl.plural(count, zero: 'Nessun servizio selezionato', one: '1 servizio selezionato', other: '${count} servizi selezionati')}";

  static String m33(count, label) => "${count} ${label} selezionati";

  static String m34(label) => "Nessun ${label} selezionato";

  static String m35(label) => "1 ${label} selezionato";

  static String m36(label) => "Puoi selezionare uno o più ${label}";

  static String m37(total) => "Totale: ${total}";

  static String m38(label) => "Qualsiasi ${label} disponibile";

  static String m39(label) => "Ti assegneremo il primo ${label} disponibile";

  static String m40(label) => "Nessun ${label} disponibile al momento";

  static String m41(label) => "Seleziona ${label} che preferisci";

  static String m42(days) =>
      "${Intl.plural(days, one: 'Fino a 1 giorno prima', other: 'Fino a ${days} giorni prima')}";

  static String m43(hours) => "Fino a ${hours} ore prima";

  static String m44(label) => "${label} selezionati";

  static String m45(businessName) =>
      "Per prenotare su ${businessName}, devi accedere con un account registrato qui.";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "actionBack": MessageLookupByLibrary.simpleMessage("Indietro"),
    "actionCancel": MessageLookupByLibrary.simpleMessage("Annulla"),
    "actionCancelBooking": MessageLookupByLibrary.simpleMessage("Annulla"),
    "actionClose": MessageLookupByLibrary.simpleMessage("Chiudi"),
    "actionConfirm": MessageLookupByLibrary.simpleMessage("Conferma"),
    "actionDelete": MessageLookupByLibrary.simpleMessage("Elimina"),
    "actionLogin": MessageLookupByLibrary.simpleMessage("Accedi"),
    "actionLogout": MessageLookupByLibrary.simpleMessage("Esci"),
    "actionNext": MessageLookupByLibrary.simpleMessage("Avanti"),
    "actionRegister": MessageLookupByLibrary.simpleMessage("Registrati"),
    "actionRetry": MessageLookupByLibrary.simpleMessage("Riprova"),
    "appTitle": MessageLookupByLibrary.simpleMessage("Prenota Online"),
    "authBusinessNotFound": MessageLookupByLibrary.simpleMessage(
      "Impossibile caricare le informazioni del business. Riprova.",
    ),
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
      "La password deve contenere almeno 8 caratteri, una maiuscola, una minuscola e un numero",
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
    "authPasswordValidationError": m0,
    "authPhone": MessageLookupByLibrary.simpleMessage("Telefono"),
    "authRedirectFromBooking": MessageLookupByLibrary.simpleMessage(
      "Per prenotare un appuntamento, accedi con il tuo account o registrati se non ne hai ancora uno.",
    ),
    "authRedirectFromMyBookings": MessageLookupByLibrary.simpleMessage(
      "Per visualizzare i tuoi appuntamenti, accedi con il tuo account o registrati se non ne hai ancora uno.",
    ),
    "authRegisterFailed": MessageLookupByLibrary.simpleMessage(
      "Registrazione fallita",
    ),
    "authRegisterSuccess": MessageLookupByLibrary.simpleMessage(
      "Registrazione completata",
    ),
    "authRegisterTitle": MessageLookupByLibrary.simpleMessage(
      "Crea un nuovo account",
    ),
    "authRememberMe": MessageLookupByLibrary.simpleMessage("Ricordami"),
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
    "blockedCustomerContactMessage": MessageLookupByLibrary.simpleMessage(
      "Per qualsiasi esigenza sugli appuntamenti ti invitiamo a contattarci. Grazie",
    ),
    "bookingCancelFailed": MessageLookupByLibrary.simpleMessage(
      "Errore durante l\'annullamento della prenotazione. Riprova.",
    ),
    "bookingCancelled": MessageLookupByLibrary.simpleMessage(
      "Prenotazione annullata con successo",
    ),
    "bookingChooseCustomLabel": m1,
    "bookingErrorInvalidClient": MessageLookupByLibrary.simpleMessage(
      "Il cliente selezionato non è valido",
    ),
    "bookingErrorInvalidLocation": MessageLookupByLibrary.simpleMessage(
      "La sede selezionata non è disponibile",
    ),
    "bookingErrorInvalidLocationCustom": m2,
    "bookingErrorInvalidService": MessageLookupByLibrary.simpleMessage(
      "Uno o più servizi selezionati non sono disponibili",
    ),
    "bookingErrorInvalidServiceCustom": m3,
    "bookingErrorInvalidStaff": MessageLookupByLibrary.simpleMessage(
      "L\'operatore selezionato non è disponibile per questi servizi",
    ),
    "bookingErrorInvalidStaffCustom": m4,
    "bookingErrorInvalidTime": MessageLookupByLibrary.simpleMessage(
      "L\'orario selezionato non è valido",
    ),
    "bookingErrorMissingServices": MessageLookupByLibrary.simpleMessage(
      "Impossibile recuperare i servizi della prenotazione",
    ),
    "bookingErrorMissingServicesCustom": m5,
    "bookingErrorNotFound": MessageLookupByLibrary.simpleMessage(
      "Prenotazione non trovata",
    ),
    "bookingErrorNotModifiable": MessageLookupByLibrary.simpleMessage(
      "Questa prenotazione non può essere modificata",
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
    "bookingErrorStaffUnavailableCustom": m6,
    "bookingErrorUnauthorized": MessageLookupByLibrary.simpleMessage(
      "Non sei autorizzato a completare questa azione",
    ),
    "bookingErrorValidation": MessageLookupByLibrary.simpleMessage(
      "Controlla i dati inseriti",
    ),
    "bookingHistoryActorCustomer": MessageLookupByLibrary.simpleMessage(
      "Cliente",
    ),
    "bookingHistoryActorStaff": MessageLookupByLibrary.simpleMessage("Staff"),
    "bookingHistoryActorSystem": MessageLookupByLibrary.simpleMessage(
      "Sistema",
    ),
    "bookingHistoryChangedFields": m7,
    "bookingHistoryEmpty": MessageLookupByLibrary.simpleMessage(
      "Nessun evento registrato",
    ),
    "bookingHistoryError": MessageLookupByLibrary.simpleMessage(
      "Errore nel caricamento dello storico",
    ),
    "bookingHistoryEventAppointmentUpdated":
        MessageLookupByLibrary.simpleMessage("Appuntamento modificato"),
    "bookingHistoryEventCancelled": MessageLookupByLibrary.simpleMessage(
      "Prenotazione annullata",
    ),
    "bookingHistoryEventCreated": MessageLookupByLibrary.simpleMessage(
      "Prenotazione creata",
    ),
    "bookingHistoryEventDurationChanged": MessageLookupByLibrary.simpleMessage(
      "Durata modificata",
    ),
    "bookingHistoryEventItemAdded": MessageLookupByLibrary.simpleMessage(
      "Servizio aggiunto",
    ),
    "bookingHistoryEventItemDeleted": MessageLookupByLibrary.simpleMessage(
      "Servizio rimosso",
    ),
    "bookingHistoryEventNotificationSentTitle": m8,
    "bookingHistoryEventPriceChanged": MessageLookupByLibrary.simpleMessage(
      "Prezzo modificato",
    ),
    "bookingHistoryEventReplaced": MessageLookupByLibrary.simpleMessage(
      "Prenotazione sostituita",
    ),
    "bookingHistoryEventStaffChanged": MessageLookupByLibrary.simpleMessage(
      "Operatore cambiato",
    ),
    "bookingHistoryEventTimeChanged": MessageLookupByLibrary.simpleMessage(
      "Orario modificato",
    ),
    "bookingHistoryEventUpdated": MessageLookupByLibrary.simpleMessage(
      "Prenotazione modificata",
    ),
    "bookingHistoryLoading": MessageLookupByLibrary.simpleMessage(
      "Caricamento storico...",
    ),
    "bookingHistoryNotificationChannelCancelled":
        MessageLookupByLibrary.simpleMessage("Cancellazione prenotazione"),
    "bookingHistoryNotificationChannelConfirmed":
        MessageLookupByLibrary.simpleMessage("Conferma prenotazione"),
    "bookingHistoryNotificationChannelReminder":
        MessageLookupByLibrary.simpleMessage("Promemoria prenotazione"),
    "bookingHistoryNotificationChannelRescheduled":
        MessageLookupByLibrary.simpleMessage("Riprogrammazione prenotazione"),
    "bookingHistoryNotificationRecipient": m9,
    "bookingHistoryNotificationSentAt": m10,
    "bookingHistoryTitle": MessageLookupByLibrary.simpleMessage(
      "Storico prenotazione",
    ),
    "bookingRescheduled": MessageLookupByLibrary.simpleMessage(
      "Prenotazione modificata con successo",
    ),
    "bookingServiceSingularLabel": MessageLookupByLibrary.simpleMessage(
      "servizio",
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
      "Sei sicuro di voler annullare questa prenotazione?",
    ),
    "cancelBookingTitle": MessageLookupByLibrary.simpleMessage(
      "Annulla prenotazione",
    ),
    "cancelledBadge": MessageLookupByLibrary.simpleMessage("ANNULLATA"),
    "cancelledBookings": MessageLookupByLibrary.simpleMessage("Annullate"),
    "confirmReschedule": MessageLookupByLibrary.simpleMessage(
      "Conferma modifica",
    ),
    "confirmationBookingId": m11,
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
    "dateTimeFirstAvailable": m12,
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
    "durationHour": m13,
    "durationHourMinute": m14,
    "durationMinute": m15,
    "durationMinutes": m16,
    "environmentDemoBannerSubtitle": MessageLookupByLibrary.simpleMessage(
      "I dati vengono resettati periodicamente.",
    ),
    "environmentDemoBannerTitle": MessageLookupByLibrary.simpleMessage(
      "AMBIENTE DEMO",
    ),
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
    "errorNotFound": m17,
    "errorServiceUnavailable": MessageLookupByLibrary.simpleMessage(
      "Servizio temporaneamente non disponibile",
    ),
    "errorServiceUnavailableCustom": m18,
    "errorServiceUnavailableSubtitle": MessageLookupByLibrary.simpleMessage(
      "Stiamo lavorando per risolvere il problema. Riprova tra qualche minuto.",
    ),
    "errorTitle": MessageLookupByLibrary.simpleMessage("Errore"),
    "loadingAvailability": MessageLookupByLibrary.simpleMessage(
      "Caricamento disponibilità...",
    ),
    "loadingGeneric": MessageLookupByLibrary.simpleMessage("Caricamento..."),
    "locationEmpty": MessageLookupByLibrary.simpleMessage(
      "Nessuna sede disponibile",
    ),
    "locationEmptyCustom": m19,
    "locationSubtitle": MessageLookupByLibrary.simpleMessage(
      "Seleziona dove vuoi effettuare la prenotazione",
    ),
    "locationTitle": MessageLookupByLibrary.simpleMessage("Scegli la sede"),
    "modifiable": MessageLookupByLibrary.simpleMessage("Modificabile"),
    "modifiableUntilDateTime": m20,
    "modifiableUntilDays": m21,
    "modifiableUntilHours": m22,
    "modifiableUntilMinutes": m23,
    "modificationWindowExpired": MessageLookupByLibrary.simpleMessage(
      "Il tempo per modificare o annullare questa prenotazione è scaduto.",
    ),
    "modificationWindowExpiredDateTime": m24,
    "modify": MessageLookupByLibrary.simpleMessage("Riprogramma"),
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
    "noCancelledBookings": MessageLookupByLibrary.simpleMessage(
      "Non hai prenotazioni annullate",
    ),
    "noPastBookings": MessageLookupByLibrary.simpleMessage(
      "Non hai prenotazioni passate",
    ),
    "noStaffForAllServices": MessageLookupByLibrary.simpleMessage(
      "Nessun operatore può eseguire tutti i servizi selezionati. Prova a selezionare meno servizi o servizi diversi.",
    ),
    "noStaffForAllServicesCustom": m25,
    "noUpcomingBookings": MessageLookupByLibrary.simpleMessage(
      "Non hai prenotazioni in programma",
    ),
    "notModifiable": MessageLookupByLibrary.simpleMessage("Non modificabile"),
    "pastBookings": MessageLookupByLibrary.simpleMessage("Passate"),
    "priceFormat": m26,
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
    "servicePackageExpandError": MessageLookupByLibrary.simpleMessage(
      "Impossibile espandere il pacchetto selezionato.",
    ),
    "servicePackageLabel": MessageLookupByLibrary.simpleMessage("Pacchetto"),
    "servicePackagesLoadError": MessageLookupByLibrary.simpleMessage(
      "Impossibile caricare i pacchetti.",
    ),
    "servicePackagesLoading": MessageLookupByLibrary.simpleMessage(
      "Caricamento pacchetti...",
    ),
    "servicePackagesSubtitle": MessageLookupByLibrary.simpleMessage(
      "Oppure scegli un pacchetto pronto",
    ),
    "servicePackagesTitle": MessageLookupByLibrary.simpleMessage("Pacchetti"),
    "servicesCategoryFallbackName": m27,
    "servicesDuration": m28,
    "servicesEmpty": MessageLookupByLibrary.simpleMessage(
      "Nessun servizio disponibile al momento",
    ),
    "servicesEmptyCustom": m29,
    "servicesEmptySubtitle": MessageLookupByLibrary.simpleMessage(
      "Non ci sono servizi prenotabili online per questa attività",
    ),
    "servicesEmptySubtitleCustom": m30,
    "servicesFree": MessageLookupByLibrary.simpleMessage("Gratis"),
    "servicesPriceFrom": m31,
    "servicesSelected": m32,
    "servicesSelectedManyCustom": m33,
    "servicesSelectedNoneCustom": m34,
    "servicesSelectedOneCustom": m35,
    "servicesSubtitle": MessageLookupByLibrary.simpleMessage(
      "Puoi selezionare uno o più servizi",
    ),
    "servicesSubtitleCustom": m36,
    "servicesTitle": MessageLookupByLibrary.simpleMessage("Scegli i servizi"),
    "servicesTotal": m37,
    "sessionExpired": MessageLookupByLibrary.simpleMessage(
      "Sessione scaduta. Effettua nuovamente l\'accesso.",
    ),
    "slotNoLongerAvailable": MessageLookupByLibrary.simpleMessage(
      "Lo slot non è più disponibile. La prenotazione originale è rimasta invariata.",
    ),
    "staffAnyOperator": MessageLookupByLibrary.simpleMessage(
      "Qualsiasi operatore disponibile",
    ),
    "staffAnyOperatorCustom": m38,
    "staffAnyOperatorSubtitle": MessageLookupByLibrary.simpleMessage(
      "Ti assegneremo il primo operatore libero",
    ),
    "staffAnyOperatorSubtitleCustom": m39,
    "staffEmpty": MessageLookupByLibrary.simpleMessage(
      "Nessun operatore disponibile al momento",
    ),
    "staffEmptyCustom": m40,
    "staffSubtitle": MessageLookupByLibrary.simpleMessage(
      "Seleziona con chi desideri essere servito",
    ),
    "staffSubtitleCustom": m41,
    "staffTitle": MessageLookupByLibrary.simpleMessage("Scegli l\'operatore"),
    "summaryCancellationPolicyAcceptLabel":
        MessageLookupByLibrary.simpleMessage(
          "Accetto la policy di modifica/cancellazione",
        ),
    "summaryCancellationPolicyAcceptRequiredError":
        MessageLookupByLibrary.simpleMessage(
          "Per confermare devi accettare la policy di modifica/cancellazione.",
        ),
    "summaryCancellationPolicyAlways": MessageLookupByLibrary.simpleMessage(
      "Sempre",
    ),
    "summaryCancellationPolicyDays": m42,
    "summaryCancellationPolicyHours": m43,
    "summaryCancellationPolicyNever": MessageLookupByLibrary.simpleMessage(
      "Mai (non consentita dopo la prenotazione)",
    ),
    "summaryCancellationPolicyTitle": MessageLookupByLibrary.simpleMessage(
      "Policy modifica/cancellazione",
    ),
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
    "summaryServicesCustom": m44,
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
    "wrongBusinessAuthAction": MessageLookupByLibrary.simpleMessage(
      "Esci e accedi qui",
    ),
    "wrongBusinessAuthMessage": m45,
    "wrongBusinessAuthTitle": MessageLookupByLibrary.simpleMessage(
      "Account associato ad un\'altra attività",
    ),
    "yes": MessageLookupByLibrary.simpleMessage("Sì"),
  };
}
