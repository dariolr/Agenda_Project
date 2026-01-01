// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class L10n {
  L10n();

  static L10n? _current;

  static L10n get current {
    assert(
      _current != null,
      'No instance of L10n was loaded. Try to initialize the L10n delegate before accessing L10n.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<L10n> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = L10n();
      L10n._current = instance;

      return instance;
    });
  }

  static L10n of(BuildContext context) {
    final instance = L10n.maybeOf(context);
    assert(
      instance != null,
      'No instance of L10n present in the widget tree. Did you add L10n.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static L10n? maybeOf(BuildContext context) {
    return Localizations.of<L10n>(context, L10n);
  }

  /// `Agenda Platform`
  String get appTitle {
    return Intl.message(
      'Agenda Platform',
      name: 'appTitle',
      desc: '',
      args: [],
    );
  }

  /// `Agenda`
  String get navAgenda {
    return Intl.message('Agenda', name: 'navAgenda', desc: '', args: []);
  }

  /// `Clienti`
  String get navClients {
    return Intl.message('Clienti', name: 'navClients', desc: '', args: []);
  }

  /// `Servizi`
  String get navServices {
    return Intl.message('Servizi', name: 'navServices', desc: '', args: []);
  }

  /// `Team`
  String get navStaff {
    return Intl.message('Team', name: 'navStaff', desc: '', args: []);
  }

  /// `Profilo`
  String get navProfile {
    return Intl.message('Profilo', name: 'navProfile', desc: '', args: []);
  }

  /// `Elenco Clienti`
  String get clientsTitle {
    return Intl.message(
      'Elenco Clienti',
      name: 'clientsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Specificare almeno un builder per form factor`
  String get errorFormFactorBuilderRequired {
    return Intl.message(
      'Specificare almeno un builder per form factor',
      name: 'errorFormFactorBuilderRequired',
      desc: '',
      args: [],
    );
  }

  /// `Nessun builder disponibile per {factor}`
  String errorFormFactorBuilderMissing(String factor) {
    return Intl.message(
      'Nessun builder disponibile per $factor',
      name: 'errorFormFactorBuilderMissing',
      desc: '',
      args: [factor],
    );
  }

  /// `Errore`
  String get errorTitle {
    return Intl.message('Errore', name: 'errorTitle', desc: '', args: []);
  }

  /// `Pagina non trovata: {path}`
  String errorNotFound(String path) {
    return Intl.message(
      'Pagina non trovata: $path',
      name: 'errorNotFound',
      desc: '',
      args: [path],
    );
  }

  /// `Servizio non trovato`
  String get errorServiceNotFound {
    return Intl.message(
      'Servizio non trovato',
      name: 'errorServiceNotFound',
      desc: '',
      args: [],
    );
  }

  /// `Eccezione non trovata: {id}`
  String errorExceptionNotFound(int id) {
    return Intl.message(
      'Eccezione non trovata: $id',
      name: 'errorExceptionNotFound',
      desc: '',
      args: [id],
    );
  }

  /// `Schermata Team`
  String get staffScreenPlaceholder {
    return Intl.message(
      'Schermata Team',
      name: 'staffScreenPlaceholder',
      desc: '',
      args: [],
    );
  }

  /// `Elimina`
  String get actionDelete {
    return Intl.message('Elimina', name: 'actionDelete', desc: '', args: []);
  }

  /// `Annulla`
  String get actionCancel {
    return Intl.message('Annulla', name: 'actionCancel', desc: '', args: []);
  }

  /// `Conferma`
  String get actionConfirm {
    return Intl.message('Conferma', name: 'actionConfirm', desc: '', args: []);
  }

  /// `Conferma`
  String get actionClose {
    return Intl.message('Conferma', name: 'actionClose', desc: '', args: []);
  }

  /// `Confermi l’eliminazione?`
  String get deleteConfirmationTitle {
    return Intl.message(
      'Confermi l’eliminazione?',
      name: 'deleteConfirmationTitle',
      desc: '',
      args: [],
    );
  }

  /// `Oggi`
  String get agendaToday {
    return Intl.message('Oggi', name: 'agendaToday', desc: '', args: []);
  }

  /// `Giorno precedente`
  String get agendaPrevDay {
    return Intl.message(
      'Giorno precedente',
      name: 'agendaPrevDay',
      desc: '',
      args: [],
    );
  }

  /// `Giorno successivo`
  String get agendaNextDay {
    return Intl.message(
      'Giorno successivo',
      name: 'agendaNextDay',
      desc: '',
      args: [],
    );
  }

  /// `Settimana precedente`
  String get agendaPrevWeek {
    return Intl.message(
      'Settimana precedente',
      name: 'agendaPrevWeek',
      desc: '',
      args: [],
    );
  }

  /// `Settimana successivo`
  String get agendaNextWeek {
    return Intl.message(
      'Settimana successivo',
      name: 'agendaNextWeek',
      desc: '',
      args: [],
    );
  }

  /// `Mese precedente`
  String get agendaPrevMonth {
    return Intl.message(
      'Mese precedente',
      name: 'agendaPrevMonth',
      desc: '',
      args: [],
    );
  }

  /// `Mese successivo`
  String get agendaNextMonth {
    return Intl.message(
      'Mese successivo',
      name: 'agendaNextMonth',
      desc: '',
      args: [],
    );
  }

  /// `Nessuna sede disponibile`
  String get agendaNoLocations {
    return Intl.message(
      'Nessuna sede disponibile',
      name: 'agendaNoLocations',
      desc: '',
      args: [],
    );
  }

  /// `Seleziona sede`
  String get agendaSelectLocation {
    return Intl.message(
      'Seleziona sede',
      name: 'agendaSelectLocation',
      desc: '',
      args: [],
    );
  }

  /// `Tutte le sedi`
  String get allLocations {
    return Intl.message(
      'Tutte le sedi',
      name: 'allLocations',
      desc: '',
      args: [],
    );
  }

  /// `Disponibilità settimanale`
  String get availabilityTitle {
    return Intl.message(
      'Disponibilità settimanale',
      name: 'availabilityTitle',
      desc: '',
      args: [],
    );
  }

  /// `Disponibilità – {name}`
  String availabilityTitleFor(String name) {
    return Intl.message(
      'Disponibilità – $name',
      name: 'availabilityTitleFor',
      desc: '',
      args: [name],
    );
  }

  /// `Salva modifiche`
  String get availabilitySave {
    return Intl.message(
      'Salva modifiche',
      name: 'availabilitySave',
      desc: '',
      args: [],
    );
  }

  /// `Settimana corrente`
  String get currentWeek {
    return Intl.message(
      'Settimana corrente',
      name: 'currentWeek',
      desc: '',
      args: [],
    );
  }

  /// `{hours}h {minutes}m`
  String hoursMinutesCompact(Object hours, Object minutes) {
    return Intl.message(
      '${hours}h ${minutes}m',
      name: 'hoursMinutesCompact',
      desc: '',
      args: [hours, minutes],
    );
  }

  /// `{hours}h`
  String hoursHoursOnly(Object hours) {
    return Intl.message(
      '${hours}h',
      name: 'hoursHoursOnly',
      desc: '',
      args: [hours],
    );
  }

  /// `Team:`
  String get labelStaff {
    return Intl.message('Team:', name: 'labelStaff', desc: '', args: []);
  }

  /// `Seleziona`
  String get labelSelect {
    return Intl.message('Seleziona', name: 'labelSelect', desc: '', args: []);
  }

  /// `Disponibilità`
  String get staffHubAvailabilityTitle {
    return Intl.message(
      'Disponibilità',
      name: 'staffHubAvailabilityTitle',
      desc: '',
      args: [],
    );
  }

  /// `Configura gli orari di lavoro settimanali`
  String get staffHubAvailabilitySubtitle {
    return Intl.message(
      'Configura gli orari di lavoro settimanali',
      name: 'staffHubAvailabilitySubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Team`
  String get staffHubTeamTitle {
    return Intl.message('Team', name: 'staffHubTeamTitle', desc: '', args: []);
  }

  /// `Gestione membri e ruoli`
  String get staffHubTeamSubtitle {
    return Intl.message(
      'Gestione membri e ruoli',
      name: 'staffHubTeamSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Statistiche`
  String get staffHubStatsTitle {
    return Intl.message(
      'Statistiche',
      name: 'staffHubStatsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Performance e carichi di lavoro`
  String get staffHubStatsSubtitle {
    return Intl.message(
      'Performance e carichi di lavoro',
      name: 'staffHubStatsSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Non ancora disponibile`
  String get staffHubNotYetAvailable {
    return Intl.message(
      'Non ancora disponibile',
      name: 'staffHubNotYetAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Modifica orari`
  String get staffEditHours {
    return Intl.message(
      'Modifica orari',
      name: 'staffEditHours',
      desc: '',
      args: [],
    );
  }

  /// `Modifica`
  String get actionEdit {
    return Intl.message('Modifica', name: 'actionEdit', desc: '', args: []);
  }

  /// `{minutes} min`
  String durationMinute(Object minutes) {
    return Intl.message(
      '$minutes min',
      name: 'durationMinute',
      desc: '',
      args: [minutes],
    );
  }

  /// `{hours} ora`
  String durationHour(Object hours) {
    return Intl.message(
      '$hours ora',
      name: 'durationHour',
      desc: '',
      args: [hours],
    );
  }

  /// `{hours} ora {minutes} min`
  String durationHourMinute(Object hours, Object minutes) {
    return Intl.message(
      '$hours ora $minutes min',
      name: 'durationHourMinute',
      desc: '',
      args: [hours, minutes],
    );
  }

  /// `Gratis`
  String get freeLabel {
    return Intl.message('Gratis', name: 'freeLabel', desc: '', args: []);
  }

  /// `a partire da`
  String get priceStartingFromPrefix {
    return Intl.message(
      'a partire da',
      name: 'priceStartingFromPrefix',
      desc: '',
      args: [],
    );
  }

  /// `N/D`
  String get priceNotAvailable {
    return Intl.message('N/D', name: 'priceNotAvailable', desc: '', args: []);
  }

  /// `Nuovo cliente`
  String get clientsNew {
    return Intl.message(
      'Nuovo cliente',
      name: 'clientsNew',
      desc: '',
      args: [],
    );
  }

  /// `Modifica cliente`
  String get clientsEdit {
    return Intl.message(
      'Modifica cliente',
      name: 'clientsEdit',
      desc: '',
      args: [],
    );
  }

  /// `Nessun cliente`
  String get clientsEmpty {
    return Intl.message(
      'Nessun cliente',
      name: 'clientsEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Salva`
  String get actionSave {
    return Intl.message('Salva', name: 'actionSave', desc: '', args: []);
  }

  /// `Tutti`
  String get filterAll {
    return Intl.message('Tutti', name: 'filterAll', desc: '', args: []);
  }

  /// `VIP`
  String get filterVIP {
    return Intl.message('VIP', name: 'filterVIP', desc: '', args: []);
  }

  /// `Inattivi`
  String get filterInactive {
    return Intl.message('Inattivi', name: 'filterInactive', desc: '', args: []);
  }

  /// `Nuovi`
  String get filterNew {
    return Intl.message('Nuovi', name: 'filterNew', desc: '', args: []);
  }

  /// `Nome`
  String get formFirstName {
    return Intl.message('Nome', name: 'formFirstName', desc: '', args: []);
  }

  /// `Cognome`
  String get formLastName {
    return Intl.message('Cognome', name: 'formLastName', desc: '', args: []);
  }

  /// `Email`
  String get formEmail {
    return Intl.message('Email', name: 'formEmail', desc: '', args: []);
  }

  /// `Telefono`
  String get formPhone {
    return Intl.message('Telefono', name: 'formPhone', desc: '', args: []);
  }

  /// `Note (non visibili al cliente)`
  String get formNotes {
    return Intl.message(
      'Note (non visibili al cliente)',
      name: 'formNotes',
      desc: '',
      args: [],
    );
  }

  /// `Richiesto`
  String get validationRequired {
    return Intl.message(
      'Richiesto',
      name: 'validationRequired',
      desc: '',
      args: [],
    );
  }

  /// `Email non valida`
  String get validationInvalidEmail {
    return Intl.message(
      'Email non valida',
      name: 'validationInvalidEmail',
      desc: '',
      args: [],
    );
  }

  /// `Telefono non valido`
  String get validationInvalidPhone {
    return Intl.message(
      'Telefono non valido',
      name: 'validationInvalidPhone',
      desc: '',
      args: [],
    );
  }

  /// `Ultima visita: {date}`
  String lastVisitLabel(String date) {
    return Intl.message(
      'Ultima visita: $date',
      name: 'lastVisitLabel',
      desc: '',
      args: [date],
    );
  }

  /// `Inserire almeno nome o cognome`
  String get validationNameOrLastNameRequired {
    return Intl.message(
      'Inserire almeno nome o cognome',
      name: 'validationNameOrLastNameRequired',
      desc: '',
      args: [],
    );
  }

  /// `Aggiungi`
  String get agendaAdd {
    return Intl.message('Aggiungi', name: 'agendaAdd', desc: '', args: []);
  }

  /// `Aggiungi un...`
  String get agendaAddTitle {
    return Intl.message(
      'Aggiungi un...',
      name: 'agendaAddTitle',
      desc: '',
      args: [],
    );
  }

  /// `Nuovo appuntamento`
  String get agendaAddAppointment {
    return Intl.message(
      'Nuovo appuntamento',
      name: 'agendaAddAppointment',
      desc: '',
      args: [],
    );
  }

  /// `Nuovo blocco`
  String get agendaAddBlock {
    return Intl.message(
      'Nuovo blocco',
      name: 'agendaAddBlock',
      desc: '',
      args: [],
    );
  }

  /// `Nuovo appuntamento`
  String get appointmentDialogTitleNew {
    return Intl.message(
      'Nuovo appuntamento',
      name: 'appointmentDialogTitleNew',
      desc: '',
      args: [],
    );
  }

  /// `Modifica appuntamento`
  String get appointmentDialogTitleEdit {
    return Intl.message(
      'Modifica appuntamento',
      name: 'appointmentDialogTitleEdit',
      desc: '',
      args: [],
    );
  }

  /// `Data`
  String get formDate {
    return Intl.message('Data', name: 'formDate', desc: '', args: []);
  }

  /// `Servizio`
  String get formService {
    return Intl.message('Servizio', name: 'formService', desc: '', args: []);
  }

  /// `Cliente`
  String get formClient {
    return Intl.message('Cliente', name: 'formClient', desc: '', args: []);
  }

  /// `Team`
  String get formStaff {
    return Intl.message('Team', name: 'formStaff', desc: '', args: []);
  }

  /// `Dettagli prenotazione`
  String get bookingDetails {
    return Intl.message(
      'Dettagli prenotazione',
      name: 'bookingDetails',
      desc: '',
      args: [],
    );
  }

  /// `Note prenotazione`
  String get bookingNotes {
    return Intl.message(
      'Note prenotazione',
      name: 'bookingNotes',
      desc: '',
      args: [],
    );
  }

  /// `Note`
  String get appointmentNotesTitle {
    return Intl.message(
      'Note',
      name: 'appointmentNotesTitle',
      desc: '',
      args: [],
    );
  }

  /// `Nota appuntamento`
  String get appointmentNoteLabel {
    return Intl.message(
      'Nota appuntamento',
      name: 'appointmentNoteLabel',
      desc: '',
      args: [],
    );
  }

  /// `Nota cliente`
  String get clientNoteLabel {
    return Intl.message(
      'Nota cliente',
      name: 'clientNoteLabel',
      desc: '',
      args: [],
    );
  }

  /// `Servizi`
  String get bookingItems {
    return Intl.message('Servizi', name: 'bookingItems', desc: '', args: []);
  }

  /// `Totale`
  String get bookingTotal {
    return Intl.message('Totale', name: 'bookingTotal', desc: '', args: []);
  }

  /// `Attenzione: l’orario selezionato per l’appuntamento include fasce non disponibili per il team scelto.`
  String get bookingUnavailableTimeWarningAppointment {
    return Intl.message(
      'Attenzione: l’orario selezionato per l’appuntamento include fasce non disponibili per il team scelto.',
      name: 'bookingUnavailableTimeWarningAppointment',
      desc: '',
      args: [],
    );
  }

  /// `Attenzione: l’orario di questo servizio include fasce non disponibili per il team scelto.`
  String get bookingUnavailableTimeWarningService {
    return Intl.message(
      'Attenzione: l’orario di questo servizio include fasce non disponibili per il team scelto.',
      name: 'bookingUnavailableTimeWarningService',
      desc: '',
      args: [],
    );
  }

  /// `Attenzione: il membro del team selezionato non è abilitato per questo servizio.`
  String get bookingStaffNotEligibleWarning {
    return Intl.message(
      'Attenzione: il membro del team selezionato non è abilitato per questo servizio.',
      name: 'bookingStaffNotEligibleWarning',
      desc: '',
      args: [],
    );
  }

  /// `Elimina prenotazione`
  String get actionDeleteBooking {
    return Intl.message(
      'Elimina prenotazione',
      name: 'actionDeleteBooking',
      desc: '',
      args: [],
    );
  }

  /// `Eliminare l'appuntamento?`
  String get deleteAppointmentConfirmTitle {
    return Intl.message(
      'Eliminare l\'appuntamento?',
      name: 'deleteAppointmentConfirmTitle',
      desc: '',
      args: [],
    );
  }

  /// `L'appuntamento verrà rimosso. L'operazione non può essere annullata.`
  String get deleteAppointmentConfirmMessage {
    return Intl.message(
      'L\'appuntamento verrà rimosso. L\'operazione non può essere annullata.',
      name: 'deleteAppointmentConfirmMessage',
      desc: '',
      args: [],
    );
  }

  /// `Eliminare l’intera prenotazione?`
  String get deleteBookingConfirmTitle {
    return Intl.message(
      'Eliminare l’intera prenotazione?',
      name: 'deleteBookingConfirmTitle',
      desc: '',
      args: [],
    );
  }

  /// `Verranno rimossi tutti i servizi collegati. L'operazione non può essere annullata.`
  String get deleteBookingConfirmMessage {
    return Intl.message(
      'Verranno rimossi tutti i servizi collegati. L\'operazione non può essere annullata.',
      name: 'deleteBookingConfirmMessage',
      desc: '',
      args: [],
    );
  }

  /// `Sedi`
  String get teamLocationsLabel {
    return Intl.message('Sedi', name: 'teamLocationsLabel', desc: '', args: []);
  }

  /// `Team`
  String get teamStaffLabel {
    return Intl.message('Team', name: 'teamStaffLabel', desc: '', args: []);
  }

  /// `Aggiungi membro`
  String get teamAddStaff {
    return Intl.message(
      'Aggiungi membro',
      name: 'teamAddStaff',
      desc: '',
      args: [],
    );
  }

  /// `Nessun membro in questa sede`
  String get teamNoStaffInLocation {
    return Intl.message(
      'Nessun membro in questa sede',
      name: 'teamNoStaffInLocation',
      desc: '',
      args: [],
    );
  }

  /// `Impossibile eliminare la sede`
  String get teamDeleteLocationBlockedTitle {
    return Intl.message(
      'Impossibile eliminare la sede',
      name: 'teamDeleteLocationBlockedTitle',
      desc: '',
      args: [],
    );
  }

  /// `Rimuovi prima tutti i membri del team associati.`
  String get teamDeleteLocationBlockedMessage {
    return Intl.message(
      'Rimuovi prima tutti i membri del team associati.',
      name: 'teamDeleteLocationBlockedMessage',
      desc: '',
      args: [],
    );
  }

  /// `Eliminare la sede?`
  String get teamDeleteLocationTitle {
    return Intl.message(
      'Eliminare la sede?',
      name: 'teamDeleteLocationTitle',
      desc: '',
      args: [],
    );
  }

  /// `La sede verrà rimossa dal team. L'operazione non può essere annullata.`
  String get teamDeleteLocationMessage {
    return Intl.message(
      'La sede verrà rimossa dal team. L\'operazione non può essere annullata.',
      name: 'teamDeleteLocationMessage',
      desc: '',
      args: [],
    );
  }

  /// `Eliminare il membro del team?`
  String get teamDeleteStaffTitle {
    return Intl.message(
      'Eliminare il membro del team?',
      name: 'teamDeleteStaffTitle',
      desc: '',
      args: [],
    );
  }

  /// `Il membro verrà rimosso dal team. L'operazione non può essere annullata.`
  String get teamDeleteStaffMessage {
    return Intl.message(
      'Il membro verrà rimosso dal team. L\'operazione non può essere annullata.',
      name: 'teamDeleteStaffMessage',
      desc: '',
      args: [],
    );
  }

  /// `Nuova sede`
  String get teamNewLocationTitle {
    return Intl.message(
      'Nuova sede',
      name: 'teamNewLocationTitle',
      desc: '',
      args: [],
    );
  }

  /// `Modifica sede`
  String get teamEditLocationTitle {
    return Intl.message(
      'Modifica sede',
      name: 'teamEditLocationTitle',
      desc: '',
      args: [],
    );
  }

  /// `Nome sede`
  String get teamLocationNameLabel {
    return Intl.message(
      'Nome sede',
      name: 'teamLocationNameLabel',
      desc: '',
      args: [],
    );
  }

  /// `Indirizzo`
  String get teamLocationAddressLabel {
    return Intl.message(
      'Indirizzo',
      name: 'teamLocationAddressLabel',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get teamLocationEmailLabel {
    return Intl.message(
      'Email',
      name: 'teamLocationEmailLabel',
      desc: '',
      args: [],
    );
  }

  /// `Email per notifiche ai clienti`
  String get teamLocationEmailHint {
    return Intl.message(
      'Email per notifiche ai clienti',
      name: 'teamLocationEmailHint',
      desc: '',
      args: [],
    );
  }

  /// `Sede attiva`
  String get teamLocationIsActiveLabel {
    return Intl.message(
      'Sede attiva',
      name: 'teamLocationIsActiveLabel',
      desc: '',
      args: [],
    );
  }

  /// `Se disattivata, la sede non sarà visibile ai clienti`
  String get teamLocationIsActiveHint {
    return Intl.message(
      'Se disattivata, la sede non sarà visibile ai clienti',
      name: 'teamLocationIsActiveHint',
      desc: '',
      args: [],
    );
  }

  /// `Nuovo membro del team`
  String get teamNewStaffTitle {
    return Intl.message(
      'Nuovo membro del team',
      name: 'teamNewStaffTitle',
      desc: '',
      args: [],
    );
  }

  /// `Modifica membro del team`
  String get teamEditStaffTitle {
    return Intl.message(
      'Modifica membro del team',
      name: 'teamEditStaffTitle',
      desc: '',
      args: [],
    );
  }

  /// `Nome`
  String get teamStaffNameLabel {
    return Intl.message('Nome', name: 'teamStaffNameLabel', desc: '', args: []);
  }

  /// `Cognome`
  String get teamStaffSurnameLabel {
    return Intl.message(
      'Cognome',
      name: 'teamStaffSurnameLabel',
      desc: '',
      args: [],
    );
  }

  /// `Colore`
  String get teamStaffColorLabel {
    return Intl.message(
      'Colore',
      name: 'teamStaffColorLabel',
      desc: '',
      args: [],
    );
  }

  /// `Sedi associate`
  String get teamStaffLocationsLabel {
    return Intl.message(
      'Sedi associate',
      name: 'teamStaffLocationsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Se il membro lavora su più sedi, ricorda di allineare disponibilità e orari con le sedi selezionate.`
  String get teamStaffMultiLocationWarning {
    return Intl.message(
      'Se il membro lavora su più sedi, ricorda di allineare disponibilità e orari con le sedi selezionate.',
      name: 'teamStaffMultiLocationWarning',
      desc: '',
      args: [],
    );
  }

  /// `Team abilitato`
  String get teamEligibleStaffLabel {
    return Intl.message(
      'Team abilitato',
      name: 'teamEligibleStaffLabel',
      desc: '',
      args: [],
    );
  }

  /// `Servizi abilitati`
  String get teamEligibleServicesLabel {
    return Intl.message(
      'Servizi abilitati',
      name: 'teamEligibleServicesLabel',
      desc: '',
      args: [],
    );
  }

  /// `Seleziona tutto`
  String get teamSelectAllServices {
    return Intl.message(
      'Seleziona tutto',
      name: 'teamSelectAllServices',
      desc: '',
      args: [],
    );
  }

  /// `{count} servizi abilitati`
  String teamEligibleServicesCount(int count) {
    return Intl.message(
      '$count servizi abilitati',
      name: 'teamEligibleServicesCount',
      desc: '',
      args: [count],
    );
  }

  /// `Nessun servizio abilitato`
  String get teamEligibleServicesNone {
    return Intl.message(
      'Nessun servizio abilitato',
      name: 'teamEligibleServicesNone',
      desc: '',
      args: [],
    );
  }

  /// `Servizi selezionati`
  String get teamSelectedServicesButton {
    return Intl.message(
      'Servizi selezionati',
      name: 'teamSelectedServicesButton',
      desc: '',
      args: [],
    );
  }

  /// `{selected} su {total}`
  String teamSelectedServicesCount(int selected, int total) {
    return Intl.message(
      '$selected su $total',
      name: 'teamSelectedServicesCount',
      desc: '',
      args: [selected, total],
    );
  }

  /// `Servizi`
  String get teamServicesLabel {
    return Intl.message(
      'Servizi',
      name: 'teamServicesLabel',
      desc: '',
      args: [],
    );
  }

  /// `Seleziona sedi`
  String get teamChooseLocationsButton {
    return Intl.message(
      'Seleziona sedi',
      name: 'teamChooseLocationsButton',
      desc: '',
      args: [],
    );
  }

  /// `Seleziona la sede`
  String get teamChooseLocationSingleButton {
    return Intl.message(
      'Seleziona la sede',
      name: 'teamChooseLocationSingleButton',
      desc: '',
      args: [],
    );
  }

  /// `Sede`
  String get teamLocationLabel {
    return Intl.message('Sede', name: 'teamLocationLabel', desc: '', args: []);
  }

  /// `Seleziona tutto`
  String get teamSelectAllLocations {
    return Intl.message(
      'Seleziona tutto',
      name: 'teamSelectAllLocations',
      desc: '',
      args: [],
    );
  }

  /// `Abilitato alle prenotazioni online`
  String get teamStaffBookableOnlineLabel {
    return Intl.message(
      'Abilitato alle prenotazioni online',
      name: 'teamStaffBookableOnlineLabel',
      desc: '',
      args: [],
    );
  }

  /// `Non prenotabile online`
  String get staffNotBookableOnlineTooltip {
    return Intl.message(
      'Non prenotabile online',
      name: 'staffNotBookableOnlineTooltip',
      desc: '',
      args: [],
    );
  }

  /// `Non prenotabile online`
  String get staffNotBookableOnlineTitle {
    return Intl.message(
      'Non prenotabile online',
      name: 'staffNotBookableOnlineTitle',
      desc: '',
      args: [],
    );
  }

  /// `Questo membro del team non è abilitato alle prenotazioni online. Puoi modificare l’impostazione dal form di modifica dello staff.`
  String get staffNotBookableOnlineMessage {
    return Intl.message(
      'Questo membro del team non è abilitato alle prenotazioni online. Puoi modificare l’impostazione dal form di modifica dello staff.',
      name: 'staffNotBookableOnlineMessage',
      desc: '',
      args: [],
    );
  }

  /// `{count} membri abilitati`
  String serviceEligibleStaffCount(int count) {
    return Intl.message(
      '$count membri abilitati',
      name: 'serviceEligibleStaffCount',
      desc: '',
      args: [count],
    );
  }

  /// `Nessun membro abilitato`
  String get serviceEligibleStaffNone {
    return Intl.message(
      'Nessun membro abilitato',
      name: 'serviceEligibleStaffNone',
      desc: '',
      args: [],
    );
  }

  /// `Riordina sedi e membri del team trascinandoli. Seleziona se ordinare sedi o team. L’ordine sarà lo stesso anche nella sezione agenda.`
  String get teamReorderHelpDescription {
    return Intl.message(
      'Riordina sedi e membri del team trascinandoli. Seleziona se ordinare sedi o team. L’ordine sarà lo stesso anche nella sezione agenda.',
      name: 'teamReorderHelpDescription',
      desc: '',
      args: [],
    );
  }

  /// `Nuova categoria`
  String get createCategoryButtonLabel {
    return Intl.message(
      'Nuova categoria',
      name: 'createCategoryButtonLabel',
      desc: '',
      args: [],
    );
  }

  /// `Nuovo servizio`
  String get servicesNewServiceMenu {
    return Intl.message(
      'Nuovo servizio',
      name: 'servicesNewServiceMenu',
      desc: '',
      args: [],
    );
  }

  /// `Modifica ordinamento`
  String get reorderTitle {
    return Intl.message(
      'Modifica ordinamento',
      name: 'reorderTitle',
      desc: '',
      args: [],
    );
  }

  /// `Aggiungi servizio`
  String get addServiceTooltip {
    return Intl.message(
      'Aggiungi servizio',
      name: 'addServiceTooltip',
      desc: '',
      args: [],
    );
  }

  /// `Impossibile eliminare`
  String get cannotDeleteTitle {
    return Intl.message(
      'Impossibile eliminare',
      name: 'cannotDeleteTitle',
      desc: '',
      args: [],
    );
  }

  /// `La categoria contiene uno o più servizi.`
  String get cannotDeleteCategoryContent {
    return Intl.message(
      'La categoria contiene uno o più servizi.',
      name: 'cannotDeleteCategoryContent',
      desc: '',
      args: [],
    );
  }

  /// `Nessun servizio in questa categoria`
  String get noServicesInCategory {
    return Intl.message(
      'Nessun servizio in questa categoria',
      name: 'noServicesInCategory',
      desc: '',
      args: [],
    );
  }

  /// `Non prenotabile online`
  String get notBookableOnline {
    return Intl.message(
      'Non prenotabile online',
      name: 'notBookableOnline',
      desc: '',
      args: [],
    );
  }

  /// `Duplica`
  String get duplicateAction {
    return Intl.message('Duplica', name: 'duplicateAction', desc: '', args: []);
  }

  /// `Eliminare il servizio?`
  String get deleteServiceQuestion {
    return Intl.message(
      'Eliminare il servizio?',
      name: 'deleteServiceQuestion',
      desc: '',
      args: [],
    );
  }

  /// `Questa azione non può essere annullata.`
  String get cannotUndoWarning {
    return Intl.message(
      'Questa azione non può essere annullata.',
      name: 'cannotUndoWarning',
      desc: '',
      args: [],
    );
  }

  /// `Nuova categoria`
  String get newCategoryTitle {
    return Intl.message(
      'Nuova categoria',
      name: 'newCategoryTitle',
      desc: '',
      args: [],
    );
  }

  /// `Modifica categoria`
  String get editCategoryTitle {
    return Intl.message(
      'Modifica categoria',
      name: 'editCategoryTitle',
      desc: '',
      args: [],
    );
  }

  /// `Nome *`
  String get fieldNameRequiredLabel {
    return Intl.message(
      'Nome *',
      name: 'fieldNameRequiredLabel',
      desc: '',
      args: [],
    );
  }

  /// `Il nome è obbligatorio`
  String get fieldNameRequiredError {
    return Intl.message(
      'Il nome è obbligatorio',
      name: 'fieldNameRequiredError',
      desc: '',
      args: [],
    );
  }

  /// `Esiste già una categoria con questo nome`
  String get categoryDuplicateError {
    return Intl.message(
      'Esiste già una categoria con questo nome',
      name: 'categoryDuplicateError',
      desc: '',
      args: [],
    );
  }

  /// `Descrizione`
  String get fieldDescriptionLabel {
    return Intl.message(
      'Descrizione',
      name: 'fieldDescriptionLabel',
      desc: '',
      args: [],
    );
  }

  /// `Colore servizio`
  String get serviceColorLabel {
    return Intl.message(
      'Colore servizio',
      name: 'serviceColorLabel',
      desc: '',
      args: [],
    );
  }

  /// `Nuovo servizio`
  String get newServiceTitle {
    return Intl.message(
      'Nuovo servizio',
      name: 'newServiceTitle',
      desc: '',
      args: [],
    );
  }

  /// `Modifica servizio`
  String get editServiceTitle {
    return Intl.message(
      'Modifica servizio',
      name: 'editServiceTitle',
      desc: '',
      args: [],
    );
  }

  /// `Categoria *`
  String get fieldCategoryRequiredLabel {
    return Intl.message(
      'Categoria *',
      name: 'fieldCategoryRequiredLabel',
      desc: '',
      args: [],
    );
  }

  /// `Durata *`
  String get fieldDurationRequiredLabel {
    return Intl.message(
      'Durata *',
      name: 'fieldDurationRequiredLabel',
      desc: '',
      args: [],
    );
  }

  /// `Seleziona una durata`
  String get fieldDurationRequiredError {
    return Intl.message(
      'Seleziona una durata',
      name: 'fieldDurationRequiredError',
      desc: '',
      args: [],
    );
  }

  /// `Prezzo`
  String get fieldPriceLabel {
    return Intl.message('Prezzo', name: 'fieldPriceLabel', desc: '', args: []);
  }

  /// `Tempo di lavorazione`
  String get fieldProcessingTimeLabel {
    return Intl.message(
      'Tempo di lavorazione',
      name: 'fieldProcessingTimeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Tempo bloccato`
  String get fieldBlockedTimeLabel {
    return Intl.message(
      'Tempo bloccato',
      name: 'fieldBlockedTimeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Tempo aggiuntivo`
  String get additionalTimeSwitch {
    return Intl.message(
      'Tempo aggiuntivo',
      name: 'additionalTimeSwitch',
      desc: '',
      args: [],
    );
  }

  /// `Tempo di lavorazione`
  String get additionalTimeOptionProcessing {
    return Intl.message(
      'Tempo di lavorazione',
      name: 'additionalTimeOptionProcessing',
      desc: '',
      args: [],
    );
  }

  /// `Tempo bloccato`
  String get additionalTimeOptionBlocked {
    return Intl.message(
      'Tempo bloccato',
      name: 'additionalTimeOptionBlocked',
      desc: '',
      args: [],
    );
  }

  /// `Prenotabile online`
  String get bookableOnlineSwitch {
    return Intl.message(
      'Prenotabile online',
      name: 'bookableOnlineSwitch',
      desc: '',
      args: [],
    );
  }

  /// `Servizio gratuito`
  String get freeServiceSwitch {
    return Intl.message(
      'Servizio gratuito',
      name: 'freeServiceSwitch',
      desc: '',
      args: [],
    );
  }

  /// `Prezzo "a partire da"`
  String get priceStartingFromSwitch {
    return Intl.message(
      'Prezzo "a partire da"',
      name: 'priceStartingFromSwitch',
      desc: '',
      args: [],
    );
  }

  /// `Imposta un prezzo per abilitarlo`
  String get setPriceToEnable {
    return Intl.message(
      'Imposta un prezzo per abilitarlo',
      name: 'setPriceToEnable',
      desc: '',
      args: [],
    );
  }

  /// `Esiste già un servizio con questo nome`
  String get serviceDuplicateError {
    return Intl.message(
      'Esiste già un servizio con questo nome',
      name: 'serviceDuplicateError',
      desc: '',
      args: [],
    );
  }

  /// `Riordina categorie e servizi trascinandoli: l’ordine sarà lo stesso anche nella prenotazione online. Seleziona se ordinare categorie o servizi.`
  String get reorderHelpDescription {
    return Intl.message(
      'Riordina categorie e servizi trascinandoli: l’ordine sarà lo stesso anche nella prenotazione online. Seleziona se ordinare categorie o servizi.',
      name: 'reorderHelpDescription',
      desc: '',
      args: [],
    );
  }

  /// `Categorie`
  String get reorderCategoriesLabel {
    return Intl.message(
      'Categorie',
      name: 'reorderCategoriesLabel',
      desc: '',
      args: [],
    );
  }

  /// `Servizi`
  String get reorderServicesLabel {
    return Intl.message(
      'Servizi',
      name: 'reorderServicesLabel',
      desc: '',
      args: [],
    );
  }

  /// `Le categorie senza servizi non sono riordinabili e restano in coda.`
  String get emptyCategoriesNotReorderableNote {
    return Intl.message(
      'Le categorie senza servizi non sono riordinabili e restano in coda.',
      name: 'emptyCategoriesNotReorderableNote',
      desc: '',
      args: [],
    );
  }

  /// `Trattamenti Corpo`
  String get serviceSeedCategoryBodyName {
    return Intl.message(
      'Trattamenti Corpo',
      name: 'serviceSeedCategoryBodyName',
      desc: '',
      args: [],
    );
  }

  /// `Servizi dedicati al benessere del corpo`
  String get serviceSeedCategoryBodyDescription {
    return Intl.message(
      'Servizi dedicati al benessere del corpo',
      name: 'serviceSeedCategoryBodyDescription',
      desc: '',
      args: [],
    );
  }

  /// `Trattamenti Sportivi`
  String get serviceSeedCategorySportsName {
    return Intl.message(
      'Trattamenti Sportivi',
      name: 'serviceSeedCategorySportsName',
      desc: '',
      args: [],
    );
  }

  /// `Percorsi pensati per atleti e persone attive`
  String get serviceSeedCategorySportsDescription {
    return Intl.message(
      'Percorsi pensati per atleti e persone attive',
      name: 'serviceSeedCategorySportsDescription',
      desc: '',
      args: [],
    );
  }

  /// `Trattamenti Viso`
  String get serviceSeedCategoryFaceName {
    return Intl.message(
      'Trattamenti Viso',
      name: 'serviceSeedCategoryFaceName',
      desc: '',
      args: [],
    );
  }

  /// `Cura estetica e rigenerante per il viso`
  String get serviceSeedCategoryFaceDescription {
    return Intl.message(
      'Cura estetica e rigenerante per il viso',
      name: 'serviceSeedCategoryFaceDescription',
      desc: '',
      args: [],
    );
  }

  /// `Massaggio Relax`
  String get serviceSeedServiceRelaxName {
    return Intl.message(
      'Massaggio Relax',
      name: 'serviceSeedServiceRelaxName',
      desc: '',
      args: [],
    );
  }

  /// `Trattamento rilassante da 30 minuti`
  String get serviceSeedServiceRelaxDescription {
    return Intl.message(
      'Trattamento rilassante da 30 minuti',
      name: 'serviceSeedServiceRelaxDescription',
      desc: '',
      args: [],
    );
  }

  /// `Massaggio Sportivo`
  String get serviceSeedServiceSportName {
    return Intl.message(
      'Massaggio Sportivo',
      name: 'serviceSeedServiceSportName',
      desc: '',
      args: [],
    );
  }

  /// `Trattamento decontratturante intensivo`
  String get serviceSeedServiceSportDescription {
    return Intl.message(
      'Trattamento decontratturante intensivo',
      name: 'serviceSeedServiceSportDescription',
      desc: '',
      args: [],
    );
  }

  /// `Trattamento Viso`
  String get serviceSeedServiceFaceName {
    return Intl.message(
      'Trattamento Viso',
      name: 'serviceSeedServiceFaceName',
      desc: '',
      args: [],
    );
  }

  /// `Pulizia e trattamento illuminante`
  String get serviceSeedServiceFaceDescription {
    return Intl.message(
      'Pulizia e trattamento illuminante',
      name: 'serviceSeedServiceFaceDescription',
      desc: '',
      args: [],
    );
  }

  /// `Copia`
  String get serviceDuplicateCopyWord {
    return Intl.message(
      'Copia',
      name: 'serviceDuplicateCopyWord',
      desc: '',
      args: [],
    );
  }

  /// `Confermi lo spostamento?`
  String get moveAppointmentConfirmTitle {
    return Intl.message(
      'Confermi lo spostamento?',
      name: 'moveAppointmentConfirmTitle',
      desc: '',
      args: [],
    );
  }

  /// `L'appuntamento verrà spostato alle {newTime} per {staffName}.`
  String moveAppointmentConfirmMessage(String newTime, String staffName) {
    return Intl.message(
      'L\'appuntamento verrà spostato alle $newTime per $staffName.',
      name: 'moveAppointmentConfirmMessage',
      desc: '',
      args: [newTime, staffName],
    );
  }

  /// `Modifiche non salvate`
  String get discardChangesTitle {
    return Intl.message(
      'Modifiche non salvate',
      name: 'discardChangesTitle',
      desc: '',
      args: [],
    );
  }

  /// `Hai delle modifiche non salvate. Vuoi scartarle?`
  String get discardChangesMessage {
    return Intl.message(
      'Hai delle modifiche non salvate. Vuoi scartarle?',
      name: 'discardChangesMessage',
      desc: '',
      args: [],
    );
  }

  /// `Annulla`
  String get actionDiscard {
    return Intl.message('Annulla', name: 'actionDiscard', desc: '', args: []);
  }

  /// `Continua a modificare`
  String get actionKeepEditing {
    return Intl.message(
      'Continua a modificare',
      name: 'actionKeepEditing',
      desc: '',
      args: [],
    );
  }

  /// `Eliminare il cliente?`
  String get deleteClientConfirmTitle {
    return Intl.message(
      'Eliminare il cliente?',
      name: 'deleteClientConfirmTitle',
      desc: '',
      args: [],
    );
  }

  /// `Il cliente verrà eliminato definitivamente. Questa azione non può essere annullata.`
  String get deleteClientConfirmMessage {
    return Intl.message(
      'Il cliente verrà eliminato definitivamente. Questa azione non può essere annullata.',
      name: 'deleteClientConfirmMessage',
      desc: '',
      args: [],
    );
  }

  /// `Nome (A-Z)`
  String get sortByNameAsc {
    return Intl.message(
      'Nome (A-Z)',
      name: 'sortByNameAsc',
      desc: '',
      args: [],
    );
  }

  /// `Nome (Z-A)`
  String get sortByNameDesc {
    return Intl.message(
      'Nome (Z-A)',
      name: 'sortByNameDesc',
      desc: '',
      args: [],
    );
  }

  /// `Cognome (A-Z)`
  String get sortByLastNameAsc {
    return Intl.message(
      'Cognome (A-Z)',
      name: 'sortByLastNameAsc',
      desc: '',
      args: [],
    );
  }

  /// `Cognome (Z-A)`
  String get sortByLastNameDesc {
    return Intl.message(
      'Cognome (Z-A)',
      name: 'sortByLastNameDesc',
      desc: '',
      args: [],
    );
  }

  /// `Ultima visita (recenti)`
  String get sortByLastVisitDesc {
    return Intl.message(
      'Ultima visita (recenti)',
      name: 'sortByLastVisitDesc',
      desc: '',
      args: [],
    );
  }

  /// `Ultima visita (meno recenti)`
  String get sortByLastVisitAsc {
    return Intl.message(
      'Ultima visita (meno recenti)',
      name: 'sortByLastVisitAsc',
      desc: '',
      args: [],
    );
  }

  /// `Data creazione (nuovi)`
  String get sortByCreatedAtDesc {
    return Intl.message(
      'Data creazione (nuovi)',
      name: 'sortByCreatedAtDesc',
      desc: '',
      args: [],
    );
  }

  /// `Data creazione (vecchi)`
  String get sortByCreatedAtAsc {
    return Intl.message(
      'Data creazione (vecchi)',
      name: 'sortByCreatedAtAsc',
      desc: '',
      args: [],
    );
  }

  /// `Appuntamenti di {clientName}`
  String clientAppointmentsTitle(String clientName) {
    return Intl.message(
      'Appuntamenti di $clientName',
      name: 'clientAppointmentsTitle',
      desc: '',
      args: [clientName],
    );
  }

  /// `Prossimi`
  String get clientAppointmentsUpcoming {
    return Intl.message(
      'Prossimi',
      name: 'clientAppointmentsUpcoming',
      desc: '',
      args: [],
    );
  }

  /// `Passati`
  String get clientAppointmentsPast {
    return Intl.message(
      'Passati',
      name: 'clientAppointmentsPast',
      desc: '',
      args: [],
    );
  }

  /// `Nessun appuntamento`
  String get clientAppointmentsEmpty {
    return Intl.message(
      'Nessun appuntamento',
      name: 'clientAppointmentsEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Filtra team`
  String get staffFilterTooltip {
    return Intl.message(
      'Filtra team',
      name: 'staffFilterTooltip',
      desc: '',
      args: [],
    );
  }

  /// `Filtra team`
  String get staffFilterTitle {
    return Intl.message(
      'Filtra team',
      name: 'staffFilterTitle',
      desc: '',
      args: [],
    );
  }

  /// `Tutto il team`
  String get staffFilterAllTeam {
    return Intl.message(
      'Tutto il team',
      name: 'staffFilterAllTeam',
      desc: '',
      args: [],
    );
  }

  /// `Team di turno`
  String get staffFilterOnDuty {
    return Intl.message(
      'Team di turno',
      name: 'staffFilterOnDuty',
      desc: '',
      args: [],
    );
  }

  /// `Nessun membro del team di turno oggi`
  String get agendaNoOnDutyTeamTitle {
    return Intl.message(
      'Nessun membro del team di turno oggi',
      name: 'agendaNoOnDutyTeamTitle',
      desc: '',
      args: [],
    );
  }

  /// `Nessun membro del team selezionato`
  String get agendaNoSelectedTeamTitle {
    return Intl.message(
      'Nessun membro del team selezionato',
      name: 'agendaNoSelectedTeamTitle',
      desc: '',
      args: [],
    );
  }

  /// `Visualizza tutto il team`
  String get agendaShowAllTeamButton {
    return Intl.message(
      'Visualizza tutto il team',
      name: 'agendaShowAllTeamButton',
      desc: '',
      args: [],
    );
  }

  /// `Seleziona membri del team`
  String get staffFilterSelectMembers {
    return Intl.message(
      'Seleziona membri del team',
      name: 'staffFilterSelectMembers',
      desc: '',
      args: [],
    );
  }

  /// `Nuovo blocco`
  String get blockDialogTitleNew {
    return Intl.message(
      'Nuovo blocco',
      name: 'blockDialogTitleNew',
      desc: '',
      args: [],
    );
  }

  /// `Modifica blocco`
  String get blockDialogTitleEdit {
    return Intl.message(
      'Modifica blocco',
      name: 'blockDialogTitleEdit',
      desc: '',
      args: [],
    );
  }

  /// `Giornata intera`
  String get blockAllDay {
    return Intl.message(
      'Giornata intera',
      name: 'blockAllDay',
      desc: '',
      args: [],
    );
  }

  /// `Orario inizio`
  String get blockStartTime {
    return Intl.message(
      'Orario inizio',
      name: 'blockStartTime',
      desc: '',
      args: [],
    );
  }

  /// `Orario fine`
  String get blockEndTime {
    return Intl.message(
      'Orario fine',
      name: 'blockEndTime',
      desc: '',
      args: [],
    );
  }

  /// `Seleziona team`
  String get blockSelectStaff {
    return Intl.message(
      'Seleziona team',
      name: 'blockSelectStaff',
      desc: '',
      args: [],
    );
  }

  /// `Seleziona almeno un team`
  String get blockSelectStaffError {
    return Intl.message(
      'Seleziona almeno un team',
      name: 'blockSelectStaffError',
      desc: '',
      args: [],
    );
  }

  /// `L'ora di fine deve essere successiva all'ora di inizio`
  String get blockTimeError {
    return Intl.message(
      'L\'ora di fine deve essere successiva all\'ora di inizio',
      name: 'blockTimeError',
      desc: '',
      args: [],
    );
  }

  /// `Motivo (opzionale)`
  String get blockReason {
    return Intl.message(
      'Motivo (opzionale)',
      name: 'blockReason',
      desc: '',
      args: [],
    );
  }

  /// `Es. Riunione, Pausa, ecc.`
  String get blockReasonHint {
    return Intl.message(
      'Es. Riunione, Pausa, ecc.',
      name: 'blockReasonHint',
      desc: '',
      args: [],
    );
  }

  /// `Ordina per`
  String get sortByTitle {
    return Intl.message('Ordina per', name: 'sortByTitle', desc: '', args: []);
  }

  /// `Seleziona team`
  String get selectStaffTitle {
    return Intl.message(
      'Seleziona team',
      name: 'selectStaffTitle',
      desc: '',
      args: [],
    );
  }

  /// `Aggiungi un cliente all'appuntamento`
  String get addClientToAppointment {
    return Intl.message(
      'Aggiungi un cliente all\'appuntamento',
      name: 'addClientToAppointment',
      desc: '',
      args: [],
    );
  }

  /// `Lascia il campo vuoto se non vuoi associare un cliente all'appuntamento`
  String get clientOptionalHint {
    return Intl.message(
      'Lascia il campo vuoto se non vuoi associare un cliente all\'appuntamento',
      name: 'clientOptionalHint',
      desc: '',
      args: [],
    );
  }

  /// `Seleziona cliente`
  String get selectClientTitle {
    return Intl.message(
      'Seleziona cliente',
      name: 'selectClientTitle',
      desc: '',
      args: [],
    );
  }

  /// `Rimuovi cliente`
  String get removeClient {
    return Intl.message(
      'Rimuovi cliente',
      name: 'removeClient',
      desc: '',
      args: [],
    );
  }

  /// `Cerca cliente...`
  String get searchClientPlaceholder {
    return Intl.message(
      'Cerca cliente...',
      name: 'searchClientPlaceholder',
      desc: '',
      args: [],
    );
  }

  /// `Crea nuovo cliente`
  String get createNewClient {
    return Intl.message(
      'Crea nuovo cliente',
      name: 'createNewClient',
      desc: '',
      args: [],
    );
  }

  /// `Nessun cliente per l'appuntamento`
  String get noClientForAppointment {
    return Intl.message(
      'Nessun cliente per l\'appuntamento',
      name: 'noClientForAppointment',
      desc: '',
      args: [],
    );
  }

  /// `Servizi`
  String get formServices {
    return Intl.message('Servizi', name: 'formServices', desc: '', args: []);
  }

  /// `{count, plural, =1{1 servizio selezionato} other{{count} servizi selezionati}}`
  String servicesSelectedCount(int count) {
    return Intl.plural(
      count,
      one: '1 servizio selezionato',
      other: '$count servizi selezionati',
      name: 'servicesSelectedCount',
      desc: '',
      args: [count],
    );
  }

  /// `Aggiungi un servizio`
  String get addService {
    return Intl.message(
      'Aggiungi un servizio',
      name: 'addService',
      desc: '',
      args: [],
    );
  }

  /// `Seleziona un servizio`
  String get selectService {
    return Intl.message(
      'Seleziona un servizio',
      name: 'selectService',
      desc: '',
      args: [],
    );
  }

  /// `Nessun servizio aggiunto`
  String get noServicesAdded {
    return Intl.message(
      'Nessun servizio aggiunto',
      name: 'noServicesAdded',
      desc: '',
      args: [],
    );
  }

  /// `Aggiungi almeno un servizio`
  String get atLeastOneServiceRequired {
    return Intl.message(
      'Aggiungi almeno un servizio',
      name: 'atLeastOneServiceRequired',
      desc: '',
      args: [],
    );
  }

  /// `Note sull'appuntamento...`
  String get notesPlaceholder {
    return Intl.message(
      'Note sull\'appuntamento...',
      name: 'notesPlaceholder',
      desc: '',
      args: [],
    );
  }

  /// `Nessun team disponibile`
  String get noStaffAvailable {
    return Intl.message(
      'Nessun team disponibile',
      name: 'noStaffAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Orario settimanale`
  String get weeklyScheduleTitle {
    return Intl.message(
      'Orario settimanale',
      name: 'weeklyScheduleTitle',
      desc: '',
      args: [],
    );
  }

  /// `{hours} ore totale`
  String weeklyScheduleTotalHours(int hours) {
    return Intl.message(
      '$hours ore totale',
      name: 'weeklyScheduleTotalHours',
      desc: '',
      args: [hours],
    );
  }

  /// `Non lavora`
  String get weeklyScheduleNotWorking {
    return Intl.message(
      'Non lavora',
      name: 'weeklyScheduleNotWorking',
      desc: '',
      args: [],
    );
  }

  /// `-`
  String get weeklyScheduleFor {
    return Intl.message('-', name: 'weeklyScheduleFor', desc: '', args: []);
  }

  /// `Aggiungi turno`
  String get weeklyScheduleAddShift {
    return Intl.message(
      'Aggiungi turno',
      name: 'weeklyScheduleAddShift',
      desc: '',
      args: [],
    );
  }

  /// `Rimuovi turno`
  String get weeklyScheduleRemoveShift {
    return Intl.message(
      'Rimuovi turno',
      name: 'weeklyScheduleRemoveShift',
      desc: '',
      args: [],
    );
  }

  /// `lunedì`
  String get dayMondayFull {
    return Intl.message('lunedì', name: 'dayMondayFull', desc: '', args: []);
  }

  /// `martedì`
  String get dayTuesdayFull {
    return Intl.message('martedì', name: 'dayTuesdayFull', desc: '', args: []);
  }

  /// `mercoledì`
  String get dayWednesdayFull {
    return Intl.message(
      'mercoledì',
      name: 'dayWednesdayFull',
      desc: '',
      args: [],
    );
  }

  /// `giovedì`
  String get dayThursdayFull {
    return Intl.message('giovedì', name: 'dayThursdayFull', desc: '', args: []);
  }

  /// `venerdì`
  String get dayFridayFull {
    return Intl.message('venerdì', name: 'dayFridayFull', desc: '', args: []);
  }

  /// `sabato`
  String get daySaturdayFull {
    return Intl.message('sabato', name: 'daySaturdayFull', desc: '', args: []);
  }

  /// `domenica`
  String get daySundayFull {
    return Intl.message('domenica', name: 'daySundayFull', desc: '', args: []);
  }

  /// `Nuova eccezione`
  String get exceptionDialogTitleNew {
    return Intl.message(
      'Nuova eccezione',
      name: 'exceptionDialogTitleNew',
      desc: '',
      args: [],
    );
  }

  /// `Modifica eccezione`
  String get exceptionDialogTitleEdit {
    return Intl.message(
      'Modifica eccezione',
      name: 'exceptionDialogTitleEdit',
      desc: '',
      args: [],
    );
  }

  /// `Tipo eccezione`
  String get exceptionType {
    return Intl.message(
      'Tipo eccezione',
      name: 'exceptionType',
      desc: '',
      args: [],
    );
  }

  /// `Non disponibile`
  String get exceptionTypeUnavailable {
    return Intl.message(
      'Non disponibile',
      name: 'exceptionTypeUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `Disponibile`
  String get exceptionTypeAvailable {
    return Intl.message(
      'Disponibile',
      name: 'exceptionTypeAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Giornata intera`
  String get exceptionAllDay {
    return Intl.message(
      'Giornata intera',
      name: 'exceptionAllDay',
      desc: '',
      args: [],
    );
  }

  /// `Orario inizio`
  String get exceptionStartTime {
    return Intl.message(
      'Orario inizio',
      name: 'exceptionStartTime',
      desc: '',
      args: [],
    );
  }

  /// `Orario fine`
  String get exceptionEndTime {
    return Intl.message(
      'Orario fine',
      name: 'exceptionEndTime',
      desc: '',
      args: [],
    );
  }

  /// `Motivo (opzionale)`
  String get exceptionReason {
    return Intl.message(
      'Motivo (opzionale)',
      name: 'exceptionReason',
      desc: '',
      args: [],
    );
  }

  /// `Ferie`
  String get exceptionReasonVacation {
    return Intl.message(
      'Ferie',
      name: 'exceptionReasonVacation',
      desc: '',
      args: [],
    );
  }

  /// `Turno extra`
  String get exceptionReasonExtraShift {
    return Intl.message(
      'Turno extra',
      name: 'exceptionReasonExtraShift',
      desc: '',
      args: [],
    );
  }

  /// `Visita medica`
  String get exceptionReasonMedicalVisit {
    return Intl.message(
      'Visita medica',
      name: 'exceptionReasonMedicalVisit',
      desc: '',
      args: [],
    );
  }

  /// `Es. Ferie, Visita medica, Turno extra...`
  String get exceptionReasonHint {
    return Intl.message(
      'Es. Ferie, Visita medica, Turno extra...',
      name: 'exceptionReasonHint',
      desc: '',
      args: [],
    );
  }

  /// `L'ora di fine deve essere successiva all'ora di inizio`
  String get exceptionTimeError {
    return Intl.message(
      'L\'ora di fine deve essere successiva all\'ora di inizio',
      name: 'exceptionTimeError',
      desc: '',
      args: [],
    );
  }

  /// `Non puoi aggiungere una non disponibilità in un giorno senza disponibilità base.`
  String get exceptionUnavailableNoBase {
    return Intl.message(
      'Non puoi aggiungere una non disponibilità in un giorno senza disponibilità base.',
      name: 'exceptionUnavailableNoBase',
      desc: '',
      args: [],
    );
  }

  /// `La non disponibilità deve sovrapporsi alla disponibilità base.`
  String get exceptionUnavailableNoOverlap {
    return Intl.message(
      'La non disponibilità deve sovrapporsi alla disponibilità base.',
      name: 'exceptionUnavailableNoOverlap',
      desc: '',
      args: [],
    );
  }

  /// `La disponibilità extra deve aggiungere ore rispetto alla disponibilità base.`
  String get exceptionAvailableNoEffect {
    return Intl.message(
      'La disponibilità extra deve aggiungere ore rispetto alla disponibilità base.',
      name: 'exceptionAvailableNoEffect',
      desc: '',
      args: [],
    );
  }

  /// `Alcuni giorni non sono stati salvati: {dates}.`
  String exceptionPartialSaveInfo(Object dates) {
    return Intl.message(
      'Alcuni giorni non sono stati salvati: $dates.',
      name: 'exceptionPartialSaveInfo',
      desc: '',
      args: [dates],
    );
  }

  /// `Alcuni giorni non sono stati salvati: {details}.`
  String exceptionPartialSaveInfoDetailed(Object details) {
    return Intl.message(
      'Alcuni giorni non sono stati salvati: $details.',
      name: 'exceptionPartialSaveInfoDetailed',
      desc: '',
      args: [details],
    );
  }

  /// `Eccezioni non salvate`
  String get exceptionPartialSaveTitle {
    return Intl.message(
      'Eccezioni non salvate',
      name: 'exceptionPartialSaveTitle',
      desc: '',
      args: [],
    );
  }

  /// `I giorni sotto non erano congruenti e non sono stati salvati:`
  String get exceptionPartialSaveMessage {
    return Intl.message(
      'I giorni sotto non erano congruenti e non sono stati salvati:',
      name: 'exceptionPartialSaveMessage',
      desc: '',
      args: [],
    );
  }

  /// `Eliminare l'eccezione?`
  String get exceptionDeleteTitle {
    return Intl.message(
      'Eliminare l\'eccezione?',
      name: 'exceptionDeleteTitle',
      desc: '',
      args: [],
    );
  }

  /// `L'eccezione verrà eliminata definitivamente.`
  String get exceptionDeleteMessage {
    return Intl.message(
      'L\'eccezione verrà eliminata definitivamente.',
      name: 'exceptionDeleteMessage',
      desc: '',
      args: [],
    );
  }

  /// `Seleziona orario`
  String get exceptionSelectTime {
    return Intl.message(
      'Seleziona orario',
      name: 'exceptionSelectTime',
      desc: '',
      args: [],
    );
  }

  /// `Eccezioni`
  String get exceptionsTitle {
    return Intl.message(
      'Eccezioni',
      name: 'exceptionsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Nessuna eccezione configurata`
  String get exceptionsEmpty {
    return Intl.message(
      'Nessuna eccezione configurata',
      name: 'exceptionsEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Aggiungi eccezione`
  String get exceptionsAdd {
    return Intl.message(
      'Aggiungi eccezione',
      name: 'exceptionsAdd',
      desc: '',
      args: [],
    );
  }

  /// `Periodo`
  String get exceptionPeriodMode {
    return Intl.message(
      'Periodo',
      name: 'exceptionPeriodMode',
      desc: '',
      args: [],
    );
  }

  /// `Giorno singolo`
  String get exceptionPeriodSingle {
    return Intl.message(
      'Giorno singolo',
      name: 'exceptionPeriodSingle',
      desc: '',
      args: [],
    );
  }

  /// `Da - A`
  String get exceptionPeriodRange {
    return Intl.message(
      'Da - A',
      name: 'exceptionPeriodRange',
      desc: '',
      args: [],
    );
  }

  /// `Durata`
  String get exceptionPeriodDuration {
    return Intl.message(
      'Durata',
      name: 'exceptionPeriodDuration',
      desc: '',
      args: [],
    );
  }

  /// `Data inizio`
  String get exceptionDateFrom {
    return Intl.message(
      'Data inizio',
      name: 'exceptionDateFrom',
      desc: '',
      args: [],
    );
  }

  /// `Data fine`
  String get exceptionDateTo {
    return Intl.message(
      'Data fine',
      name: 'exceptionDateTo',
      desc: '',
      args: [],
    );
  }

  /// `Durata (giorni)`
  String get exceptionDuration {
    return Intl.message(
      'Durata (giorni)',
      name: 'exceptionDuration',
      desc: '',
      args: [],
    );
  }

  /// `{count} {count, plural, =1{giorno} other{giorni}}`
  String exceptionDurationDays(int count) {
    return Intl.message(
      '$count ${Intl.plural(count, one: 'giorno', other: 'giorni')}',
      name: 'exceptionDurationDays',
      desc: '',
      args: [count],
    );
  }

  /// `Elimina solo questo turno`
  String get shiftDeleteThisOnly {
    return Intl.message(
      'Elimina solo questo turno',
      name: 'shiftDeleteThisOnly',
      desc: '',
      args: [],
    );
  }

  /// `Elimina solo la fascia oraria di {date}`
  String shiftDeleteThisOnlyDesc(String date) {
    return Intl.message(
      'Elimina solo la fascia oraria di $date',
      name: 'shiftDeleteThisOnlyDesc',
      desc: '',
      args: [date],
    );
  }

  /// `Elimina tutti questi turni`
  String get shiftDeleteAll {
    return Intl.message(
      'Elimina tutti questi turni',
      name: 'shiftDeleteAll',
      desc: '',
      args: [],
    );
  }

  /// `Elimina la fascia oraria settimanale di ogni {dayName}`
  String shiftDeleteAllDesc(String dayName) {
    return Intl.message(
      'Elimina la fascia oraria settimanale di ogni $dayName',
      name: 'shiftDeleteAllDesc',
      desc: '',
      args: [dayName],
    );
  }

  /// `Modifica solo questo turno`
  String get shiftEditThisOnly {
    return Intl.message(
      'Modifica solo questo turno',
      name: 'shiftEditThisOnly',
      desc: '',
      args: [],
    );
  }

  /// `Modifica solo la fascia oraria di {date}`
  String shiftEditThisOnlyDesc(String date) {
    return Intl.message(
      'Modifica solo la fascia oraria di $date',
      name: 'shiftEditThisOnlyDesc',
      desc: '',
      args: [date],
    );
  }

  /// `Modifica tutti questi turni`
  String get shiftEditAll {
    return Intl.message(
      'Modifica tutti questi turni',
      name: 'shiftEditAll',
      desc: '',
      args: [],
    );
  }

  /// `Modifica la fascia oraria settimanale di ogni {dayName}`
  String shiftEditAllDesc(String dayName) {
    return Intl.message(
      'Modifica la fascia oraria settimanale di ogni $dayName',
      name: 'shiftEditAllDesc',
      desc: '',
      args: [dayName],
    );
  }

  /// `Modifica turno`
  String get shiftEditTitle {
    return Intl.message(
      'Modifica turno',
      name: 'shiftEditTitle',
      desc: '',
      args: [],
    );
  }

  /// `Ora inizio`
  String get shiftStartTime {
    return Intl.message(
      'Ora inizio',
      name: 'shiftStartTime',
      desc: '',
      args: [],
    );
  }

  /// `Ora fine`
  String get shiftEndTime {
    return Intl.message('Ora fine', name: 'shiftEndTime', desc: '', args: []);
  }

  /// `Modifica eccezione`
  String get exceptionEditShift {
    return Intl.message(
      'Modifica eccezione',
      name: 'exceptionEditShift',
      desc: '',
      args: [],
    );
  }

  /// `Modifica gli orari di questa eccezione`
  String get exceptionEditShiftDesc {
    return Intl.message(
      'Modifica gli orari di questa eccezione',
      name: 'exceptionEditShiftDesc',
      desc: '',
      args: [],
    );
  }

  /// `Elimina eccezione`
  String get exceptionDeleteShift {
    return Intl.message(
      'Elimina eccezione',
      name: 'exceptionDeleteShift',
      desc: '',
      args: [],
    );
  }

  /// `Ripristina la disponibilità base`
  String get exceptionDeleteShiftDesc {
    return Intl.message(
      'Ripristina la disponibilità base',
      name: 'exceptionDeleteShiftDesc',
      desc: '',
      args: [],
    );
  }

  /// `Il cliente non può essere modificato per questo appuntamento`
  String get clientLockedHint {
    return Intl.message(
      'Il cliente non può essere modificato per questo appuntamento',
      name: 'clientLockedHint',
      desc: '',
      args: [],
    );
  }

  /// `Applicare il cliente a tutta la prenotazione?`
  String get applyClientToAllAppointmentsTitle {
    return Intl.message(
      'Applicare il cliente a tutta la prenotazione?',
      name: 'applyClientToAllAppointmentsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Il cliente verrà associato anche agli altri {count} appuntamenti di questa prenotazione.`
  String applyClientToAllAppointmentsMessage(int count) {
    return Intl.message(
      'Il cliente verrà associato anche agli altri $count appuntamenti di questa prenotazione.',
      name: 'applyClientToAllAppointmentsMessage',
      desc: '',
      args: [count],
    );
  }

  /// `Operatori`
  String get operatorsTitle {
    return Intl.message(
      'Operatori',
      name: 'operatorsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Gestisci chi può accedere al gestionale`
  String get operatorsSubtitle {
    return Intl.message(
      'Gestisci chi può accedere al gestionale',
      name: 'operatorsSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Nessun operatore configurato`
  String get operatorsEmpty {
    return Intl.message(
      'Nessun operatore configurato',
      name: 'operatorsEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Invita operatore`
  String get operatorsInviteTitle {
    return Intl.message(
      'Invita operatore',
      name: 'operatorsInviteTitle',
      desc: '',
      args: [],
    );
  }

  /// `Invia un invito via email`
  String get operatorsInviteSubtitle {
    return Intl.message(
      'Invia un invito via email',
      name: 'operatorsInviteSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get operatorsInviteEmail {
    return Intl.message(
      'Email',
      name: 'operatorsInviteEmail',
      desc: '',
      args: [],
    );
  }

  /// `Ruolo`
  String get operatorsInviteRole {
    return Intl.message(
      'Ruolo',
      name: 'operatorsInviteRole',
      desc: '',
      args: [],
    );
  }

  /// `Invia invito`
  String get operatorsInviteSend {
    return Intl.message(
      'Invia invito',
      name: 'operatorsInviteSend',
      desc: '',
      args: [],
    );
  }

  /// `Invito inviato a {email}`
  String operatorsInviteSuccess(String email) {
    return Intl.message(
      'Invito inviato a $email',
      name: 'operatorsInviteSuccess',
      desc: '',
      args: [email],
    );
  }

  /// `Link di invito copiato`
  String get operatorsInviteCopied {
    return Intl.message(
      'Link di invito copiato',
      name: 'operatorsInviteCopied',
      desc: '',
      args: [],
    );
  }

  /// `Inviti in attesa`
  String get operatorsPendingInvites {
    return Intl.message(
      'Inviti in attesa',
      name: 'operatorsPendingInvites',
      desc: '',
      args: [],
    );
  }

  /// `{count} inviti in attesa`
  String operatorsPendingInvitesCount(int count) {
    return Intl.message(
      '$count inviti in attesa',
      name: 'operatorsPendingInvitesCount',
      desc: '',
      args: [count],
    );
  }

  /// `Revoca invito`
  String get operatorsRevokeInvite {
    return Intl.message(
      'Revoca invito',
      name: 'operatorsRevokeInvite',
      desc: '',
      args: [],
    );
  }

  /// `Vuoi revocare l'invito per {email}?`
  String operatorsRevokeInviteConfirm(String email) {
    return Intl.message(
      'Vuoi revocare l\'invito per $email?',
      name: 'operatorsRevokeInviteConfirm',
      desc: '',
      args: [email],
    );
  }

  /// `Modifica ruolo`
  String get operatorsEditRole {
    return Intl.message(
      'Modifica ruolo',
      name: 'operatorsEditRole',
      desc: '',
      args: [],
    );
  }

  /// `Rimuovi operatore`
  String get operatorsRemove {
    return Intl.message(
      'Rimuovi operatore',
      name: 'operatorsRemove',
      desc: '',
      args: [],
    );
  }

  /// `Vuoi rimuovere {name} dal team?`
  String operatorsRemoveConfirm(String name) {
    return Intl.message(
      'Vuoi rimuovere $name dal team?',
      name: 'operatorsRemoveConfirm',
      desc: '',
      args: [name],
    );
  }

  /// `Operatore rimosso`
  String get operatorsRemoveSuccess {
    return Intl.message(
      'Operatore rimosso',
      name: 'operatorsRemoveSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Proprietario`
  String get operatorsRoleOwner {
    return Intl.message(
      'Proprietario',
      name: 'operatorsRoleOwner',
      desc: '',
      args: [],
    );
  }

  /// `Amministratore`
  String get operatorsRoleAdmin {
    return Intl.message(
      'Amministratore',
      name: 'operatorsRoleAdmin',
      desc: '',
      args: [],
    );
  }

  /// `Manager`
  String get operatorsRoleManager {
    return Intl.message(
      'Manager',
      name: 'operatorsRoleManager',
      desc: '',
      args: [],
    );
  }

  /// `Staff`
  String get operatorsRoleStaff {
    return Intl.message(
      'Staff',
      name: 'operatorsRoleStaff',
      desc: '',
      args: [],
    );
  }

  /// `Seleziona il livello di accesso`
  String get operatorsRoleDescription {
    return Intl.message(
      'Seleziona il livello di accesso',
      name: 'operatorsRoleDescription',
      desc: '',
      args: [],
    );
  }

  /// `Tu`
  String get operatorsYou {
    return Intl.message('Tu', name: 'operatorsYou', desc: '', args: []);
  }

  /// `Invitato da {name}`
  String operatorsInvitedBy(String name) {
    return Intl.message(
      'Invitato da $name',
      name: 'operatorsInvitedBy',
      desc: '',
      args: [name],
    );
  }

  /// `Scade il {date}`
  String operatorsExpires(String date) {
    return Intl.message(
      'Scade il $date',
      name: 'operatorsExpires',
      desc: '',
      args: [date],
    );
  }

  /// `Accedi al gestionale`
  String get authLoginSubtitle {
    return Intl.message(
      'Accedi al gestionale',
      name: 'authLoginSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get authEmail {
    return Intl.message('Email', name: 'authEmail', desc: '', args: []);
  }

  /// `Password`
  String get authPassword {
    return Intl.message('Password', name: 'authPassword', desc: '', args: []);
  }

  /// `Accedi`
  String get authLogin {
    return Intl.message('Accedi', name: 'authLogin', desc: '', args: []);
  }

  /// `Esci`
  String get authLogout {
    return Intl.message('Esci', name: 'authLogout', desc: '', args: []);
  }

  /// `Ricordami`
  String get authRememberMe {
    return Intl.message(
      'Ricordami',
      name: 'authRememberMe',
      desc: '',
      args: [],
    );
  }

  /// `Password dimenticata?`
  String get authForgotPassword {
    return Intl.message(
      'Password dimenticata?',
      name: 'authForgotPassword',
      desc: '',
      args: [],
    );
  }

  /// `Contatta l'amministratore di sistema per reimpostare la password.`
  String get authForgotPasswordInfo {
    return Intl.message(
      'Contatta l\'amministratore di sistema per reimpostare la password.',
      name: 'authForgotPasswordInfo',
      desc: '',
      args: [],
    );
  }

  /// `Campo obbligatorio`
  String get authRequiredField {
    return Intl.message(
      'Campo obbligatorio',
      name: 'authRequiredField',
      desc: '',
      args: [],
    );
  }

  /// `Email non valida`
  String get authInvalidEmail {
    return Intl.message(
      'Email non valida',
      name: 'authInvalidEmail',
      desc: '',
      args: [],
    );
  }

  /// `Password troppo corta`
  String get authPasswordTooShort {
    return Intl.message(
      'Password troppo corta',
      name: 'authPasswordTooShort',
      desc: '',
      args: [],
    );
  }

  /// `Credenziali non valide. Riprova.`
  String get authLoginFailed {
    return Intl.message(
      'Credenziali non valide. Riprova.',
      name: 'authLoginFailed',
      desc: '',
      args: [],
    );
  }

  /// `Accesso riservato agli operatori autorizzati`
  String get authLoginFooter {
    return Intl.message(
      'Accesso riservato agli operatori autorizzati',
      name: 'authLoginFooter',
      desc: '',
      args: [],
    );
  }

  /// `Nome`
  String get authFirstName {
    return Intl.message('Nome', name: 'authFirstName', desc: '', args: []);
  }

  /// `Cognome`
  String get authLastName {
    return Intl.message('Cognome', name: 'authLastName', desc: '', args: []);
  }

  /// `Telefono`
  String get authPhone {
    return Intl.message('Telefono', name: 'authPhone', desc: '', args: []);
  }

  /// `Cambia`
  String get switchBusiness {
    return Intl.message('Cambia', name: 'switchBusiness', desc: '', args: []);
  }

  /// `Profilo`
  String get profileTitle {
    return Intl.message('Profilo', name: 'profileTitle', desc: '', args: []);
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<L10n> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'it'),
      Locale.fromSubtags(languageCode: 'en'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<L10n> load(Locale locale) => L10n.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
