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

  static String m0(name) => "Disponibilità – ${name}";

  static String m1(fields) => "Campi modificati: ${fields}";

  static String m2(duration) => "Durata totale: ${duration}";

  static String m3(price) => "Totale: ${price}";

  static String m4(count) => "${count} prenotazioni";

  static String m5(clientName) => "Appuntamenti di ${clientName}";

  static String m6(hours) => "${hours} ora";

  static String m7(hours, minutes) => "${hours} ora ${minutes} min";

  static String m8(minutes) => "${minutes} min";

  static String m9(id) => "Eccezione non trovata: ${id}";

  static String m10(factor) => "Nessun builder disponibile per ${factor}";

  static String m11(path) => "Pagina non trovata: ${path}";

  static String m12(count) =>
      "${count} ${Intl.plural(count, one: 'giorno', other: 'giorni')}";

  static String m13(dates) => "Alcuni giorni non sono stati salvati: ${dates}.";

  static String m14(details) =>
      "Alcuni giorni non sono stati salvati: ${details}.";

  static String m15(hours) => "${hours}h";

  static String m16(hours, minutes) => "${hours}h ${minutes}m";

  static String m17(date) => "Ultima visita: ${date}";

  static String m18(newTime, staffName) =>
      "L\'appuntamento verrà spostato alle ${newTime} per ${staffName}.";

  static String m19(date) => "Scade il ${date}";

  static String m20(email) => "Invito inviato a ${email}";

  static String m21(name) => "Invitato da ${name}";

  static String m22(count) => "${count} inviti in attesa";

  static String m23(name) => "Vuoi rimuovere ${name} dal team?";

  static String m24(email) => "Vuoi revocare l\'invito per ${email}?";

  static String m25(hoursA, hoursB, total) =>
      "Sett. A: ${hoursA}h | Sett. B: ${hoursB}h | Tot: ${total}h";

  static String m26(week) => "Settimana attuale: ${week}";

  static String m27(count) => "Mostra planning scaduti (${count})";

  static String m28(from) => "Valida dal ${from}";

  static String m29(from, to) => "Valida dal ${from} al ${to}";

  static String m30(from) => "Dal ${from}";

  static String m31(from, to) => "Dal ${from} al ${to}";

  static String m32(hours) => "${hours}h/settimana";

  static String m33(count) => "Crea ${count} appuntamenti";

  static String m34(count) => "${count} conflitti";

  static String m35(count) => "${count} appuntamenti";

  static String m36(count) => "${count} selezionati";

  static String m37(index, total) => "${index} di ${total}";

  static String m38(count) => "${count} appuntamenti creati";

  static String m39(count) => "${count} saltati per conflitto";

  static String m40(index, total) =>
      "Questo è l\'appuntamento ${index} di ${total} nella serie.";

  static String m41(index, total) =>
      "Questo è l\'appuntamento ${index} di ${total} nella serie.";

  static String m42(count) => "${count} servizi";

  static String m43(count) => "${count} membri abilitati";

  static String m44(count) =>
      "${Intl.plural(count, one: '1 servizio selezionato', other: '${count} servizi selezionati')}";

  static String m45(dayName) =>
      "Elimina la fascia oraria settimanale di ogni ${dayName}";

  static String m46(date) => "Elimina solo la fascia oraria di ${date}";

  static String m47(dayName) =>
      "Modifica la fascia oraria settimanale di ogni ${dayName}";

  static String m48(date) => "Modifica solo la fascia oraria di ${date}";

  static String m49(count) => "${count} servizi abilitati";

  static String m50(count) =>
      "${Intl.plural(count, one: '1 giorno', other: '${count} giorni')}";

  static String m51(count) =>
      "${Intl.plural(count, one: '1 ora', other: '${count} ore')}";

  static String m52(count) =>
      "${Intl.plural(count, one: '1 minuto', other: '${count} minuti')}";

  static String m53(selected, total) => "${selected} su ${total}";

  static String m54(hours) => "${hours} ore totale";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "actionApply": MessageLookupByLibrary.simpleMessage("Applica"),
    "actionCancel": MessageLookupByLibrary.simpleMessage("Annulla"),
    "actionClose": MessageLookupByLibrary.simpleMessage("Chiudi"),
    "actionConfirm": MessageLookupByLibrary.simpleMessage("Conferma"),
    "actionDelete": MessageLookupByLibrary.simpleMessage("Elimina"),
    "actionDeleteBooking": MessageLookupByLibrary.simpleMessage(
      "Elimina prenotazione",
    ),
    "actionDeselectAll": MessageLookupByLibrary.simpleMessage(
      "Deseleziona tutti",
    ),
    "actionDiscard": MessageLookupByLibrary.simpleMessage("Annulla"),
    "actionEdit": MessageLookupByLibrary.simpleMessage("Modifica"),
    "actionKeepEditing": MessageLookupByLibrary.simpleMessage(
      "Continua a modificare",
    ),
    "actionRefresh": MessageLookupByLibrary.simpleMessage("Aggiorna"),
    "actionRetry": MessageLookupByLibrary.simpleMessage("Riprova"),
    "actionSave": MessageLookupByLibrary.simpleMessage("Salva"),
    "actionSelectAll": MessageLookupByLibrary.simpleMessage("Seleziona tutti"),
    "addClientToAppointment": MessageLookupByLibrary.simpleMessage(
      "Aggiungi un cliente all\'appuntamento",
    ),
    "addPackage": MessageLookupByLibrary.simpleMessage("Aggiungi pacchetto"),
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
    "applyClientToAllAppointmentsMessage": MessageLookupByLibrary.simpleMessage(
      "Il cliente verrà associato anche agli appuntamenti di questa prenotazione che sono stati assegnati ad altro operatore.",
    ),
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
      "Nota sull\'appuntamento",
    ),
    "appointmentNotesTitle": MessageLookupByLibrary.simpleMessage("Note"),
    "appointmentPriceFree": MessageLookupByLibrary.simpleMessage("Gratuito"),
    "appointmentPriceHint": MessageLookupByLibrary.simpleMessage(
      "Prezzo personalizzato",
    ),
    "appointmentPriceLabel": MessageLookupByLibrary.simpleMessage("Prezzo"),
    "appointmentPriceResetTooltip": MessageLookupByLibrary.simpleMessage(
      "Ripristina prezzo del servizio",
    ),
    "atLeastOneServiceRequired": MessageLookupByLibrary.simpleMessage(
      "Aggiungi almeno un servizio",
    ),
    "authEmail": MessageLookupByLibrary.simpleMessage("Email"),
    "authFirstName": MessageLookupByLibrary.simpleMessage("Nome"),
    "authForgotPassword": MessageLookupByLibrary.simpleMessage(
      "Password dimenticata?",
    ),
    "authForgotPasswordInfo": MessageLookupByLibrary.simpleMessage(
      "Contatta l\'amministratore di sistema per reimpostare la password.",
    ),
    "authInvalidEmail": MessageLookupByLibrary.simpleMessage(
      "Email non valida",
    ),
    "authLastName": MessageLookupByLibrary.simpleMessage("Cognome"),
    "authLogin": MessageLookupByLibrary.simpleMessage("Accedi"),
    "authLoginFailed": MessageLookupByLibrary.simpleMessage(
      "Credenziali non valide. Riprova.",
    ),
    "authLoginFooter": MessageLookupByLibrary.simpleMessage(
      "Accesso riservato agli operatori autorizzati",
    ),
    "authLoginSubtitle": MessageLookupByLibrary.simpleMessage(
      "Accedi al gestionale",
    ),
    "authLogout": MessageLookupByLibrary.simpleMessage("Esci"),
    "authPassword": MessageLookupByLibrary.simpleMessage("Password"),
    "authPasswordTooShort": MessageLookupByLibrary.simpleMessage(
      "Password troppo corta",
    ),
    "authPhone": MessageLookupByLibrary.simpleMessage("Telefono"),
    "authRememberMe": MessageLookupByLibrary.simpleMessage("Ricordami"),
    "authRequiredField": MessageLookupByLibrary.simpleMessage(
      "Campo obbligatorio",
    ),
    "authResetPasswordError": MessageLookupByLibrary.simpleMessage(
      "Si è verificato un errore. Riprova più tardi.",
    ),
    "authResetPasswordMessage": MessageLookupByLibrary.simpleMessage(
      "Inserisci la tua email. Ti invieremo un link per reimpostare la password.",
    ),
    "authResetPasswordSend": MessageLookupByLibrary.simpleMessage("Invia"),
    "authResetPasswordSuccess": MessageLookupByLibrary.simpleMessage(
      "Se l\'email esiste nel sistema, riceverai un link per reimpostare la password.",
    ),
    "authResetPasswordTitle": MessageLookupByLibrary.simpleMessage(
      "Recupera password",
    ),
    "availabilitySave": MessageLookupByLibrary.simpleMessage("Salva modifiche"),
    "availabilityTitle": MessageLookupByLibrary.simpleMessage(
      "Disponibilità settimanale",
    ),
    "availabilityTitleFor": m0,
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
    "bookingHistoryActorCustomer": MessageLookupByLibrary.simpleMessage(
      "Cliente",
    ),
    "bookingHistoryActorStaff": MessageLookupByLibrary.simpleMessage(
      "Operatore",
    ),
    "bookingHistoryActorSystem": MessageLookupByLibrary.simpleMessage(
      "Sistema",
    ),
    "bookingHistoryChangedFields": m1,
    "bookingHistoryEmpty": MessageLookupByLibrary.simpleMessage(
      "Nessun evento registrato",
    ),
    "bookingHistoryError": MessageLookupByLibrary.simpleMessage(
      "Errore nel caricamento dello storico",
    ),
    "bookingHistoryEventAppointmentUpdated":
        MessageLookupByLibrary.simpleMessage("Appuntamento modificato"),
    "bookingHistoryEventCancelled": MessageLookupByLibrary.simpleMessage(
      "Prenotazione cancellata",
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
    "bookingHistoryEventPriceChanged": MessageLookupByLibrary.simpleMessage(
      "Prezzo modificato",
    ),
    "bookingHistoryEventReplaced": MessageLookupByLibrary.simpleMessage(
      "Prenotazione riprogrammata",
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
    "bookingHistoryTitle": MessageLookupByLibrary.simpleMessage(
      "Storico prenotazione",
    ),
    "bookingItems": MessageLookupByLibrary.simpleMessage("Servizi"),
    "bookingNotes": MessageLookupByLibrary.simpleMessage("Note prenotazione"),
    "bookingStaffNotEligibleWarning": MessageLookupByLibrary.simpleMessage(
      "Attenzione: il membro del team selezionato non è abilitato per questo servizio.",
    ),
    "bookingTotal": MessageLookupByLibrary.simpleMessage("Totale"),
    "bookingTotalDuration": m2,
    "bookingTotalPrice": m3,
    "bookingUnavailableTimeWarningAppointment":
        MessageLookupByLibrary.simpleMessage(
          "Attenzione: l’orario selezionato per l’appuntamento include fasce non disponibili per il team scelto.",
        ),
    "bookingUnavailableTimeWarningService": MessageLookupByLibrary.simpleMessage(
      "Attenzione: l’orario di questo servizio include fasce non disponibili per il team scelto.",
    ),
    "bookingsListActionCancel": MessageLookupByLibrary.simpleMessage(
      "Cancella",
    ),
    "bookingsListActionEdit": MessageLookupByLibrary.simpleMessage("Modifica"),
    "bookingsListActionView": MessageLookupByLibrary.simpleMessage("Dettagli"),
    "bookingsListAllLocations": MessageLookupByLibrary.simpleMessage(
      "Tutte le sedi",
    ),
    "bookingsListAllServices": MessageLookupByLibrary.simpleMessage(
      "Tutti i servizi",
    ),
    "bookingsListAllStaff": MessageLookupByLibrary.simpleMessage(
      "Tutti gli operatori",
    ),
    "bookingsListAllStatus": MessageLookupByLibrary.simpleMessage(
      "Tutti gli stati",
    ),
    "bookingsListCancelConfirmMessage": MessageLookupByLibrary.simpleMessage(
      "Questa azione non può essere annullata.",
    ),
    "bookingsListCancelConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Cancellare prenotazione?",
    ),
    "bookingsListCancelSuccess": MessageLookupByLibrary.simpleMessage(
      "Prenotazione cancellata",
    ),
    "bookingsListColumnActions": MessageLookupByLibrary.simpleMessage("Azioni"),
    "bookingsListColumnClient": MessageLookupByLibrary.simpleMessage("Cliente"),
    "bookingsListColumnCreatedAt": MessageLookupByLibrary.simpleMessage(
      "Creato il",
    ),
    "bookingsListColumnCreatedBy": MessageLookupByLibrary.simpleMessage(
      "Creato da",
    ),
    "bookingsListColumnDateTime": MessageLookupByLibrary.simpleMessage(
      "Data/Ora",
    ),
    "bookingsListColumnPrice": MessageLookupByLibrary.simpleMessage("Prezzo"),
    "bookingsListColumnServices": MessageLookupByLibrary.simpleMessage(
      "Servizi",
    ),
    "bookingsListColumnStaff": MessageLookupByLibrary.simpleMessage(
      "Operatore",
    ),
    "bookingsListColumnStatus": MessageLookupByLibrary.simpleMessage("Stato"),
    "bookingsListEmpty": MessageLookupByLibrary.simpleMessage(
      "Nessuna prenotazione trovata",
    ),
    "bookingsListEmptyHint": MessageLookupByLibrary.simpleMessage(
      "Prova a modificare i filtri di ricerca",
    ),
    "bookingsListFilterClient": MessageLookupByLibrary.simpleMessage(
      "Cerca cliente",
    ),
    "bookingsListFilterClientHint": MessageLookupByLibrary.simpleMessage(
      "Nome, email o telefono",
    ),
    "bookingsListFilterFutureOnly": MessageLookupByLibrary.simpleMessage(
      "Solo futuri",
    ),
    "bookingsListFilterIncludePast": MessageLookupByLibrary.simpleMessage(
      "Includi passati",
    ),
    "bookingsListFilterLocation": MessageLookupByLibrary.simpleMessage("Sede"),
    "bookingsListFilterPeriod": MessageLookupByLibrary.simpleMessage("Periodo"),
    "bookingsListFilterService": MessageLookupByLibrary.simpleMessage(
      "Servizio",
    ),
    "bookingsListFilterStaff": MessageLookupByLibrary.simpleMessage(
      "Operatore",
    ),
    "bookingsListFilterStatus": MessageLookupByLibrary.simpleMessage("Stato"),
    "bookingsListFilterTitle": MessageLookupByLibrary.simpleMessage("Filtri"),
    "bookingsListLoadMore": MessageLookupByLibrary.simpleMessage(
      "Carica altre",
    ),
    "bookingsListLoading": MessageLookupByLibrary.simpleMessage(
      "Caricamento...",
    ),
    "bookingsListNoClient": MessageLookupByLibrary.simpleMessage(
      "Nessun cliente",
    ),
    "bookingsListResetFilters": MessageLookupByLibrary.simpleMessage(
      "Reset filtri",
    ),
    "bookingsListSortAsc": MessageLookupByLibrary.simpleMessage("Crescente"),
    "bookingsListSortByAppointment": MessageLookupByLibrary.simpleMessage(
      "Data appuntamento",
    ),
    "bookingsListSortByCreated": MessageLookupByLibrary.simpleMessage(
      "Data creazione",
    ),
    "bookingsListSortDesc": MessageLookupByLibrary.simpleMessage("Decrescente"),
    "bookingsListSourceInternal": MessageLookupByLibrary.simpleMessage(
      "Gestionale",
    ),
    "bookingsListSourceOnline": MessageLookupByLibrary.simpleMessage("Online"),
    "bookingsListSourcePhone": MessageLookupByLibrary.simpleMessage("Telefono"),
    "bookingsListSourceWalkIn": MessageLookupByLibrary.simpleMessage("Walk-in"),
    "bookingsListStatusCancelled": MessageLookupByLibrary.simpleMessage(
      "Cancellato",
    ),
    "bookingsListStatusCompleted": MessageLookupByLibrary.simpleMessage(
      "Completato",
    ),
    "bookingsListStatusConfirmed": MessageLookupByLibrary.simpleMessage(
      "Confermato",
    ),
    "bookingsListStatusNoShow": MessageLookupByLibrary.simpleMessage("No show"),
    "bookingsListStatusPending": MessageLookupByLibrary.simpleMessage(
      "In attesa",
    ),
    "bookingsListTitle": MessageLookupByLibrary.simpleMessage(
      "Elenco Prenotazioni",
    ),
    "bookingsListTotalCount": m4,
    "cancelledBadge": MessageLookupByLibrary.simpleMessage("CANCELLATO"),
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
    "clientAppointmentsTitle": m5,
    "clientAppointmentsUpcoming": MessageLookupByLibrary.simpleMessage(
      "Prossimi",
    ),
    "clientLockedHint": MessageLookupByLibrary.simpleMessage(
      "Il cliente non può essere modificato per questo appuntamento",
    ),
    "clientNoteLabel": MessageLookupByLibrary.simpleMessage("Nota sul cliente"),
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
    "dayFriday": MessageLookupByLibrary.simpleMessage("Venerdì"),
    "dayFridayFull": MessageLookupByLibrary.simpleMessage("venerdì"),
    "dayMonday": MessageLookupByLibrary.simpleMessage("Lunedì"),
    "dayMondayFull": MessageLookupByLibrary.simpleMessage("lunedì"),
    "daySaturday": MessageLookupByLibrary.simpleMessage("Sabato"),
    "daySaturdayFull": MessageLookupByLibrary.simpleMessage("sabato"),
    "daySunday": MessageLookupByLibrary.simpleMessage("Domenica"),
    "daySundayFull": MessageLookupByLibrary.simpleMessage("domenica"),
    "dayThursday": MessageLookupByLibrary.simpleMessage("Giovedì"),
    "dayThursdayFull": MessageLookupByLibrary.simpleMessage("giovedì"),
    "dayTuesday": MessageLookupByLibrary.simpleMessage("Martedì"),
    "dayTuesdayFull": MessageLookupByLibrary.simpleMessage("martedì"),
    "dayWednesday": MessageLookupByLibrary.simpleMessage("Mercoledì"),
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
    "durationHour": m6,
    "durationHourMinute": m7,
    "durationMinute": m8,
    "editCategoryTitle": MessageLookupByLibrary.simpleMessage(
      "Modifica categoria",
    ),
    "editServiceTitle": MessageLookupByLibrary.simpleMessage(
      "Modifica servizio",
    ),
    "emptyCategoriesNotReorderableNote": MessageLookupByLibrary.simpleMessage(
      "Le categorie senza servizi non sono riordinabili e restano in coda.",
    ),
    "errorExceptionNotFound": m9,
    "errorFormFactorBuilderMissing": m10,
    "errorFormFactorBuilderRequired": MessageLookupByLibrary.simpleMessage(
      "Specificare almeno un builder per form factor",
    ),
    "errorNotFound": m11,
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
    "exceptionDurationDays": m12,
    "exceptionEditShift": MessageLookupByLibrary.simpleMessage(
      "Modifica eccezione",
    ),
    "exceptionEditShiftDesc": MessageLookupByLibrary.simpleMessage(
      "Modifica gli orari di questa eccezione",
    ),
    "exceptionEndTime": MessageLookupByLibrary.simpleMessage("Orario fine"),
    "exceptionPartialSaveInfo": m13,
    "exceptionPartialSaveInfoDetailed": m14,
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
    "hoursHoursOnly": m15,
    "hoursMinutesCompact": m16,
    "labelSelect": MessageLookupByLibrary.simpleMessage("Seleziona"),
    "labelStaff": MessageLookupByLibrary.simpleMessage("Team:"),
    "lastVisitLabel": m17,
    "minutesLabel": MessageLookupByLibrary.simpleMessage("min"),
    "moreBookingsDescription": MessageLookupByLibrary.simpleMessage(
      "Consulta lo storico delle prenotazioni",
    ),
    "moreReportsDescription": MessageLookupByLibrary.simpleMessage(
      "Visualizza statistiche e andamento attività",
    ),
    "moreServicesDescription": MessageLookupByLibrary.simpleMessage(
      "Gestisci i servizi offerti, categorie e listini",
    ),
    "moreSubtitle": MessageLookupByLibrary.simpleMessage(
      "Accedi alle altre funzionalità dell\'applicazione",
    ),
    "moreTeamDescription": MessageLookupByLibrary.simpleMessage(
      "Gestisci operatori, sedi e orari di lavoro",
    ),
    "moveAppointmentConfirmMessage": m18,
    "moveAppointmentConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Confermi lo spostamento?",
    ),
    "navAgenda": MessageLookupByLibrary.simpleMessage("Agenda"),
    "navClients": MessageLookupByLibrary.simpleMessage("Clienti"),
    "navMore": MessageLookupByLibrary.simpleMessage("Altro"),
    "navProfile": MessageLookupByLibrary.simpleMessage("Profilo"),
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
    "noServicesFound": MessageLookupByLibrary.simpleMessage(
      "Nessun servizio trovato",
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
    "operatorsEditRole": MessageLookupByLibrary.simpleMessage("Modifica ruolo"),
    "operatorsEmpty": MessageLookupByLibrary.simpleMessage(
      "Nessun operatore configurato",
    ),
    "operatorsExpires": m19,
    "operatorsInviteCopied": MessageLookupByLibrary.simpleMessage(
      "Link di invito copiato",
    ),
    "operatorsInviteEmail": MessageLookupByLibrary.simpleMessage("Email"),
    "operatorsInviteRole": MessageLookupByLibrary.simpleMessage("Ruolo"),
    "operatorsInviteSend": MessageLookupByLibrary.simpleMessage("Invia invito"),
    "operatorsInviteSubtitle": MessageLookupByLibrary.simpleMessage(
      "Invia un invito via email",
    ),
    "operatorsInviteSuccess": m20,
    "operatorsInviteTitle": MessageLookupByLibrary.simpleMessage(
      "Invita operatore",
    ),
    "operatorsInvitedBy": m21,
    "operatorsPendingInvites": MessageLookupByLibrary.simpleMessage(
      "Inviti in attesa",
    ),
    "operatorsPendingInvitesCount": m22,
    "operatorsRemove": MessageLookupByLibrary.simpleMessage(
      "Rimuovi operatore",
    ),
    "operatorsRemoveConfirm": m23,
    "operatorsRemoveSuccess": MessageLookupByLibrary.simpleMessage(
      "Operatore rimosso",
    ),
    "operatorsRevokeInvite": MessageLookupByLibrary.simpleMessage(
      "Revoca invito",
    ),
    "operatorsRevokeInviteConfirm": m24,
    "operatorsRoleAdmin": MessageLookupByLibrary.simpleMessage(
      "Amministratore",
    ),
    "operatorsRoleDescription": MessageLookupByLibrary.simpleMessage(
      "Seleziona il livello di accesso",
    ),
    "operatorsRoleManager": MessageLookupByLibrary.simpleMessage("Manager"),
    "operatorsRoleOwner": MessageLookupByLibrary.simpleMessage("Proprietario"),
    "operatorsRoleStaff": MessageLookupByLibrary.simpleMessage("Staff"),
    "operatorsScopeBusiness": MessageLookupByLibrary.simpleMessage(
      "Tutte le sedi",
    ),
    "operatorsScopeBusinessDesc": MessageLookupByLibrary.simpleMessage(
      "Accesso completo a tutte le sedi del business",
    ),
    "operatorsScopeLocations": MessageLookupByLibrary.simpleMessage(
      "Sedi specifiche",
    ),
    "operatorsScopeLocationsDesc": MessageLookupByLibrary.simpleMessage(
      "Accesso limitato alle sedi selezionate",
    ),
    "operatorsScopeLocationsRequired": MessageLookupByLibrary.simpleMessage(
      "Seleziona almeno una sede",
    ),
    "operatorsScopeSelectLocations": MessageLookupByLibrary.simpleMessage(
      "Seleziona sedi",
    ),
    "operatorsScopeTitle": MessageLookupByLibrary.simpleMessage("Accesso"),
    "operatorsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Gestisci chi può accedere al gestionale",
    ),
    "operatorsTitle": MessageLookupByLibrary.simpleMessage("Operatori"),
    "operatorsYou": MessageLookupByLibrary.simpleMessage("Tu"),
    "planningActive": MessageLookupByLibrary.simpleMessage("Attivo"),
    "planningBiweeklyHours": m25,
    "planningCreateTitle": MessageLookupByLibrary.simpleMessage(
      "Nuovo planning",
    ),
    "planningCurrentWeek": m26,
    "planningDeleteConfirm": MessageLookupByLibrary.simpleMessage(
      "Sei sicuro di voler eliminare questo planning? Gli orari settimanali verranno rimossi.",
    ),
    "planningDeleteTitle": MessageLookupByLibrary.simpleMessage(
      "Elimina planning",
    ),
    "planningEditTitle": MessageLookupByLibrary.simpleMessage(
      "Modifica planning",
    ),
    "planningFuture": MessageLookupByLibrary.simpleMessage("Futuro"),
    "planningHideExpired": MessageLookupByLibrary.simpleMessage(
      "Nascondi planning scaduti",
    ),
    "planningListAdd": MessageLookupByLibrary.simpleMessage(
      "Aggiungi planning",
    ),
    "planningListEmpty": MessageLookupByLibrary.simpleMessage(
      "Nessun planning definito",
    ),
    "planningListTitle": MessageLookupByLibrary.simpleMessage("Planning"),
    "planningOpenEnded": MessageLookupByLibrary.simpleMessage("Senza scadenza"),
    "planningPast": MessageLookupByLibrary.simpleMessage("Passato"),
    "planningSelectDate": MessageLookupByLibrary.simpleMessage(
      "Seleziona data",
    ),
    "planningSetEndDate": MessageLookupByLibrary.simpleMessage(
      "Imposta data fine",
    ),
    "planningShowExpired": m27,
    "planningType": MessageLookupByLibrary.simpleMessage("Tipo planning"),
    "planningTypeBiweekly": MessageLookupByLibrary.simpleMessage(
      "Bisettimanale",
    ),
    "planningTypeUnavailable": MessageLookupByLibrary.simpleMessage(
      "Non disponibile",
    ),
    "planningTypeWeekly": MessageLookupByLibrary.simpleMessage("Settimanale"),
    "planningValidFrom": MessageLookupByLibrary.simpleMessage(
      "Data inizio validità",
    ),
    "planningValidFromOnly": m28,
    "planningValidFromTo": m29,
    "planningValidTo": MessageLookupByLibrary.simpleMessage(
      "Data fine validità",
    ),
    "planningValidityFrom": m30,
    "planningValidityRange": m31,
    "planningWeekA": MessageLookupByLibrary.simpleMessage("Settimana A"),
    "planningWeekB": MessageLookupByLibrary.simpleMessage("Settimana B"),
    "planningWeeklyHours": m32,
    "popularServicesTitle": MessageLookupByLibrary.simpleMessage(
      "I più richiesti",
    ),
    "priceNotAvailable": MessageLookupByLibrary.simpleMessage("N/D"),
    "priceStartingFromPrefix": MessageLookupByLibrary.simpleMessage(
      "a partire da",
    ),
    "priceStartingFromSwitch": MessageLookupByLibrary.simpleMessage(
      "Prezzo \"a partire da\"",
    ),
    "profileTitle": MessageLookupByLibrary.simpleMessage("Profilo"),
    "recurrenceAfter": MessageLookupByLibrary.simpleMessage("Dopo"),
    "recurrenceClientRequired": MessageLookupByLibrary.simpleMessage(
      "È necessario selezionare un cliente per gli appuntamenti ricorrenti",
    ),
    "recurrenceConflictForce": MessageLookupByLibrary.simpleMessage(
      "Crea comunque",
    ),
    "recurrenceConflictForceDescription": MessageLookupByLibrary.simpleMessage(
      "Crea gli appuntamenti anche se ci sono sovrapposizioni",
    ),
    "recurrenceConflictHandling": MessageLookupByLibrary.simpleMessage(
      "Sovrapposizioni",
    ),
    "recurrenceConflictSkip": MessageLookupByLibrary.simpleMessage(
      "Salta date con conflitti",
    ),
    "recurrenceConflictSkipDescription": MessageLookupByLibrary.simpleMessage(
      "Non crea appuntamenti se ci sono sovrapposizioni",
    ),
    "recurrenceDay": MessageLookupByLibrary.simpleMessage("giorno"),
    "recurrenceDays": MessageLookupByLibrary.simpleMessage("giorni"),
    "recurrenceEnds": MessageLookupByLibrary.simpleMessage("Termina"),
    "recurrenceEvery": MessageLookupByLibrary.simpleMessage("Ogni"),
    "recurrenceFrequency": MessageLookupByLibrary.simpleMessage("Frequenza"),
    "recurrenceMonth": MessageLookupByLibrary.simpleMessage("mese"),
    "recurrenceMonths": MessageLookupByLibrary.simpleMessage("mesi"),
    "recurrenceNever": MessageLookupByLibrary.simpleMessage("Per un anno"),
    "recurrenceOccurrences": MessageLookupByLibrary.simpleMessage("occorrenze"),
    "recurrenceOnDate": MessageLookupByLibrary.simpleMessage("Il"),
    "recurrencePreviewConfirm": m33,
    "recurrencePreviewConflicts": m34,
    "recurrencePreviewCount": m35,
    "recurrencePreviewHint": MessageLookupByLibrary.simpleMessage(
      "Deseleziona le date che non vuoi creare",
    ),
    "recurrencePreviewSelected": m36,
    "recurrencePreviewTitle": MessageLookupByLibrary.simpleMessage(
      "Anteprima appuntamenti",
    ),
    "recurrenceRepeatBooking": MessageLookupByLibrary.simpleMessage(
      "Ripeti questo appuntamento",
    ),
    "recurrenceSelectDate": MessageLookupByLibrary.simpleMessage(
      "Seleziona data",
    ),
    "recurrenceSeriesIcon": MessageLookupByLibrary.simpleMessage(
      "Appuntamento ricorrente",
    ),
    "recurrenceSeriesOf": m37,
    "recurrenceSummaryAppointments": MessageLookupByLibrary.simpleMessage(
      "Appuntamenti:",
    ),
    "recurrenceSummaryConflict": MessageLookupByLibrary.simpleMessage(
      "Saltato per conflitto",
    ),
    "recurrenceSummaryCreated": m38,
    "recurrenceSummaryDeleted": MessageLookupByLibrary.simpleMessage(
      "Eliminato",
    ),
    "recurrenceSummaryError": MessageLookupByLibrary.simpleMessage(
      "Errore nella creazione della serie",
    ),
    "recurrenceSummarySkipped": m39,
    "recurrenceSummaryTitle": MessageLookupByLibrary.simpleMessage(
      "Serie creata",
    ),
    "recurrenceWeek": MessageLookupByLibrary.simpleMessage("settimana"),
    "recurrenceWeeks": MessageLookupByLibrary.simpleMessage("settimane"),
    "recurringDeleteChooseScope": MessageLookupByLibrary.simpleMessage(
      "Quali appuntamenti vuoi eliminare?",
    ),
    "recurringDeleteMessage": m40,
    "recurringDeleteTitle": MessageLookupByLibrary.simpleMessage(
      "Elimina appuntamento ricorrente",
    ),
    "recurringEditChooseScope": MessageLookupByLibrary.simpleMessage(
      "Quali appuntamenti vuoi modificare?",
    ),
    "recurringEditMessage": m41,
    "recurringEditTitle": MessageLookupByLibrary.simpleMessage(
      "Modifica appuntamento ricorrente",
    ),
    "recurringScopeAll": MessageLookupByLibrary.simpleMessage("Tutti"),
    "recurringScopeOnlyThis": MessageLookupByLibrary.simpleMessage(
      "Solo questo",
    ),
    "recurringScopeThisAndFuture": MessageLookupByLibrary.simpleMessage(
      "Questo e futuri",
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
    "reportsByDayOfWeek": MessageLookupByLibrary.simpleMessage(
      "Per giorno della settimana",
    ),
    "reportsByHour": MessageLookupByLibrary.simpleMessage("Per fascia oraria"),
    "reportsByLocation": MessageLookupByLibrary.simpleMessage("Per sede"),
    "reportsByPeriod": MessageLookupByLibrary.simpleMessage("Per periodo"),
    "reportsByService": MessageLookupByLibrary.simpleMessage("Per servizio"),
    "reportsByStaff": MessageLookupByLibrary.simpleMessage("Per operatore"),
    "reportsColAppointments": MessageLookupByLibrary.simpleMessage(
      "Appuntamenti",
    ),
    "reportsColAvailableHours": MessageLookupByLibrary.simpleMessage(
      "Effettive",
    ),
    "reportsColAvgDuration": MessageLookupByLibrary.simpleMessage(
      "Durata media",
    ),
    "reportsColAvgRevenue": MessageLookupByLibrary.simpleMessage("Media"),
    "reportsColBlockedHours": MessageLookupByLibrary.simpleMessage("Blocchi"),
    "reportsColCategory": MessageLookupByLibrary.simpleMessage("Categoria"),
    "reportsColDay": MessageLookupByLibrary.simpleMessage("Giorno"),
    "reportsColHour": MessageLookupByLibrary.simpleMessage("Ora"),
    "reportsColHours": MessageLookupByLibrary.simpleMessage("Ore"),
    "reportsColLocation": MessageLookupByLibrary.simpleMessage("Sede"),
    "reportsColOffHours": MessageLookupByLibrary.simpleMessage("Ferie/Assenze"),
    "reportsColPercentage": MessageLookupByLibrary.simpleMessage("%"),
    "reportsColPeriod": MessageLookupByLibrary.simpleMessage("Periodo"),
    "reportsColRevenue": MessageLookupByLibrary.simpleMessage("Incasso"),
    "reportsColScheduledHours": MessageLookupByLibrary.simpleMessage(
      "Programmate",
    ),
    "reportsColService": MessageLookupByLibrary.simpleMessage("Servizio"),
    "reportsColStaff": MessageLookupByLibrary.simpleMessage("Operatore"),
    "reportsColUtilization": MessageLookupByLibrary.simpleMessage(
      "Occupazione",
    ),
    "reportsColWorkedHours": MessageLookupByLibrary.simpleMessage("Prenotate"),
    "reportsFilterLocations": MessageLookupByLibrary.simpleMessage("Sedi"),
    "reportsFilterServices": MessageLookupByLibrary.simpleMessage("Servizi"),
    "reportsFilterStaff": MessageLookupByLibrary.simpleMessage("Staff"),
    "reportsFilterStatus": MessageLookupByLibrary.simpleMessage("Stato"),
    "reportsFullPeriodToggle": MessageLookupByLibrary.simpleMessage(
      "Includi intero periodo (anche futuro)",
    ),
    "reportsNoData": MessageLookupByLibrary.simpleMessage(
      "Nessun dato disponibile",
    ),
    "reportsOccupancyPercentage": MessageLookupByLibrary.simpleMessage(
      "Occupazione",
    ),
    "reportsPresetCustom": MessageLookupByLibrary.simpleMessage(
      "Scegli periodo",
    ),
    "reportsPresetLast3Months": MessageLookupByLibrary.simpleMessage(
      "Ultimi 3 mesi",
    ),
    "reportsPresetLast6Months": MessageLookupByLibrary.simpleMessage(
      "Ultimi 6 mesi",
    ),
    "reportsPresetLastMonth": MessageLookupByLibrary.simpleMessage(
      "Mese scorso",
    ),
    "reportsPresetLastYear": MessageLookupByLibrary.simpleMessage(
      "Anno precedente",
    ),
    "reportsPresetMonth": MessageLookupByLibrary.simpleMessage("Mese corrente"),
    "reportsPresetQuarter": MessageLookupByLibrary.simpleMessage(
      "Trimestre corrente",
    ),
    "reportsPresetSemester": MessageLookupByLibrary.simpleMessage(
      "Semestre corrente",
    ),
    "reportsPresetToday": MessageLookupByLibrary.simpleMessage("Oggi"),
    "reportsPresetWeek": MessageLookupByLibrary.simpleMessage(
      "Questa settimana",
    ),
    "reportsPresetYear": MessageLookupByLibrary.simpleMessage("Anno corrente"),
    "reportsPresets": MessageLookupByLibrary.simpleMessage("Preset periodo"),
    "reportsTabAppointments": MessageLookupByLibrary.simpleMessage(
      "Appuntamenti",
    ),
    "reportsTabStaff": MessageLookupByLibrary.simpleMessage("Team"),
    "reportsTitle": MessageLookupByLibrary.simpleMessage("Report"),
    "reportsTotalAppointments": MessageLookupByLibrary.simpleMessage(
      "Appuntamenti",
    ),
    "reportsTotalHours": MessageLookupByLibrary.simpleMessage("Ore lavorate"),
    "reportsTotalRevenue": MessageLookupByLibrary.simpleMessage("Incasso"),
    "reportsUniqueClients": MessageLookupByLibrary.simpleMessage(
      "Clienti unici",
    ),
    "reportsWorkHoursAvailable": MessageLookupByLibrary.simpleMessage(
      "Effettive",
    ),
    "reportsWorkHoursBlocked": MessageLookupByLibrary.simpleMessage("Blocchi"),
    "reportsWorkHoursOff": MessageLookupByLibrary.simpleMessage(
      "Ferie/Assenze",
    ),
    "reportsWorkHoursScheduled": MessageLookupByLibrary.simpleMessage(
      "Programmate",
    ),
    "reportsWorkHoursSubtitle": MessageLookupByLibrary.simpleMessage(
      "Riepilogo ore programmate, lavorate e assenze",
    ),
    "reportsWorkHoursTitle": MessageLookupByLibrary.simpleMessage("Staff"),
    "reportsWorkHoursUtilization": MessageLookupByLibrary.simpleMessage(
      "Occupazione",
    ),
    "reportsWorkHoursWorked": MessageLookupByLibrary.simpleMessage("Prenotate"),
    "resourceDeleteConfirm": MessageLookupByLibrary.simpleMessage(
      "Eliminare questa risorsa?",
    ),
    "resourceDeleteWarning": MessageLookupByLibrary.simpleMessage(
      "I servizi che usano questa risorsa non saranno più vincolati alla sua disponibilità",
    ),
    "resourceEdit": MessageLookupByLibrary.simpleMessage("Modifica risorsa"),
    "resourceNameLabel": MessageLookupByLibrary.simpleMessage("Nome risorsa"),
    "resourceNew": MessageLookupByLibrary.simpleMessage("Nuova risorsa"),
    "resourceNoServicesSelected": MessageLookupByLibrary.simpleMessage(
      "Nessun servizio associato",
    ),
    "resourceNoneLabel": MessageLookupByLibrary.simpleMessage(
      "Nessuna risorsa richiesta",
    ),
    "resourceNoteLabel": MessageLookupByLibrary.simpleMessage(
      "Note (opzionale)",
    ),
    "resourceQuantityLabel": MessageLookupByLibrary.simpleMessage(
      "Quantità disponibile",
    ),
    "resourceQuantityRequired": MessageLookupByLibrary.simpleMessage(
      "Qtà richiesta",
    ),
    "resourceSelectLabel": MessageLookupByLibrary.simpleMessage(
      "Seleziona risorse",
    ),
    "resourceSelectServices": MessageLookupByLibrary.simpleMessage(
      "Seleziona servizi",
    ),
    "resourceServiceCountPlural": m42,
    "resourceServiceCountSingular": MessageLookupByLibrary.simpleMessage(
      "1 servizio",
    ),
    "resourceServicesLabel": MessageLookupByLibrary.simpleMessage(
      "Servizi che usano questa risorsa",
    ),
    "resourceTypeLabel": MessageLookupByLibrary.simpleMessage(
      "Tipo (opzionale)",
    ),
    "resourcesEmpty": MessageLookupByLibrary.simpleMessage(
      "Nessuna risorsa configurata per questa sede",
    ),
    "resourcesEmptyHint": MessageLookupByLibrary.simpleMessage(
      "Le risorse sono attrezzature o spazi (es. cabine, lettini) che possono essere associati ai servizi",
    ),
    "resourcesTitle": MessageLookupByLibrary.simpleMessage("Risorse"),
    "searchClientPlaceholder": MessageLookupByLibrary.simpleMessage(
      "Cerca cliente...",
    ),
    "searchServices": MessageLookupByLibrary.simpleMessage("Cerca servizio..."),
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
    "serviceEligibleStaffCount": m43,
    "serviceEligibleStaffNone": MessageLookupByLibrary.simpleMessage(
      "Nessun membro abilitato",
    ),
    "servicePackageActiveLabel": MessageLookupByLibrary.simpleMessage(
      "Pacchetto attivo",
    ),
    "servicePackageBrokenLabel": MessageLookupByLibrary.simpleMessage(
      "Non valido",
    ),
    "servicePackageCreatedMessage": MessageLookupByLibrary.simpleMessage(
      "Il pacchetto è stato creato.",
    ),
    "servicePackageCreatedTitle": MessageLookupByLibrary.simpleMessage(
      "Pacchetto creato",
    ),
    "servicePackageDeleteError": MessageLookupByLibrary.simpleMessage(
      "Errore durante l\'eliminazione del pacchetto.",
    ),
    "servicePackageDeleteMessage": MessageLookupByLibrary.simpleMessage(
      "Questa azione non può essere annullata.",
    ),
    "servicePackageDeleteTitle": MessageLookupByLibrary.simpleMessage(
      "Eliminare il pacchetto?",
    ),
    "servicePackageDeletedMessage": MessageLookupByLibrary.simpleMessage(
      "Il pacchetto è stato eliminato.",
    ),
    "servicePackageDeletedTitle": MessageLookupByLibrary.simpleMessage(
      "Pacchetto eliminato",
    ),
    "servicePackageDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "Descrizione",
    ),
    "servicePackageEditTitle": MessageLookupByLibrary.simpleMessage(
      "Modifica pacchetto",
    ),
    "servicePackageExpandError": MessageLookupByLibrary.simpleMessage(
      "Impossibile espandere il pacchetto selezionato.",
    ),
    "servicePackageInactiveLabel": MessageLookupByLibrary.simpleMessage(
      "Inattivo",
    ),
    "servicePackageNameLabel": MessageLookupByLibrary.simpleMessage(
      "Nome pacchetto",
    ),
    "servicePackageNewMenu": MessageLookupByLibrary.simpleMessage(
      "Nuovo pacchetto",
    ),
    "servicePackageNewTitle": MessageLookupByLibrary.simpleMessage(
      "Nuovo pacchetto",
    ),
    "servicePackageNoServices": MessageLookupByLibrary.simpleMessage(
      "Nessun servizio selezionato",
    ),
    "servicePackageOrderLabel": MessageLookupByLibrary.simpleMessage(
      "Ordine servizi",
    ),
    "servicePackageOverrideDurationLabel": MessageLookupByLibrary.simpleMessage(
      "Durata pacchetto (min)",
    ),
    "servicePackageOverridePriceLabel": MessageLookupByLibrary.simpleMessage(
      "Prezzo pacchetto",
    ),
    "servicePackageSaveError": MessageLookupByLibrary.simpleMessage(
      "Errore nel salvataggio del pacchetto.",
    ),
    "servicePackageServicesLabel": MessageLookupByLibrary.simpleMessage(
      "Servizi inclusi",
    ),
    "servicePackageServicesRequired": MessageLookupByLibrary.simpleMessage(
      "Seleziona almeno un servizio",
    ),
    "servicePackageUpdatedMessage": MessageLookupByLibrary.simpleMessage(
      "Il pacchetto è stato aggiornato.",
    ),
    "servicePackageUpdatedTitle": MessageLookupByLibrary.simpleMessage(
      "Pacchetto aggiornato",
    ),
    "servicePackagesEmptyState": MessageLookupByLibrary.simpleMessage(
      "Nessun pacchetto disponibile",
    ),
    "servicePackagesTabLabel": MessageLookupByLibrary.simpleMessage(
      "Pacchetti",
    ),
    "servicePackagesTitle": MessageLookupByLibrary.simpleMessage("Pacchetti"),
    "serviceRequiredResourcesLabel": MessageLookupByLibrary.simpleMessage(
      "Risorse richieste",
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
    "serviceStartsAfterMidnight": MessageLookupByLibrary.simpleMessage(
      "Impossibile aggiungere il servizio: l\'orario supera la mezzanotte. Modifica l\'orario di inizio o l\'operatore.",
    ),
    "servicesLabel": MessageLookupByLibrary.simpleMessage("servizi"),
    "servicesNewServiceMenu": MessageLookupByLibrary.simpleMessage(
      "Nuovo servizio",
    ),
    "servicesSelectedCount": m44,
    "servicesTabLabel": MessageLookupByLibrary.simpleMessage("Servizi"),
    "setPriceToEnable": MessageLookupByLibrary.simpleMessage(
      "Imposta un prezzo per abilitarlo",
    ),
    "shiftDeleteAll": MessageLookupByLibrary.simpleMessage(
      "Elimina tutti questi turni",
    ),
    "shiftDeleteAllDesc": m45,
    "shiftDeleteThisOnly": MessageLookupByLibrary.simpleMessage(
      "Elimina solo questo turno",
    ),
    "shiftDeleteThisOnlyDesc": m46,
    "shiftEditAll": MessageLookupByLibrary.simpleMessage(
      "Modifica tutti questi turni",
    ),
    "shiftEditAllDesc": m47,
    "shiftEditThisOnly": MessageLookupByLibrary.simpleMessage(
      "Modifica solo questo turno",
    ),
    "shiftEditThisOnlyDesc": m48,
    "shiftEditTitle": MessageLookupByLibrary.simpleMessage("Modifica turno"),
    "shiftEndTime": MessageLookupByLibrary.simpleMessage("Ora fine"),
    "shiftStartTime": MessageLookupByLibrary.simpleMessage("Ora inizio"),
    "showAllServices": MessageLookupByLibrary.simpleMessage(
      "Mostra tutti i servizi",
    ),
    "sortByCreatedAtAsc": MessageLookupByLibrary.simpleMessage(
      "Data creazione (vecchi)",
    ),
    "sortByCreatedAtDesc": MessageLookupByLibrary.simpleMessage(
      "Data creazione (nuovi)",
    ),
    "sortByLastNameAsc": MessageLookupByLibrary.simpleMessage("Cognome (A-Z)"),
    "sortByLastNameDesc": MessageLookupByLibrary.simpleMessage("Cognome (Z-A)"),
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
    "statusCancelled": MessageLookupByLibrary.simpleMessage("Cancellato"),
    "statusCompleted": MessageLookupByLibrary.simpleMessage("Completato"),
    "statusConfirmed": MessageLookupByLibrary.simpleMessage("Confermato"),
    "switchBusiness": MessageLookupByLibrary.simpleMessage("Cambia"),
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
    "teamEligibleServicesCount": m49,
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
    "teamLocationAllowCustomerChooseStaffHint":
        MessageLookupByLibrary.simpleMessage(
          "Se disattivato, il sistema assegna automaticamente l\'operatore",
        ),
    "teamLocationAllowCustomerChooseStaffLabel":
        MessageLookupByLibrary.simpleMessage(
          "Consenti ai clienti di scegliere l\'operatore",
        ),
    "teamLocationBookingLimitsSection": MessageLookupByLibrary.simpleMessage(
      "Limiti prenotazione online",
    ),
    "teamLocationDays": m50,
    "teamLocationEmailHint": MessageLookupByLibrary.simpleMessage(
      "Email per notifiche ai clienti",
    ),
    "teamLocationEmailLabel": MessageLookupByLibrary.simpleMessage("Email"),
    "teamLocationHours": m51,
    "teamLocationIsActiveHint": MessageLookupByLibrary.simpleMessage(
      "Se disattivata, la sede non sarà visibile ai clienti",
    ),
    "teamLocationIsActiveLabel": MessageLookupByLibrary.simpleMessage(
      "Sede attiva",
    ),
    "teamLocationLabel": MessageLookupByLibrary.simpleMessage("Sede"),
    "teamLocationMaxBookingAdvanceHint": MessageLookupByLibrary.simpleMessage(
      "Fino a quanto tempo in anticipo possono prenotare",
    ),
    "teamLocationMaxBookingAdvanceLabel": MessageLookupByLibrary.simpleMessage(
      "Prenotazione massima anticipata",
    ),
    "teamLocationMinBookingNoticeHint": MessageLookupByLibrary.simpleMessage(
      "Quanto tempo prima devono prenotare i clienti",
    ),
    "teamLocationMinBookingNoticeLabel": MessageLookupByLibrary.simpleMessage(
      "Preavviso minimo prenotazione",
    ),
    "teamLocationMinGapHint": MessageLookupByLibrary.simpleMessage(
      "Non mostrare orari che lasciano meno di questo tempo libero",
    ),
    "teamLocationMinGapLabel": MessageLookupByLibrary.simpleMessage(
      "Gap minimo accettabile",
    ),
    "teamLocationMinutes": m52,
    "teamLocationNameLabel": MessageLookupByLibrary.simpleMessage("Nome sede"),
    "teamLocationSlotDisplayModeAll": MessageLookupByLibrary.simpleMessage(
      "Massima disponibilità",
    ),
    "teamLocationSlotDisplayModeAllHint": MessageLookupByLibrary.simpleMessage(
      "Mostra tutti gli orari disponibili",
    ),
    "teamLocationSlotDisplayModeLabel": MessageLookupByLibrary.simpleMessage(
      "Modalità visualizzazione",
    ),
    "teamLocationSlotDisplayModeMinGap": MessageLookupByLibrary.simpleMessage(
      "Riduci spazi vuoti",
    ),
    "teamLocationSlotDisplayModeMinGapHint":
        MessageLookupByLibrary.simpleMessage(
          "Nasconde orari che creerebbero buchi troppo piccoli",
        ),
    "teamLocationSlotIntervalHint": MessageLookupByLibrary.simpleMessage(
      "Ogni quanti minuti mostrare un orario disponibile",
    ),
    "teamLocationSlotIntervalLabel": MessageLookupByLibrary.simpleMessage(
      "Intervallo tra gli orari",
    ),
    "teamLocationSmartSlotDescription": MessageLookupByLibrary.simpleMessage(
      "Configura come vengono mostrati gli orari disponibili ai clienti che prenotano online",
    ),
    "teamLocationSmartSlotSection": MessageLookupByLibrary.simpleMessage(
      "Fasce orarie intelligenti",
    ),
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
    "teamSelectedServicesCount": m53,
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
    "validationInvalidNumber": MessageLookupByLibrary.simpleMessage(
      "Numero non valido",
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
    "weeklyScheduleTotalHours": m54,
  };
}
