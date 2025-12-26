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

  static String m0(count) =>
      "Il cliente verrà associato anche agli altri ${count} appuntamenti di questa prenotazione.";

  static String m1(name) => "Disponibilità – ${name}";

  static String m2(clientName) => "Appuntamenti di ${clientName}";

  static String m3(hours) => "${hours} ora";

  static String m4(hours, minutes) => "${hours} ora ${minutes} min";

  static String m5(minutes) => "${minutes} min";

  static String m6(id) => "Eccezione non trovata: ${id}";

  static String m7(factor) => "Nessun builder disponibile per ${factor}";

  static String m8(path) => "Pagina non trovata: ${path}";

  static String m9(count) =>
      "${count} ${Intl.plural(count, one: 'giorno', other: 'giorni')}";

  static String m10(dates) => "Alcuni giorni non sono stati salvati: ${dates}.";

  static String m11(details) =>
      "Alcuni giorni non sono stati salvati: ${details}.";

  static String m12(hours) => "${hours}h";

  static String m13(hours, minutes) => "${hours}h ${minutes}m";

  static String m14(date) => "Ultima visita: ${date}";

  static String m15(newTime, staffName) =>
      "L\'appuntamento verrà spostato alle ${newTime} per ${staffName}.";

  static String m16(count) => "${count} membri abilitati";

  static String m17(count) =>
      "${Intl.plural(count, one: '1 servizio selezionato', other: '${count} servizi selezionati')}";

  static String m18(dayName) =>
      "Elimina la fascia oraria settimanale di ogni ${dayName}";

  static String m19(date) => "Elimina solo la fascia oraria di ${date}";

  static String m20(dayName) =>
      "Modifica la fascia oraria settimanale di ogni ${dayName}";

  static String m21(date) => "Modifica solo la fascia oraria di ${date}";

  static String m22(count) => "${count} servizi abilitati";

  static String m23(selected, total) => "${selected} su ${total}";

  static String m24(hours) => "${hours} ore totale";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "actionCancel": MessageLookupByLibrary.simpleMessage("Annulla"),
    "actionClose": MessageLookupByLibrary.simpleMessage("Conferma"),
    "actionConfirm": MessageLookupByLibrary.simpleMessage("Conferma"),
    "actionDelete": MessageLookupByLibrary.simpleMessage("Elimina"),
    "actionDeleteBooking": MessageLookupByLibrary.simpleMessage(
      "Elimina prenotazione",
    ),
    "actionDiscard": MessageLookupByLibrary.simpleMessage("Annulla"),
    "actionEdit": MessageLookupByLibrary.simpleMessage("Modifica"),
    "actionKeepEditing": MessageLookupByLibrary.simpleMessage(
      "Continua a modificare",
    ),
    "actionSave": MessageLookupByLibrary.simpleMessage("Salva"),
    "addClientToAppointment": MessageLookupByLibrary.simpleMessage(
      "Aggiungi un cliente all\'appuntamento",
    ),
    "addService": MessageLookupByLibrary.simpleMessage("Aggiungi un servizio"),
    "addServiceTooltip": MessageLookupByLibrary.simpleMessage(
      "Aggiungi servizio",
    ),
    "additionalTimeOptionBlocked": MessageLookupByLibrary.simpleMessage(
      "Tempo bloccato",
    ),
    "additionalTimeOptionProcessing": MessageLookupByLibrary.simpleMessage(
      "Tempo di lavorazione",
    ),
    "additionalTimeSwitch": MessageLookupByLibrary.simpleMessage(
      "Tempo aggiuntivo",
    ),
    "agendaAdd": MessageLookupByLibrary.simpleMessage("Aggiungi"),
    "agendaAddAppointment": MessageLookupByLibrary.simpleMessage(
      "Nuovo appuntamento",
    ),
    "agendaAddBlock": MessageLookupByLibrary.simpleMessage("Nuovo blocco"),
    "agendaAddTitle": MessageLookupByLibrary.simpleMessage("Aggiungi un..."),
    "agendaNextDay": MessageLookupByLibrary.simpleMessage("Giorno successivo"),
    "agendaNextMonth": MessageLookupByLibrary.simpleMessage("Mese successivo"),
    "agendaNextWeek": MessageLookupByLibrary.simpleMessage(
      "Settimana successivo",
    ),
    "agendaNoLocations": MessageLookupByLibrary.simpleMessage(
      "Nessuna sede disponibile",
    ),
    "agendaNoOnDutyTeamTitle": MessageLookupByLibrary.simpleMessage(
      "Nessun membro del team di turno oggi",
    ),
    "agendaNoSelectedTeamTitle": MessageLookupByLibrary.simpleMessage(
      "Nessun membro del team selezionato",
    ),
    "agendaPrevDay": MessageLookupByLibrary.simpleMessage("Giorno precedente"),
    "agendaPrevMonth": MessageLookupByLibrary.simpleMessage("Mese precedente"),
    "agendaPrevWeek": MessageLookupByLibrary.simpleMessage(
      "Settimana precedente",
    ),
    "agendaSelectLocation": MessageLookupByLibrary.simpleMessage(
      "Seleziona sede",
    ),
    "agendaShowAllTeamButton": MessageLookupByLibrary.simpleMessage(
      "Visualizza tutto il team",
    ),
    "agendaToday": MessageLookupByLibrary.simpleMessage("Oggi"),
    "allLocations": MessageLookupByLibrary.simpleMessage("Tutte le sedi"),
    "appTitle": MessageLookupByLibrary.simpleMessage("Agenda Platform"),
    "applyClientToAllAppointmentsMessage": m0,
    "applyClientToAllAppointmentsTitle": MessageLookupByLibrary.simpleMessage(
      "Applicare il cliente a tutta la prenotazione?",
    ),
    "appointmentDialogTitleEdit": MessageLookupByLibrary.simpleMessage(
      "Modifica appuntamento",
    ),
    "appointmentDialogTitleNew": MessageLookupByLibrary.simpleMessage(
      "Nuovo appuntamento",
    ),
    "appointmentNoteLabel": MessageLookupByLibrary.simpleMessage(
      "Nota appuntamento",
    ),
    "appointmentNotesTitle": MessageLookupByLibrary.simpleMessage("Note"),
    "atLeastOneServiceRequired": MessageLookupByLibrary.simpleMessage(
      "Aggiungi almeno un servizio",
    ),
    "availabilitySave": MessageLookupByLibrary.simpleMessage("Salva modifiche"),
    "availabilityTitle": MessageLookupByLibrary.simpleMessage(
      "Disponibilità settimanale",
    ),
    "availabilityTitleFor": m1,
    "blockAllDay": MessageLookupByLibrary.simpleMessage("Giornata intera"),
    "blockDialogTitleEdit": MessageLookupByLibrary.simpleMessage(
      "Modifica blocco",
    ),
    "blockDialogTitleNew": MessageLookupByLibrary.simpleMessage("Nuovo blocco"),
    "blockEndTime": MessageLookupByLibrary.simpleMessage("Orario fine"),
    "blockReason": MessageLookupByLibrary.simpleMessage("Motivo (opzionale)"),
    "blockReasonHint": MessageLookupByLibrary.simpleMessage(
      "Es. Riunione, Pausa, ecc.",
    ),
    "blockSelectStaff": MessageLookupByLibrary.simpleMessage("Seleziona team"),
    "blockSelectStaffError": MessageLookupByLibrary.simpleMessage(
      "Seleziona almeno un team",
    ),
    "blockStartTime": MessageLookupByLibrary.simpleMessage("Orario inizio"),
    "blockTimeError": MessageLookupByLibrary.simpleMessage(
      "L\'ora di fine deve essere successiva all\'ora di inizio",
    ),
    "bookableOnlineSwitch": MessageLookupByLibrary.simpleMessage(
      "Prenotabile online",
    ),
    "bookingDetails": MessageLookupByLibrary.simpleMessage(
      "Dettagli prenotazione",
    ),
    "bookingItems": MessageLookupByLibrary.simpleMessage("Servizi"),
    "bookingNotes": MessageLookupByLibrary.simpleMessage("Note prenotazione"),
    "bookingStaffNotEligibleWarning": MessageLookupByLibrary.simpleMessage(
      "Attenzione: il membro del team selezionato non è abilitato per questo servizio.",
    ),
    "bookingTotal": MessageLookupByLibrary.simpleMessage("Totale"),
    "bookingUnavailableTimeWarningAppointment":
        MessageLookupByLibrary.simpleMessage(
          "Attenzione: l’orario selezionato per l’appuntamento include fasce non disponibili per il team scelto.",
        ),
    "bookingUnavailableTimeWarningService": MessageLookupByLibrary.simpleMessage(
      "Attenzione: l’orario di questo servizio include fasce non disponibili per il team scelto.",
    ),
    "cannotDeleteCategoryContent": MessageLookupByLibrary.simpleMessage(
      "La categoria contiene uno o più servizi.",
    ),
    "cannotDeleteTitle": MessageLookupByLibrary.simpleMessage(
      "Impossibile eliminare",
    ),
    "cannotUndoWarning": MessageLookupByLibrary.simpleMessage(
      "Questa azione non può essere annullata.",
    ),
    "categoryDuplicateError": MessageLookupByLibrary.simpleMessage(
      "Esiste già una categoria con questo nome",
    ),
    "clientAppointmentsEmpty": MessageLookupByLibrary.simpleMessage(
      "Nessun appuntamento",
    ),
    "clientAppointmentsPast": MessageLookupByLibrary.simpleMessage("Passati"),
    "clientAppointmentsTitle": m2,
    "clientAppointmentsUpcoming": MessageLookupByLibrary.simpleMessage(
      "Prossimi",
    ),
    "clientLockedHint": MessageLookupByLibrary.simpleMessage(
      "Il cliente non può essere modificato per questo appuntamento",
    ),
    "clientNoteLabel": MessageLookupByLibrary.simpleMessage("Nota cliente"),
    "clientOptionalHint": MessageLookupByLibrary.simpleMessage(
      "Lascia il campo vuoto se non vuoi associare un cliente all\'appuntamento",
    ),
    "clientsEdit": MessageLookupByLibrary.simpleMessage("Modifica cliente"),
    "clientsEmpty": MessageLookupByLibrary.simpleMessage("Nessun cliente"),
    "clientsNew": MessageLookupByLibrary.simpleMessage("Nuovo cliente"),
    "clientsTitle": MessageLookupByLibrary.simpleMessage("Elenco Clienti"),
    "createCategoryButtonLabel": MessageLookupByLibrary.simpleMessage(
      "Nuova categoria",
    ),
    "createNewClient": MessageLookupByLibrary.simpleMessage(
      "Crea nuovo cliente",
    ),
    "currentWeek": MessageLookupByLibrary.simpleMessage("Settimana corrente"),
    "dayFridayFull": MessageLookupByLibrary.simpleMessage("venerdì"),
    "dayMondayFull": MessageLookupByLibrary.simpleMessage("lunedì"),
    "daySaturdayFull": MessageLookupByLibrary.simpleMessage("sabato"),
    "daySundayFull": MessageLookupByLibrary.simpleMessage("domenica"),
    "dayThursdayFull": MessageLookupByLibrary.simpleMessage("giovedì"),
    "dayTuesdayFull": MessageLookupByLibrary.simpleMessage("martedì"),
    "dayWednesdayFull": MessageLookupByLibrary.simpleMessage("mercoledì"),
    "deleteAppointmentConfirmMessage": MessageLookupByLibrary.simpleMessage(
      "L\'appuntamento verrà rimosso. L\'operazione non può essere annullata.",
    ),
    "deleteAppointmentConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Eliminare l\'appuntamento?",
    ),
    "deleteBookingConfirmMessage": MessageLookupByLibrary.simpleMessage(
      "Verranno rimossi tutti i servizi collegati. L\'operazione non può essere annullata.",
    ),
    "deleteBookingConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Eliminare l’intera prenotazione?",
    ),
    "deleteClientConfirmMessage": MessageLookupByLibrary.simpleMessage(
      "Il cliente verrà eliminato definitivamente. Questa azione non può essere annullata.",
    ),
    "deleteClientConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Eliminare il cliente?",
    ),
    "deleteConfirmationTitle": MessageLookupByLibrary.simpleMessage(
      "Confermi l’eliminazione?",
    ),
    "deleteServiceQuestion": MessageLookupByLibrary.simpleMessage(
      "Eliminare il servizio?",
    ),
    "discardChangesMessage": MessageLookupByLibrary.simpleMessage(
      "Hai delle modifiche non salvate. Vuoi scartarle?",
    ),
    "discardChangesTitle": MessageLookupByLibrary.simpleMessage(
      "Modifiche non salvate",
    ),
    "duplicateAction": MessageLookupByLibrary.simpleMessage("Duplica"),
    "durationHour": m3,
    "durationHourMinute": m4,
    "durationMinute": m5,
    "editCategoryTitle": MessageLookupByLibrary.simpleMessage(
      "Modifica categoria",
    ),
    "editServiceTitle": MessageLookupByLibrary.simpleMessage(
      "Modifica servizio",
    ),
    "emptyCategoriesNotReorderableNote": MessageLookupByLibrary.simpleMessage(
      "Le categorie senza servizi non sono riordinabili e restano in coda.",
    ),
    "errorExceptionNotFound": m6,
    "errorFormFactorBuilderMissing": m7,
    "errorFormFactorBuilderRequired": MessageLookupByLibrary.simpleMessage(
      "Specificare almeno un builder per form factor",
    ),
    "errorNotFound": m8,
    "errorServiceNotFound": MessageLookupByLibrary.simpleMessage(
      "Servizio non trovato",
    ),
    "errorTitle": MessageLookupByLibrary.simpleMessage("Errore"),
    "exceptionAllDay": MessageLookupByLibrary.simpleMessage("Giornata intera"),
    "exceptionAvailableNoEffect": MessageLookupByLibrary.simpleMessage(
      "La disponibilità extra deve aggiungere ore rispetto alla disponibilità base.",
    ),
    "exceptionDateFrom": MessageLookupByLibrary.simpleMessage("Data inizio"),
    "exceptionDateTo": MessageLookupByLibrary.simpleMessage("Data fine"),
    "exceptionDeleteMessage": MessageLookupByLibrary.simpleMessage(
      "L\'eccezione verrà eliminata definitivamente.",
    ),
    "exceptionDeleteShift": MessageLookupByLibrary.simpleMessage(
      "Elimina eccezione",
    ),
    "exceptionDeleteShiftDesc": MessageLookupByLibrary.simpleMessage(
      "Ripristina la disponibilità base",
    ),
    "exceptionDeleteTitle": MessageLookupByLibrary.simpleMessage(
      "Eliminare l\'eccezione?",
    ),
    "exceptionDialogTitleEdit": MessageLookupByLibrary.simpleMessage(
      "Modifica eccezione",
    ),
    "exceptionDialogTitleNew": MessageLookupByLibrary.simpleMessage(
      "Nuova eccezione",
    ),
    "exceptionDuration": MessageLookupByLibrary.simpleMessage(
      "Durata (giorni)",
    ),
    "exceptionDurationDays": m9,
    "exceptionEditShift": MessageLookupByLibrary.simpleMessage(
      "Modifica eccezione",
    ),
    "exceptionEditShiftDesc": MessageLookupByLibrary.simpleMessage(
      "Modifica gli orari di questa eccezione",
    ),
    "exceptionEndTime": MessageLookupByLibrary.simpleMessage("Orario fine"),
    "exceptionPartialSaveInfo": m10,
    "exceptionPartialSaveInfoDetailed": m11,
    "exceptionPartialSaveMessage": MessageLookupByLibrary.simpleMessage(
      "I giorni sotto non erano congruenti e non sono stati salvati:",
    ),
    "exceptionPartialSaveTitle": MessageLookupByLibrary.simpleMessage(
      "Eccezioni non salvate",
    ),
    "exceptionPeriodDuration": MessageLookupByLibrary.simpleMessage("Durata"),
    "exceptionPeriodMode": MessageLookupByLibrary.simpleMessage("Periodo"),
    "exceptionPeriodRange": MessageLookupByLibrary.simpleMessage("Da - A"),
    "exceptionPeriodSingle": MessageLookupByLibrary.simpleMessage(
      "Giorno singolo",
    ),
    "exceptionReason": MessageLookupByLibrary.simpleMessage(
      "Motivo (opzionale)",
    ),
    "exceptionReasonExtraShift": MessageLookupByLibrary.simpleMessage(
      "Turno extra",
    ),
    "exceptionReasonHint": MessageLookupByLibrary.simpleMessage(
      "Es. Ferie, Visita medica, Turno extra...",
    ),
    "exceptionReasonMedicalVisit": MessageLookupByLibrary.simpleMessage(
      "Visita medica",
    ),
    "exceptionReasonVacation": MessageLookupByLibrary.simpleMessage("Ferie"),
    "exceptionSelectTime": MessageLookupByLibrary.simpleMessage(
      "Seleziona orario",
    ),
    "exceptionStartTime": MessageLookupByLibrary.simpleMessage("Orario inizio"),
    "exceptionTimeError": MessageLookupByLibrary.simpleMessage(
      "L\'ora di fine deve essere successiva all\'ora di inizio",
    ),
    "exceptionType": MessageLookupByLibrary.simpleMessage("Tipo eccezione"),
    "exceptionTypeAvailable": MessageLookupByLibrary.simpleMessage(
      "Disponibile",
    ),
    "exceptionTypeUnavailable": MessageLookupByLibrary.simpleMessage(
      "Non disponibile",
    ),
    "exceptionUnavailableNoBase": MessageLookupByLibrary.simpleMessage(
      "Non puoi aggiungere una non disponibilità in un giorno senza disponibilità base.",
    ),
    "exceptionUnavailableNoOverlap": MessageLookupByLibrary.simpleMessage(
      "La non disponibilità deve sovrapporsi alla disponibilità base.",
    ),
    "exceptionsAdd": MessageLookupByLibrary.simpleMessage("Aggiungi eccezione"),
    "exceptionsEmpty": MessageLookupByLibrary.simpleMessage(
      "Nessuna eccezione configurata",
    ),
    "exceptionsTitle": MessageLookupByLibrary.simpleMessage("Eccezioni"),
    "fieldBlockedTimeLabel": MessageLookupByLibrary.simpleMessage(
      "Tempo bloccato",
    ),
    "fieldCategoryRequiredLabel": MessageLookupByLibrary.simpleMessage(
      "Categoria *",
    ),
    "fieldDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "Descrizione",
    ),
    "fieldDurationRequiredError": MessageLookupByLibrary.simpleMessage(
      "Seleziona una durata",
    ),
    "fieldDurationRequiredLabel": MessageLookupByLibrary.simpleMessage(
      "Durata *",
    ),
    "fieldNameRequiredError": MessageLookupByLibrary.simpleMessage(
      "Il nome è obbligatorio",
    ),
    "fieldNameRequiredLabel": MessageLookupByLibrary.simpleMessage("Nome *"),
    "fieldPriceLabel": MessageLookupByLibrary.simpleMessage("Prezzo"),
    "fieldProcessingTimeLabel": MessageLookupByLibrary.simpleMessage(
      "Tempo di lavorazione",
    ),
    "filterAll": MessageLookupByLibrary.simpleMessage("Tutti"),
    "filterInactive": MessageLookupByLibrary.simpleMessage("Inattivi"),
    "filterNew": MessageLookupByLibrary.simpleMessage("Nuovi"),
    "filterVIP": MessageLookupByLibrary.simpleMessage("VIP"),
    "formClient": MessageLookupByLibrary.simpleMessage("Cliente"),
    "formDate": MessageLookupByLibrary.simpleMessage("Data"),
    "formEmail": MessageLookupByLibrary.simpleMessage("Email"),
    "formFirstName": MessageLookupByLibrary.simpleMessage("Nome"),
    "formLastName": MessageLookupByLibrary.simpleMessage("Cognome"),
    "formNotes": MessageLookupByLibrary.simpleMessage(
      "Note (non visibili al cliente)",
    ),
    "formPhone": MessageLookupByLibrary.simpleMessage("Telefono"),
    "formService": MessageLookupByLibrary.simpleMessage("Servizio"),
    "formServices": MessageLookupByLibrary.simpleMessage("Servizi"),
    "formStaff": MessageLookupByLibrary.simpleMessage("Team"),
    "freeLabel": MessageLookupByLibrary.simpleMessage("Gratis"),
    "freeServiceSwitch": MessageLookupByLibrary.simpleMessage(
      "Servizio gratuito",
    ),
    "hoursHoursOnly": m12,
    "hoursMinutesCompact": m13,
    "labelSelect": MessageLookupByLibrary.simpleMessage("Seleziona"),
    "labelStaff": MessageLookupByLibrary.simpleMessage("Team:"),
    "lastVisitLabel": m14,
    "moveAppointmentConfirmMessage": m15,
    "moveAppointmentConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Confermi lo spostamento?",
    ),
    "navAgenda": MessageLookupByLibrary.simpleMessage("Agenda"),
    "navClients": MessageLookupByLibrary.simpleMessage("Clienti"),
    "navServices": MessageLookupByLibrary.simpleMessage("Servizi"),
    "navStaff": MessageLookupByLibrary.simpleMessage("Team"),
    "newCategoryTitle": MessageLookupByLibrary.simpleMessage("Nuova categoria"),
    "newServiceTitle": MessageLookupByLibrary.simpleMessage("Nuovo servizio"),
    "noClientForAppointment": MessageLookupByLibrary.simpleMessage(
      "Nessun cliente per l\'appuntamento",
    ),
    "noServicesAdded": MessageLookupByLibrary.simpleMessage(
      "Nessun servizio aggiunto",
    ),
    "noServicesInCategory": MessageLookupByLibrary.simpleMessage(
      "Nessun servizio in questa categoria",
    ),
    "noStaffAvailable": MessageLookupByLibrary.simpleMessage(
      "Nessun team disponibile",
    ),
    "notBookableOnline": MessageLookupByLibrary.simpleMessage(
      "Non prenotabile online",
    ),
    "notesPlaceholder": MessageLookupByLibrary.simpleMessage(
      "Note sull\'appuntamento...",
    ),
    "priceNotAvailable": MessageLookupByLibrary.simpleMessage("N/D"),
    "priceStartingFromPrefix": MessageLookupByLibrary.simpleMessage(
      "a partire da",
    ),
    "priceStartingFromSwitch": MessageLookupByLibrary.simpleMessage(
      "Prezzo \"a partire da\"",
    ),
    "removeClient": MessageLookupByLibrary.simpleMessage("Rimuovi cliente"),
    "reorderCategoriesLabel": MessageLookupByLibrary.simpleMessage("Categorie"),
    "reorderHelpDescription": MessageLookupByLibrary.simpleMessage(
      "Riordina categorie e servizi trascinandoli: l’ordine sarà lo stesso anche nella prenotazione online. Seleziona se ordinare categorie o servizi.",
    ),
    "reorderServicesLabel": MessageLookupByLibrary.simpleMessage("Servizi"),
    "reorderTitle": MessageLookupByLibrary.simpleMessage(
      "Modifica ordinamento",
    ),
    "searchClientPlaceholder": MessageLookupByLibrary.simpleMessage(
      "Cerca cliente...",
    ),
    "selectClientTitle": MessageLookupByLibrary.simpleMessage(
      "Seleziona cliente",
    ),
    "selectService": MessageLookupByLibrary.simpleMessage(
      "Seleziona un servizio",
    ),
    "selectStaffTitle": MessageLookupByLibrary.simpleMessage("Seleziona team"),
    "serviceColorLabel": MessageLookupByLibrary.simpleMessage(
      "Colore servizio",
    ),
    "serviceDuplicateCopyWord": MessageLookupByLibrary.simpleMessage("Copia"),
    "serviceDuplicateError": MessageLookupByLibrary.simpleMessage(
      "Esiste già un servizio con questo nome",
    ),
    "serviceEligibleStaffCount": m16,
    "serviceEligibleStaffNone": MessageLookupByLibrary.simpleMessage(
      "Nessun membro abilitato",
    ),
    "serviceSeedCategoryBodyDescription": MessageLookupByLibrary.simpleMessage(
      "Servizi dedicati al benessere del corpo",
    ),
    "serviceSeedCategoryBodyName": MessageLookupByLibrary.simpleMessage(
      "Trattamenti Corpo",
    ),
    "serviceSeedCategoryFaceDescription": MessageLookupByLibrary.simpleMessage(
      "Cura estetica e rigenerante per il viso",
    ),
    "serviceSeedCategoryFaceName": MessageLookupByLibrary.simpleMessage(
      "Trattamenti Viso",
    ),
    "serviceSeedCategorySportsDescription":
        MessageLookupByLibrary.simpleMessage(
          "Percorsi pensati per atleti e persone attive",
        ),
    "serviceSeedCategorySportsName": MessageLookupByLibrary.simpleMessage(
      "Trattamenti Sportivi",
    ),
    "serviceSeedServiceFaceDescription": MessageLookupByLibrary.simpleMessage(
      "Pulizia e trattamento illuminante",
    ),
    "serviceSeedServiceFaceName": MessageLookupByLibrary.simpleMessage(
      "Trattamento Viso",
    ),
    "serviceSeedServiceRelaxDescription": MessageLookupByLibrary.simpleMessage(
      "Trattamento rilassante da 30 minuti",
    ),
    "serviceSeedServiceRelaxName": MessageLookupByLibrary.simpleMessage(
      "Massaggio Relax",
    ),
    "serviceSeedServiceSportDescription": MessageLookupByLibrary.simpleMessage(
      "Trattamento decontratturante intensivo",
    ),
    "serviceSeedServiceSportName": MessageLookupByLibrary.simpleMessage(
      "Massaggio Sportivo",
    ),
    "servicesNewServiceMenu": MessageLookupByLibrary.simpleMessage(
      "Nuovo servizio",
    ),
    "servicesSelectedCount": m17,
    "setPriceToEnable": MessageLookupByLibrary.simpleMessage(
      "Imposta un prezzo per abilitarlo",
    ),
    "shiftDeleteAll": MessageLookupByLibrary.simpleMessage(
      "Elimina tutti questi turni",
    ),
    "shiftDeleteAllDesc": m18,
    "shiftDeleteThisOnly": MessageLookupByLibrary.simpleMessage(
      "Elimina solo questo turno",
    ),
    "shiftDeleteThisOnlyDesc": m19,
    "shiftEditAll": MessageLookupByLibrary.simpleMessage(
      "Modifica tutti questi turni",
    ),
    "shiftEditAllDesc": m20,
    "shiftEditThisOnly": MessageLookupByLibrary.simpleMessage(
      "Modifica solo questo turno",
    ),
    "shiftEditThisOnlyDesc": m21,
    "shiftEditTitle": MessageLookupByLibrary.simpleMessage("Modifica turno"),
    "shiftEndTime": MessageLookupByLibrary.simpleMessage("Ora fine"),
    "shiftStartTime": MessageLookupByLibrary.simpleMessage("Ora inizio"),
    "sortByCreatedAtAsc": MessageLookupByLibrary.simpleMessage(
      "Data creazione (vecchi)",
    ),
    "sortByCreatedAtDesc": MessageLookupByLibrary.simpleMessage(
      "Data creazione (nuovi)",
    ),
    "sortByLastNameAsc": MessageLookupByLibrary.simpleMessage("Cognome (A-Z)"),
    "sortByLastNameDesc": MessageLookupByLibrary.simpleMessage("Cognome (Z-A)"),
    "sortByLastVisitAsc": MessageLookupByLibrary.simpleMessage(
      "Ultima visita (meno recenti)",
    ),
    "sortByLastVisitDesc": MessageLookupByLibrary.simpleMessage(
      "Ultima visita (recenti)",
    ),
    "sortByNameAsc": MessageLookupByLibrary.simpleMessage("Nome (A-Z)"),
    "sortByNameDesc": MessageLookupByLibrary.simpleMessage("Nome (Z-A)"),
    "sortByTitle": MessageLookupByLibrary.simpleMessage("Ordina per"),
    "staffEditHours": MessageLookupByLibrary.simpleMessage("Modifica orari"),
    "staffFilterAllTeam": MessageLookupByLibrary.simpleMessage("Tutto il team"),
    "staffFilterOnDuty": MessageLookupByLibrary.simpleMessage("Team di turno"),
    "staffFilterSelectMembers": MessageLookupByLibrary.simpleMessage(
      "Seleziona membri del team",
    ),
    "staffFilterTitle": MessageLookupByLibrary.simpleMessage("Filtra team"),
    "staffFilterTooltip": MessageLookupByLibrary.simpleMessage("Filtra team"),
    "staffHubAvailabilitySubtitle": MessageLookupByLibrary.simpleMessage(
      "Configura gli orari di lavoro settimanali",
    ),
    "staffHubAvailabilityTitle": MessageLookupByLibrary.simpleMessage(
      "Disponibilità",
    ),
    "staffHubNotYetAvailable": MessageLookupByLibrary.simpleMessage(
      "Non ancora disponibile",
    ),
    "staffHubStatsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Performance e carichi di lavoro",
    ),
    "staffHubStatsTitle": MessageLookupByLibrary.simpleMessage("Statistiche"),
    "staffHubTeamSubtitle": MessageLookupByLibrary.simpleMessage(
      "Gestione membri e ruoli",
    ),
    "staffHubTeamTitle": MessageLookupByLibrary.simpleMessage("Team"),
    "staffNotBookableOnlineMessage": MessageLookupByLibrary.simpleMessage(
      "Questo membro del team non è abilitato alle prenotazioni online. Puoi modificare l’impostazione dal form di modifica dello staff.",
    ),
    "staffNotBookableOnlineTitle": MessageLookupByLibrary.simpleMessage(
      "Non prenotabile online",
    ),
    "staffNotBookableOnlineTooltip": MessageLookupByLibrary.simpleMessage(
      "Non prenotabile online",
    ),
    "staffScreenPlaceholder": MessageLookupByLibrary.simpleMessage(
      "Schermata Team",
    ),
    "teamAddStaff": MessageLookupByLibrary.simpleMessage("Aggiungi membro"),
    "teamChooseLocationSingleButton": MessageLookupByLibrary.simpleMessage(
      "Seleziona la sede",
    ),
    "teamChooseLocationsButton": MessageLookupByLibrary.simpleMessage(
      "Seleziona sedi",
    ),
    "teamDeleteLocationBlockedMessage": MessageLookupByLibrary.simpleMessage(
      "Rimuovi prima tutti i membri del team associati.",
    ),
    "teamDeleteLocationBlockedTitle": MessageLookupByLibrary.simpleMessage(
      "Impossibile eliminare la sede",
    ),
    "teamDeleteLocationMessage": MessageLookupByLibrary.simpleMessage(
      "La sede verrà rimossa dal team. L\'operazione non può essere annullata.",
    ),
    "teamDeleteLocationTitle": MessageLookupByLibrary.simpleMessage(
      "Eliminare la sede?",
    ),
    "teamDeleteStaffMessage": MessageLookupByLibrary.simpleMessage(
      "Il membro verrà rimosso dal team. L\'operazione non può essere annullata.",
    ),
    "teamDeleteStaffTitle": MessageLookupByLibrary.simpleMessage(
      "Eliminare il membro del team?",
    ),
    "teamEditLocationTitle": MessageLookupByLibrary.simpleMessage(
      "Modifica sede",
    ),
    "teamEditStaffTitle": MessageLookupByLibrary.simpleMessage(
      "Modifica membro del team",
    ),
    "teamEligibleServicesCount": m22,
    "teamEligibleServicesLabel": MessageLookupByLibrary.simpleMessage(
      "Servizi abilitati",
    ),
    "teamEligibleServicesNone": MessageLookupByLibrary.simpleMessage(
      "Nessun servizio abilitato",
    ),
    "teamEligibleStaffLabel": MessageLookupByLibrary.simpleMessage(
      "Team abilitato",
    ),
    "teamLocationAddressLabel": MessageLookupByLibrary.simpleMessage(
      "Indirizzo",
    ),
    "teamLocationLabel": MessageLookupByLibrary.simpleMessage("Sede"),
    "teamLocationNameLabel": MessageLookupByLibrary.simpleMessage("Nome sede"),
    "teamLocationsLabel": MessageLookupByLibrary.simpleMessage("Sedi"),
    "teamNewLocationTitle": MessageLookupByLibrary.simpleMessage("Nuova sede"),
    "teamNewStaffTitle": MessageLookupByLibrary.simpleMessage(
      "Nuovo membro del team",
    ),
    "teamNoStaffInLocation": MessageLookupByLibrary.simpleMessage(
      "Nessun membro in questa sede",
    ),
    "teamReorderHelpDescription": MessageLookupByLibrary.simpleMessage(
      "Riordina sedi e membri del team trascinandoli. Seleziona se ordinare sedi o team. L’ordine sarà lo stesso anche nella sezione agenda.",
    ),
    "teamSelectAllLocations": MessageLookupByLibrary.simpleMessage(
      "Seleziona tutto",
    ),
    "teamSelectAllServices": MessageLookupByLibrary.simpleMessage(
      "Seleziona tutto",
    ),
    "teamSelectedServicesButton": MessageLookupByLibrary.simpleMessage(
      "Servizi selezionati",
    ),
    "teamSelectedServicesCount": m23,
    "teamServicesLabel": MessageLookupByLibrary.simpleMessage("Servizi"),
    "teamStaffBookableOnlineLabel": MessageLookupByLibrary.simpleMessage(
      "Abilitato alle prenotazioni online",
    ),
    "teamStaffColorLabel": MessageLookupByLibrary.simpleMessage("Colore"),
    "teamStaffLabel": MessageLookupByLibrary.simpleMessage("Team"),
    "teamStaffLocationsLabel": MessageLookupByLibrary.simpleMessage(
      "Sedi associate",
    ),
    "teamStaffMultiLocationWarning": MessageLookupByLibrary.simpleMessage(
      "Se il membro lavora su più sedi, ricorda di allineare disponibilità e orari con le sedi selezionate.",
    ),
    "teamStaffNameLabel": MessageLookupByLibrary.simpleMessage("Nome"),
    "teamStaffSurnameLabel": MessageLookupByLibrary.simpleMessage("Cognome"),
    "validationInvalidEmail": MessageLookupByLibrary.simpleMessage(
      "Email non valida",
    ),
    "validationInvalidPhone": MessageLookupByLibrary.simpleMessage(
      "Telefono non valido",
    ),
    "validationNameOrLastNameRequired": MessageLookupByLibrary.simpleMessage(
      "Inserire almeno nome o cognome",
    ),
    "validationRequired": MessageLookupByLibrary.simpleMessage("Richiesto"),
    "weeklyScheduleAddShift": MessageLookupByLibrary.simpleMessage(
      "Aggiungi turno",
    ),
    "weeklyScheduleFor": MessageLookupByLibrary.simpleMessage("-"),
    "weeklyScheduleNotWorking": MessageLookupByLibrary.simpleMessage(
      "Non lavora",
    ),
    "weeklyScheduleRemoveShift": MessageLookupByLibrary.simpleMessage(
      "Rimuovi turno",
    ),
    "weeklyScheduleTitle": MessageLookupByLibrary.simpleMessage(
      "Orario settimanale",
    ),
    "weeklyScheduleTotalHours": m24,
  };
}
