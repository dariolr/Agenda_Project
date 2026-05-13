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

  static String m11(count) => "${count} posti disponibili";

  static String m12(count) => "${count} posti";

  static String m13(id) => "Codice prenotazione: ${id}";

  static String m14(date) => "Prima disponibilità: ${date}";

  static String m15(hours) => "${hours} ora";

  static String m16(hours, minutes) => "${hours} ora ${minutes} min";

  static String m17(minutes) => "${minutes} min";

  static String m18(minutes) => "${minutes} min";

  static String m19(path) => "Pagina non trovata: ${path}";

  static String m20(label) => "${label} temporaneamente non disponibile";

  static String m21(label) => "Nessun ${label} disponibile";

  static String m22(dateTime) => "Modificabile fino al ${dateTime}";

  static String m23(days) =>
      "${Intl.plural(days, one: 'Modificabile fino a domani', other: 'Modificabile fino a ${days} giorni')}";

  static String m24(hours) =>
      "${Intl.plural(hours, one: 'Modificabile fino a 1 ora', other: 'Modificabile fino a ${hours} ore')}";

  static String m25(minutes) =>
      "${Intl.plural(minutes, one: 'Modificabile fino a 1 minuto', other: 'Modificabile fino a ${minutes} minuti')}";

  static String m26(dateTime) =>
      "Il termine per modificare o annullare è scaduto il ${dateTime}.";

  static String m27(staffLabel, serviceLabel) =>
      "Nessun ${staffLabel} può eseguire tutti i ${serviceLabel} selezionati. Prova a selezionare meno ${serviceLabel} o ${serviceLabel} diversi.";

  static String m28(price) => "€${price}";

  static String m29(id) => "Categoria ${id}";

  static String m30(duration) => "${duration} min";

  static String m31(label) => "Nessun ${label} disponibile al momento";

  static String m32(label) =>
      "Non ci sono ${label} prenotabili online per questa attività";

  static String m33(price) => "da ${price}";

  static String m34(count) =>
      "${Intl.plural(count, zero: 'Nessun servizio selezionato', one: '1 servizio selezionato', other: '${count} servizi selezionati')}";

  static String m35(count, label) => "${count} ${label} selezionati";

  static String m36(label) => "Nessun ${label} selezionato";

  static String m37(label) => "1 ${label} selezionato";

  static String m38(label) => "Puoi selezionare uno o più ${label}";

  static String m39(total) => "Totale: ${total}";

  static String m40(label) => "Qualsiasi ${label} disponibile";

  static String m41(label) => "Ti assegneremo il primo ${label} disponibile";

  static String m42(label) => "Nessun ${label} disponibile al momento";

  static String m43(label) => "Seleziona ${label} che preferisci";

  static String m44(days) =>
      "${Intl.plural(days, one: 'Fino a 1 giorno prima', other: 'Fino a ${days} giorni prima')}";

  static String m45(hours) => "Fino a ${hours} ore prima";

  static String m46(label) => "${label} selezionati";

  static String m47(eventName) =>
      "Hai già selezionato l\'evento \"${eventName}\". Una prenotazione può includere servizi oppure un evento di gruppo, non entrambi. Deseleziona l\'evento per scegliere i servizi.";

  static String m48(businessName) =>
      "Per prenotare su ${businessName}, devi accedere con un account registrato qui.";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "actionBack": MessageLookupByLibrary.simpleMessage("Indietro"),
    "actionBackToBooking": MessageLookupByLibrary.simpleMessage(
      "Torna alla prenotazione",
    ),
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
    "apiErrorClassTypeNameExists": MessageLookupByLibrary.simpleMessage(
      "Esiste già un tipo classe con questo nome.",
    ),
    "apiErrorDatabase": MessageLookupByLibrary.simpleMessage(
      "Servizio temporaneamente non disponibile. Riprova più tardi.",
    ),
    "apiErrorDemoBlocked": MessageLookupByLibrary.simpleMessage(
      "Questa azione è bloccata in modalità demo.",
    ),
    "apiErrorForbidden": MessageLookupByLibrary.simpleMessage(
      "Non hai i permessi per eseguire questa azione.",
    ),
    "apiErrorInvalidCredentials": MessageLookupByLibrary.simpleMessage(
      "Email o password non valide.",
    ),
    "apiErrorInvalidRefreshToken": MessageLookupByLibrary.simpleMessage(
      "La sessione non è più valida. Accedi di nuovo.",
    ),
    "apiErrorInvalidResetToken": MessageLookupByLibrary.simpleMessage(
      "Il link di reset password non è valido.",
    ),
    "apiErrorNotFound": MessageLookupByLibrary.simpleMessage(
      "La risorsa richiesta non è stata trovata.",
    ),
    "apiErrorResetTokenExpired": MessageLookupByLibrary.simpleMessage(
      "Il link di reset password è scaduto.",
    ),
    "apiErrorServiceCapacityFull": MessageLookupByLibrary.simpleMessage(
      "Lo slot selezionato ha raggiunto il numero massimo di prenotazioni contemporanee.",
    ),
    "apiErrorSlotConflict": MessageLookupByLibrary.simpleMessage(
      "Lo slot orario selezionato non è più disponibile.",
    ),
    "apiErrorTokenExpired": MessageLookupByLibrary.simpleMessage(
      "La sessione è scaduta. Accedi di nuovo.",
    ),
    "apiErrorUnauthorized": MessageLookupByLibrary.simpleMessage(
      "Autenticazione richiesta.",
    ),
    "apiErrorValidation": MessageLookupByLibrary.simpleMessage(
      "Controlla i dati inseriti.",
    ),
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
    "authNetworkError": MessageLookupByLibrary.simpleMessage(
      "Impossibile contattare il server. Verifica la connessione o riprova tra poco.",
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
    "bookingStepServicesAndEvents": MessageLookupByLibrary.simpleMessage(
      "Servizi / eventi",
    ),
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
    "classBookingWaitlistedBadge": MessageLookupByLibrary.simpleMessage(
      "Lista d\'attesa",
    ),
    "classEventAlreadyBooked": MessageLookupByLibrary.simpleMessage(
      "Già prenotato",
    ),
    "classEventAlreadyWaitlisted": MessageLookupByLibrary.simpleMessage(
      "Già in lista d\'attesa",
    ),
    "classEventFull": MessageLookupByLibrary.simpleMessage("Completo"),
    "classEventGroupLesson": MessageLookupByLibrary.simpleMessage(
      "Evento di gruppo",
    ),
    "classEventJoinWaitlistLabel": MessageLookupByLibrary.simpleMessage(
      "Iscriviti in lista d\'attesa",
    ),
    "classEventManageBooking": MessageLookupByLibrary.simpleMessage(
      "Gestisci prenotazione",
    ),
    "classEventSpotsAvailable": m11,
    "classEventSpotsLeft": m12,
    "classEventWaitlistDialogConfirm": MessageLookupByLibrary.simpleMessage(
      "Iscriviti",
    ),
    "classEventWaitlistDialogMessage": MessageLookupByLibrary.simpleMessage(
      "Questo evento è al completo. Vuoi iscriverti alla lista d\'attesa?",
    ),
    "classEventWaitlistDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Evento al completo",
    ),
    "classEventWaitlistLabel": MessageLookupByLibrary.simpleMessage(
      "Lista d\'attesa",
    ),
    "classEventWaitlistNotice": MessageLookupByLibrary.simpleMessage(
      "Sarai aggiunto alla lista d\'attesa",
    ),
    "confirmReschedule": MessageLookupByLibrary.simpleMessage(
      "Conferma modifica",
    ),
    "confirmationBookingId": m13,
    "confirmationGoHome": MessageLookupByLibrary.simpleMessage(
      "Torna alla home",
    ),
    "confirmationNewBooking": MessageLookupByLibrary.simpleMessage(
      "Nuova prenotazione",
    ),
    "confirmationPostRegistrationMyBookingsHint":
        MessageLookupByLibrary.simpleMessage(
          "Troverai l\'elenco delle tue prenotazioni in alto a destra, nella sezione Profilo.",
        ),
    "confirmationSubtitle": MessageLookupByLibrary.simpleMessage(
      "Ti abbiamo inviato un\'email di conferma",
    ),
    "confirmationTitle": MessageLookupByLibrary.simpleMessage(
      "Prenotazione confermata!",
    ),
    "confirmationWaitlistSubtitle": MessageLookupByLibrary.simpleMessage(
      "Verrai confermato non appena si libera un posto",
    ),
    "confirmationWaitlistTitle": MessageLookupByLibrary.simpleMessage(
      "Sei in lista d\'attesa!",
    ),
    "currentBooking": MessageLookupByLibrary.simpleMessage(
      "Prenotazione attuale",
    ),
    "dateTimeAfternoon": MessageLookupByLibrary.simpleMessage("Pomeriggio"),
    "dateTimeEvening": MessageLookupByLibrary.simpleMessage("Sera"),
    "dateTimeFirstAvailable": m14,
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
    "durationHour": m15,
    "durationHourMinute": m16,
    "durationMinute": m17,
    "durationMinutes": m18,
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
    "errorDirectLinkInvalidMessage": MessageLookupByLibrary.simpleMessage(
      "Il link che hai aperto non è valido, è scaduto o non è più disponibile.",
    ),
    "errorDirectLinkInvalidTitle": MessageLookupByLibrary.simpleMessage(
      "Link di prenotazione non valido",
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
    "errorNotFound": m19,
    "errorServiceUnavailable": MessageLookupByLibrary.simpleMessage(
      "Servizio temporaneamente non disponibile",
    ),
    "errorServiceUnavailableCustom": m20,
    "errorServiceUnavailableSubtitle": MessageLookupByLibrary.simpleMessage(
      "Stiamo lavorando per risolvere il problema. Riprova tra qualche minuto.",
    ),
    "errorTitle": MessageLookupByLibrary.simpleMessage("Errore"),
    "eventsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Seleziona l\'evento a cui vuoi partecipare",
    ),
    "eventsTitle": MessageLookupByLibrary.simpleMessage("Scegli un evento"),
    "loadingAvailability": MessageLookupByLibrary.simpleMessage(
      "Caricamento disponibilità...",
    ),
    "loadingGeneric": MessageLookupByLibrary.simpleMessage("Caricamento..."),
    "locationEmpty": MessageLookupByLibrary.simpleMessage(
      "Nessuna sede disponibile",
    ),
    "locationEmptyCustom": m21,
    "locationSubtitle": MessageLookupByLibrary.simpleMessage(
      "Seleziona dove vuoi effettuare la prenotazione",
    ),
    "locationTitle": MessageLookupByLibrary.simpleMessage("Scegli la sede"),
    "modifiable": MessageLookupByLibrary.simpleMessage("Modificabile"),
    "modifiableUntilDateTime": m22,
    "modifiableUntilDays": m23,
    "modifiableUntilHours": m24,
    "modifiableUntilMinutes": m25,
    "modificationWindowExpired": MessageLookupByLibrary.simpleMessage(
      "Il tempo per modificare o annullare questa prenotazione è scaduto.",
    ),
    "modificationWindowExpiredDateTime": m26,
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
    "noStaffForAllServicesCustom": m27,
    "noUpcomingBookings": MessageLookupByLibrary.simpleMessage(
      "Non hai prenotazioni in programma",
    ),
    "notModifiable": MessageLookupByLibrary.simpleMessage("Non modificabile"),
    "onlinePaymentRequiredBadge": MessageLookupByLibrary.simpleMessage(
      "Pagamento online richiesto",
    ),
    "pastBookings": MessageLookupByLibrary.simpleMessage("Passate"),
    "paymentResultFailedMessage": MessageLookupByLibrary.simpleMessage(
      "Il pagamento non è stato completato. Puoi riprovare se la prenotazione è ancora disponibile.",
    ),
    "paymentResultFailedTitle": MessageLookupByLibrary.simpleMessage(
      "Pagamento non completato",
    ),
    "paymentResultMyBookings": MessageLookupByLibrary.simpleMessage(
      "Le mie prenotazioni",
    ),
    "paymentResultPendingMessage": MessageLookupByLibrary.simpleMessage(
      "Stiamo verificando il pagamento. La prenotazione sarà confermata appena riceviamo l\'esito.",
    ),
    "paymentResultPendingTitle": MessageLookupByLibrary.simpleMessage(
      "Pagamento in verifica",
    ),
    "paymentResultRetry": MessageLookupByLibrary.simpleMessage(
      "Riprova pagamento",
    ),
    "paymentResultSuccessMessage": MessageLookupByLibrary.simpleMessage(
      "Il pagamento è stato completato e la prenotazione è confermata.",
    ),
    "paymentResultSuccessTitle": MessageLookupByLibrary.simpleMessage(
      "Prenotazione confermata",
    ),
    "paymentResultTitle": MessageLookupByLibrary.simpleMessage("Pagamento"),
    "priceFormat": m28,
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
    "servicesAndEventsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Seleziona un servizio o iscriviti a un evento di gruppo",
    ),
    "servicesAndEventsTitle": MessageLookupByLibrary.simpleMessage(
      "Scegli un servizio o un evento",
    ),
    "servicesCategoryFallbackName": m29,
    "servicesDuration": m30,
    "servicesEmpty": MessageLookupByLibrary.simpleMessage(
      "Nessun servizio disponibile al momento",
    ),
    "servicesEmptyCustom": m31,
    "servicesEmptySubtitle": MessageLookupByLibrary.simpleMessage(
      "Non ci sono servizi prenotabili online per questa attività",
    ),
    "servicesEmptySubtitleCustom": m32,
    "servicesFree": MessageLookupByLibrary.simpleMessage("Gratis"),
    "servicesPriceFrom": m33,
    "servicesSelected": m34,
    "servicesSelectedManyCustom": m35,
    "servicesSelectedNoneCustom": m36,
    "servicesSelectedOneCustom": m37,
    "servicesSubtitle": MessageLookupByLibrary.simpleMessage(
      "Puoi selezionare uno o più servizi",
    ),
    "servicesSubtitleCustom": m38,
    "servicesTitle": MessageLookupByLibrary.simpleMessage("Scegli i servizi"),
    "servicesTotal": m39,
    "sessionExpired": MessageLookupByLibrary.simpleMessage(
      "Sessione scaduta. Effettua nuovamente l\'accesso.",
    ),
    "slotNoLongerAvailable": MessageLookupByLibrary.simpleMessage(
      "Lo slot non è più disponibile. La prenotazione originale è rimasta invariata.",
    ),
    "staffAnyOperator": MessageLookupByLibrary.simpleMessage(
      "Qualsiasi operatore disponibile",
    ),
    "staffAnyOperatorCustom": m40,
    "staffAnyOperatorSubtitle": MessageLookupByLibrary.simpleMessage(
      "Ti assegneremo il primo operatore libero",
    ),
    "staffAnyOperatorSubtitleCustom": m41,
    "staffEmpty": MessageLookupByLibrary.simpleMessage(
      "Nessun operatore disponibile al momento",
    ),
    "staffEmptyCustom": m42,
    "staffSubtitle": MessageLookupByLibrary.simpleMessage(
      "Seleziona con chi desideri essere servito",
    ),
    "staffSubtitleCustom": m43,
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
    "summaryCancellationPolicyDays": m44,
    "summaryCancellationPolicyHours": m45,
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
    "summaryInPersonPrice": MessageLookupByLibrary.simpleMessage(
      "Da pagare in sede",
    ),
    "summaryOnlinePaymentNote": MessageLookupByLibrary.simpleMessage(
      "Verrai reindirizzato a Stripe per completare il pagamento dopo la conferma.",
    ),
    "summaryOnlinePaymentPrice": MessageLookupByLibrary.simpleMessage(
      "Da pagare online",
    ),
    "summaryOperator": MessageLookupByLibrary.simpleMessage("Operatore"),
    "summaryPrice": MessageLookupByLibrary.simpleMessage("Prezzo totale"),
    "summaryServices": MessageLookupByLibrary.simpleMessage(
      "Servizi selezionati",
    ),
    "summaryServicesCustom": m46,
    "summarySubtitle": MessageLookupByLibrary.simpleMessage(
      "Controlla i dettagli prima di confermare",
    ),
    "summaryTitle": MessageLookupByLibrary.simpleMessage(
      "Riepilogo prenotazione",
    ),
    "tabConflictEventsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Hai già selezionato uno o più servizi. Una prenotazione può includere servizi oppure un evento di gruppo, non entrambi. Deseleziona i servizi per scegliere un evento.",
    ),
    "tabConflictEventsTitle": MessageLookupByLibrary.simpleMessage(
      "Evento non selezionabile",
    ),
    "tabConflictServicesSubtitle": m47,
    "tabConflictServicesTitle": MessageLookupByLibrary.simpleMessage(
      "Servizi non selezionabili",
    ),
    "tabEvents": MessageLookupByLibrary.simpleMessage("Eventi"),
    "tabServices": MessageLookupByLibrary.simpleMessage("Servizi"),
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
    "wrongBusinessAuthMessage": m48,
    "wrongBusinessAuthTitle": MessageLookupByLibrary.simpleMessage(
      "Account associato ad un\'altra attività",
    ),
    "yes": MessageLookupByLibrary.simpleMessage("Sì"),
  };
}
