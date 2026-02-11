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

  /// `Altro`
  String get navMore {
    return Intl.message('Altro', name: 'navMore', desc: '', args: []);
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

  /// `Chiudi`
  String get actionClose {
    return Intl.message('Chiudi', name: 'actionClose', desc: '', args: []);
  }

  /// `Riprova`
  String get actionRetry {
    return Intl.message('Riprova', name: 'actionRetry', desc: '', args: []);
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

  /// `Servizi`
  String get servicesTabLabel {
    return Intl.message(
      'Servizi',
      name: 'servicesTabLabel',
      desc: '',
      args: [],
    );
  }

  /// `Pacchetti`
  String get servicePackagesTabLabel {
    return Intl.message(
      'Pacchetti',
      name: 'servicePackagesTabLabel',
      desc: '',
      args: [],
    );
  }

  /// `Pacchetti`
  String get servicePackagesTitle {
    return Intl.message(
      'Pacchetti',
      name: 'servicePackagesTitle',
      desc: '',
      args: [],
    );
  }

  /// `I più richiesti`
  String get popularServicesTitle {
    return Intl.message(
      'I più richiesti',
      name: 'popularServicesTitle',
      desc: '',
      args: [],
    );
  }

  /// `Nessun pacchetto disponibile`
  String get servicePackagesEmptyState {
    return Intl.message(
      'Nessun pacchetto disponibile',
      name: 'servicePackagesEmptyState',
      desc: '',
      args: [],
    );
  }

  /// `Nuovo pacchetto`
  String get servicePackageNewMenu {
    return Intl.message(
      'Nuovo pacchetto',
      name: 'servicePackageNewMenu',
      desc: '',
      args: [],
    );
  }

  /// `Nuovo pacchetto`
  String get servicePackageNewTitle {
    return Intl.message(
      'Nuovo pacchetto',
      name: 'servicePackageNewTitle',
      desc: '',
      args: [],
    );
  }

  /// `Modifica pacchetto`
  String get servicePackageEditTitle {
    return Intl.message(
      'Modifica pacchetto',
      name: 'servicePackageEditTitle',
      desc: '',
      args: [],
    );
  }

  /// `Nome pacchetto`
  String get servicePackageNameLabel {
    return Intl.message(
      'Nome pacchetto',
      name: 'servicePackageNameLabel',
      desc: '',
      args: [],
    );
  }

  /// `Descrizione`
  String get servicePackageDescriptionLabel {
    return Intl.message(
      'Descrizione',
      name: 'servicePackageDescriptionLabel',
      desc: '',
      args: [],
    );
  }

  /// `Prezzo pacchetto`
  String get servicePackageOverridePriceLabel {
    return Intl.message(
      'Prezzo pacchetto',
      name: 'servicePackageOverridePriceLabel',
      desc: '',
      args: [],
    );
  }

  /// `Durata pacchetto (min)`
  String get servicePackageOverrideDurationLabel {
    return Intl.message(
      'Durata pacchetto (min)',
      name: 'servicePackageOverrideDurationLabel',
      desc: '',
      args: [],
    );
  }

  /// `Pacchetto attivo`
  String get servicePackageActiveLabel {
    return Intl.message(
      'Pacchetto attivo',
      name: 'servicePackageActiveLabel',
      desc: '',
      args: [],
    );
  }

  /// `Servizi inclusi`
  String get servicePackageServicesLabel {
    return Intl.message(
      'Servizi inclusi',
      name: 'servicePackageServicesLabel',
      desc: '',
      args: [],
    );
  }

  /// `Ordine servizi`
  String get servicePackageOrderLabel {
    return Intl.message(
      'Ordine servizi',
      name: 'servicePackageOrderLabel',
      desc: '',
      args: [],
    );
  }

  /// `Nessun servizio selezionato`
  String get servicePackageNoServices {
    return Intl.message(
      'Nessun servizio selezionato',
      name: 'servicePackageNoServices',
      desc: '',
      args: [],
    );
  }

  /// `Seleziona almeno un servizio`
  String get servicePackageServicesRequired {
    return Intl.message(
      'Seleziona almeno un servizio',
      name: 'servicePackageServicesRequired',
      desc: '',
      args: [],
    );
  }

  /// `Pacchetto creato`
  String get servicePackageCreatedTitle {
    return Intl.message(
      'Pacchetto creato',
      name: 'servicePackageCreatedTitle',
      desc: '',
      args: [],
    );
  }

  /// `Il pacchetto è stato creato.`
  String get servicePackageCreatedMessage {
    return Intl.message(
      'Il pacchetto è stato creato.',
      name: 'servicePackageCreatedMessage',
      desc: '',
      args: [],
    );
  }

  /// `Pacchetto aggiornato`
  String get servicePackageUpdatedTitle {
    return Intl.message(
      'Pacchetto aggiornato',
      name: 'servicePackageUpdatedTitle',
      desc: '',
      args: [],
    );
  }

  /// `Il pacchetto è stato aggiornato.`
  String get servicePackageUpdatedMessage {
    return Intl.message(
      'Il pacchetto è stato aggiornato.',
      name: 'servicePackageUpdatedMessage',
      desc: '',
      args: [],
    );
  }

  /// `Errore nel salvataggio del pacchetto.`
  String get servicePackageSaveError {
    return Intl.message(
      'Errore nel salvataggio del pacchetto.',
      name: 'servicePackageSaveError',
      desc: '',
      args: [],
    );
  }

  /// `Eliminare il pacchetto?`
  String get servicePackageDeleteTitle {
    return Intl.message(
      'Eliminare il pacchetto?',
      name: 'servicePackageDeleteTitle',
      desc: '',
      args: [],
    );
  }

  /// `Questa azione non può essere annullata.`
  String get servicePackageDeleteMessage {
    return Intl.message(
      'Questa azione non può essere annullata.',
      name: 'servicePackageDeleteMessage',
      desc: '',
      args: [],
    );
  }

  /// `Pacchetto eliminato`
  String get servicePackageDeletedTitle {
    return Intl.message(
      'Pacchetto eliminato',
      name: 'servicePackageDeletedTitle',
      desc: '',
      args: [],
    );
  }

  /// `Il pacchetto è stato eliminato.`
  String get servicePackageDeletedMessage {
    return Intl.message(
      'Il pacchetto è stato eliminato.',
      name: 'servicePackageDeletedMessage',
      desc: '',
      args: [],
    );
  }

  /// `Errore durante l'eliminazione del pacchetto.`
  String get servicePackageDeleteError {
    return Intl.message(
      'Errore durante l\'eliminazione del pacchetto.',
      name: 'servicePackageDeleteError',
      desc: '',
      args: [],
    );
  }

  /// `Inattivo`
  String get servicePackageInactiveLabel {
    return Intl.message(
      'Inattivo',
      name: 'servicePackageInactiveLabel',
      desc: '',
      args: [],
    );
  }

  /// `Non valido`
  String get servicePackageBrokenLabel {
    return Intl.message(
      'Non valido',
      name: 'servicePackageBrokenLabel',
      desc: '',
      args: [],
    );
  }

  /// `servizi`
  String get servicesLabel {
    return Intl.message('servizi', name: 'servicesLabel', desc: '', args: []);
  }

  /// `min`
  String get minutesLabel {
    return Intl.message('min', name: 'minutesLabel', desc: '', args: []);
  }

  /// `Aggiungi pacchetto`
  String get addPackage {
    return Intl.message(
      'Aggiungi pacchetto',
      name: 'addPackage',
      desc: '',
      args: [],
    );
  }

  /// `Impossibile espandere il pacchetto selezionato.`
  String get servicePackageExpandError {
    return Intl.message(
      'Impossibile espandere il pacchetto selezionato.',
      name: 'servicePackageExpandError',
      desc: '',
      args: [],
    );
  }

  /// `Numero non valido`
  String get validationInvalidNumber {
    return Intl.message(
      'Numero non valido',
      name: 'validationInvalidNumber',
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

  /// `Nota sull'appuntamento`
  String get appointmentNoteLabel {
    return Intl.message(
      'Nota sull\'appuntamento',
      name: 'appointmentNoteLabel',
      desc: '',
      args: [],
    );
  }

  /// `Nota sul cliente`
  String get clientNoteLabel {
    return Intl.message(
      'Nota sul cliente',
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

  /// `Limiti prenotazione online`
  String get teamLocationBookingLimitsSection {
    return Intl.message(
      'Limiti prenotazione online',
      name: 'teamLocationBookingLimitsSection',
      desc: '',
      args: [],
    );
  }

  /// `Consenti ai clienti di scegliere l'operatore`
  String get teamLocationAllowCustomerChooseStaffLabel {
    return Intl.message(
      'Consenti ai clienti di scegliere l\'operatore',
      name: 'teamLocationAllowCustomerChooseStaffLabel',
      desc: '',
      args: [],
    );
  }

  /// `Se disattivato, il sistema assegna automaticamente l'operatore`
  String get teamLocationAllowCustomerChooseStaffHint {
    return Intl.message(
      'Se disattivato, il sistema assegna automaticamente l\'operatore',
      name: 'teamLocationAllowCustomerChooseStaffHint',
      desc: '',
      args: [],
    );
  }

  /// `Preavviso minimo prenotazione`
  String get teamLocationMinBookingNoticeLabel {
    return Intl.message(
      'Preavviso minimo prenotazione',
      name: 'teamLocationMinBookingNoticeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Quanto tempo prima devono prenotare i clienti`
  String get teamLocationMinBookingNoticeHint {
    return Intl.message(
      'Quanto tempo prima devono prenotare i clienti',
      name: 'teamLocationMinBookingNoticeHint',
      desc: '',
      args: [],
    );
  }

  /// `Prenotazione massima anticipata`
  String get teamLocationMaxBookingAdvanceLabel {
    return Intl.message(
      'Prenotazione massima anticipata',
      name: 'teamLocationMaxBookingAdvanceLabel',
      desc: '',
      args: [],
    );
  }

  /// `Fino a quanto tempo in anticipo possono prenotare`
  String get teamLocationMaxBookingAdvanceHint {
    return Intl.message(
      'Fino a quanto tempo in anticipo possono prenotare',
      name: 'teamLocationMaxBookingAdvanceHint',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, =1{1 ora} other{{count} ore}}`
  String teamLocationHours(int count) {
    return Intl.plural(
      count,
      one: '1 ora',
      other: '$count ore',
      name: 'teamLocationHours',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, =1{1 giorno} other{{count} giorni}}`
  String teamLocationDays(int count) {
    return Intl.plural(
      count,
      one: '1 giorno',
      other: '$count giorni',
      name: 'teamLocationDays',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, =1{1 minuto} other{{count} minuti}}`
  String teamLocationMinutes(int count) {
    return Intl.plural(
      count,
      one: '1 minuto',
      other: '$count minuti',
      name: 'teamLocationMinutes',
      desc: '',
      args: [count],
    );
  }

  /// `Fasce orarie intelligenti`
  String get teamLocationSmartSlotSection {
    return Intl.message(
      'Fasce orarie intelligenti',
      name: 'teamLocationSmartSlotSection',
      desc: '',
      args: [],
    );
  }

  /// `Configura come vengono mostrati gli orari disponibili ai clienti che prenotano online`
  String get teamLocationSmartSlotDescription {
    return Intl.message(
      'Configura come vengono mostrati gli orari disponibili ai clienti che prenotano online',
      name: 'teamLocationSmartSlotDescription',
      desc: '',
      args: [],
    );
  }

  /// `Intervallo tra gli orari`
  String get teamLocationSlotIntervalLabel {
    return Intl.message(
      'Intervallo tra gli orari',
      name: 'teamLocationSlotIntervalLabel',
      desc: '',
      args: [],
    );
  }

  /// `Ogni quanti minuti mostrare un orario disponibile`
  String get teamLocationSlotIntervalHint {
    return Intl.message(
      'Ogni quanti minuti mostrare un orario disponibile',
      name: 'teamLocationSlotIntervalHint',
      desc: '',
      args: [],
    );
  }

  /// `Modalità visualizzazione`
  String get teamLocationSlotDisplayModeLabel {
    return Intl.message(
      'Modalità visualizzazione',
      name: 'teamLocationSlotDisplayModeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Massima disponibilità`
  String get teamLocationSlotDisplayModeAll {
    return Intl.message(
      'Massima disponibilità',
      name: 'teamLocationSlotDisplayModeAll',
      desc: '',
      args: [],
    );
  }

  /// `Riduci spazi vuoti`
  String get teamLocationSlotDisplayModeMinGap {
    return Intl.message(
      'Riduci spazi vuoti',
      name: 'teamLocationSlotDisplayModeMinGap',
      desc: '',
      args: [],
    );
  }

  /// `Mostra tutti gli orari disponibili`
  String get teamLocationSlotDisplayModeAllHint {
    return Intl.message(
      'Mostra tutti gli orari disponibili',
      name: 'teamLocationSlotDisplayModeAllHint',
      desc: '',
      args: [],
    );
  }

  /// `Nasconde orari che creerebbero buchi troppo piccoli`
  String get teamLocationSlotDisplayModeMinGapHint {
    return Intl.message(
      'Nasconde orari che creerebbero buchi troppo piccoli',
      name: 'teamLocationSlotDisplayModeMinGapHint',
      desc: '',
      args: [],
    );
  }

  /// `Gap minimo accettabile`
  String get teamLocationMinGapLabel {
    return Intl.message(
      'Gap minimo accettabile',
      name: 'teamLocationMinGapLabel',
      desc: '',
      args: [],
    );
  }

  /// `Non mostrare orari che lasciano meno di questo tempo libero`
  String get teamLocationMinGapHint {
    return Intl.message(
      'Non mostrare orari che lasciano meno di questo tempo libero',
      name: 'teamLocationMinGapHint',
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

  /// `Sedi disponibili`
  String get serviceLocationsLabel {
    return Intl.message(
      'Sedi disponibili',
      name: 'serviceLocationsLabel',
      desc: '',
      args: [],
    );
  }

  /// `{count} di {total} sedi`
  String serviceLocationsCount(int count, int total) {
    return Intl.message(
      '$count di $total sedi',
      name: 'serviceLocationsCount',
      desc: '',
      args: [count, total],
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

  /// `Impossibile aggiungere il servizio: l'orario supera la mezzanotte. Modifica l'orario di inizio o l'operatore.`
  String get serviceStartsAfterMidnight {
    return Intl.message(
      'Impossibile aggiungere il servizio: l\'orario supera la mezzanotte. Modifica l\'orario di inizio o l\'operatore.',
      name: 'serviceStartsAfterMidnight',
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

  /// `Cerca servizio...`
  String get searchServices {
    return Intl.message(
      'Cerca servizio...',
      name: 'searchServices',
      desc: '',
      args: [],
    );
  }

  /// `Mostra tutti i servizi`
  String get showAllServices {
    return Intl.message(
      'Mostra tutti i servizi',
      name: 'showAllServices',
      desc: '',
      args: [],
    );
  }

  /// `Nessun servizio trovato`
  String get noServicesFound {
    return Intl.message(
      'Nessun servizio trovato',
      name: 'noServicesFound',
      desc: '',
      args: [],
    );
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

  /// `Il cliente verrà associato anche agli appuntamenti di questa prenotazione che sono stati assegnati ad altro operatore.`
  String get applyClientToAllAppointmentsMessage {
    return Intl.message(
      'Il cliente verrà associato anche agli appuntamenti di questa prenotazione che sono stati assegnati ad altro operatore.',
      name: 'applyClientToAllAppointmentsMessage',
      desc: '',
      args: [],
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

  /// `Permessi`
  String get permissionsTitle {
    return Intl.message(
      'Permessi',
      name: 'permissionsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Gestisci accessi e ruoli degli operatori`
  String get permissionsDescription {
    return Intl.message(
      'Gestisci accessi e ruoli degli operatori',
      name: 'permissionsDescription',
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

  /// `Esiste già un invito in attesa per questa email. Puoi reinviarlo dalla lista degli inviti pendenti.`
  String get operatorsInviteAlreadyPending {
    return Intl.message(
      'Esiste già un invito in attesa per questa email. Puoi reinviarlo dalla lista degli inviti pendenti.',
      name: 'operatorsInviteAlreadyPending',
      desc: '',
      args: [],
    );
  }

  /// `Questo utente ha già accesso al business.`
  String get operatorsInviteAlreadyHasAccess {
    return Intl.message(
      'Questo utente ha già accesso al business.',
      name: 'operatorsInviteAlreadyHasAccess',
      desc: '',
      args: [],
    );
  }

  /// `Invio email non disponibile in questo ambiente. Contatta il supporto.`
  String get operatorsInviteEmailUnavailable {
    return Intl.message(
      'Invio email non disponibile in questo ambiente. Contatta il supporto.',
      name: 'operatorsInviteEmailUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `Impossibile inviare l'email di invito. Riprova più tardi.`
  String get operatorsInviteEmailFailed {
    return Intl.message(
      'Impossibile inviare l\'email di invito. Riprova più tardi.',
      name: 'operatorsInviteEmailFailed',
      desc: '',
      args: [],
    );
  }

  /// `Impossibile inviare l'invito`
  String get operatorsInviteError {
    return Intl.message(
      'Impossibile inviare l\'invito',
      name: 'operatorsInviteError',
      desc: '',
      args: [],
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

  /// `Accetta invito`
  String get invitationAcceptTitle {
    return Intl.message(
      'Accetta invito',
      name: 'invitationAcceptTitle',
      desc: '',
      args: [],
    );
  }

  /// `Verifica invito in corso...`
  String get invitationAcceptLoading {
    return Intl.message(
      'Verifica invito in corso...',
      name: 'invitationAcceptLoading',
      desc: '',
      args: [],
    );
  }

  /// `Sei stato invitato a collaborare con {businessName} come {role}.`
  String invitationAcceptIntro(String businessName, String role) {
    return Intl.message(
      'Sei stato invitato a collaborare con $businessName come $role.',
      name: 'invitationAcceptIntro',
      desc: '',
      args: [businessName, role],
    );
  }

  /// `Accedi con l'email invitata per continuare.`
  String get invitationAcceptLoginRequired {
    return Intl.message(
      'Accedi con l\'email invitata per continuare.',
      name: 'invitationAcceptLoginRequired',
      desc: '',
      args: [],
    );
  }

  /// `Accetta per continuare`
  String get invitationAcceptLoginAction {
    return Intl.message(
      'Accetta per continuare',
      name: 'invitationAcceptLoginAction',
      desc: '',
      args: [],
    );
  }

  /// `Accetta e accedi`
  String get invitationAcceptAndLoginAction {
    return Intl.message(
      'Accetta e accedi',
      name: 'invitationAcceptAndLoginAction',
      desc: '',
      args: [],
    );
  }

  /// `Hai già un account? Accedi per accettare l'invito.`
  String get invitationAcceptHintExistingAccount {
    return Intl.message(
      'Hai già un account? Accedi per accettare l\'invito.',
      name: 'invitationAcceptHintExistingAccount',
      desc: '',
      args: [],
    );
  }

  /// `Non hai un account? Registrati prima.`
  String get invitationAcceptHintNoAccount {
    return Intl.message(
      'Non hai un account? Registrati prima.',
      name: 'invitationAcceptHintNoAccount',
      desc: '',
      args: [],
    );
  }

  /// `Registrati per accettare`
  String get invitationRegisterAction {
    return Intl.message(
      'Registrati per accettare',
      name: 'invitationRegisterAction',
      desc: '',
      args: [],
    );
  }

  /// `Registrati per accettare l'invito`
  String get invitationRegisterTitle {
    return Intl.message(
      'Registrati per accettare l\'invito',
      name: 'invitationRegisterTitle',
      desc: '',
      args: [],
    );
  }

  /// `Registrazione...`
  String get invitationRegisterInProgress {
    return Intl.message(
      'Registrazione...',
      name: 'invitationRegisterInProgress',
      desc: '',
      args: [],
    );
  }

  /// `Conferma password`
  String get invitationRegisterPasswordConfirm {
    return Intl.message(
      'Conferma password',
      name: 'invitationRegisterPasswordConfirm',
      desc: '',
      args: [],
    );
  }

  /// `La password deve avere almeno 8 caratteri.`
  String get invitationRegisterPasswordTooShort {
    return Intl.message(
      'La password deve avere almeno 8 caratteri.',
      name: 'invitationRegisterPasswordTooShort',
      desc: '',
      args: [],
    );
  }

  /// `La password deve contenere almeno una maiuscola, una minuscola e un numero.`
  String get invitationRegisterPasswordWeak {
    return Intl.message(
      'La password deve contenere almeno una maiuscola, una minuscola e un numero.',
      name: 'invitationRegisterPasswordWeak',
      desc: '',
      args: [],
    );
  }

  /// `Le password non coincidono.`
  String get invitationRegisterPasswordMismatch {
    return Intl.message(
      'Le password non coincidono.',
      name: 'invitationRegisterPasswordMismatch',
      desc: '',
      args: [],
    );
  }

  /// `Email già registrata. Accedi per accettare l'invito.`
  String get invitationRegisterExistingUser {
    return Intl.message(
      'Email già registrata. Accedi per accettare l\'invito.',
      name: 'invitationRegisterExistingUser',
      desc: '',
      args: [],
    );
  }

  /// `Per questa email non esiste ancora un account. Usa Registrati.`
  String get invitationAcceptRequiresRegistration {
    return Intl.message(
      'Per questa email non esiste ancora un account. Usa Registrati.',
      name: 'invitationAcceptRequiresRegistration',
      desc: '',
      args: [],
    );
  }

  /// `Accetta invito`
  String get invitationAcceptButton {
    return Intl.message(
      'Accetta invito',
      name: 'invitationAcceptButton',
      desc: '',
      args: [],
    );
  }

  /// `Accettazione in corso...`
  String get invitationAcceptInProgress {
    return Intl.message(
      'Accettazione in corso...',
      name: 'invitationAcceptInProgress',
      desc: '',
      args: [],
    );
  }

  /// `Rifiuta invito`
  String get invitationDeclineButton {
    return Intl.message(
      'Rifiuta invito',
      name: 'invitationDeclineButton',
      desc: '',
      args: [],
    );
  }

  /// `Rifiuto in corso...`
  String get invitationDeclineInProgress {
    return Intl.message(
      'Rifiuto in corso...',
      name: 'invitationDeclineInProgress',
      desc: '',
      args: [],
    );
  }

  /// `Invito accettato`
  String get invitationAcceptSuccessTitle {
    return Intl.message(
      'Invito accettato',
      name: 'invitationAcceptSuccessTitle',
      desc: '',
      args: [],
    );
  }

  /// `Ora puoi usare il gestionale con i permessi assegnati.`
  String get invitationAcceptSuccessMessage {
    return Intl.message(
      'Ora puoi usare il gestionale con i permessi assegnati.',
      name: 'invitationAcceptSuccessMessage',
      desc: '',
      args: [],
    );
  }

  /// `Invito rifiutato`
  String get invitationDeclineSuccessTitle {
    return Intl.message(
      'Invito rifiutato',
      name: 'invitationDeclineSuccessTitle',
      desc: '',
      args: [],
    );
  }

  /// `Hai rifiutato l'invito. Non è stata aggiunta nessuna autorizzazione.`
  String get invitationDeclineSuccessMessage {
    return Intl.message(
      'Hai rifiutato l\'invito. Non è stata aggiunta nessuna autorizzazione.',
      name: 'invitationDeclineSuccessMessage',
      desc: '',
      args: [],
    );
  }

  /// `Vai al login`
  String get invitationDeclineGoLogin {
    return Intl.message(
      'Vai al login',
      name: 'invitationDeclineGoLogin',
      desc: '',
      args: [],
    );
  }

  /// `Questo invito non è valido.`
  String get invitationAcceptErrorInvalid {
    return Intl.message(
      'Questo invito non è valido.',
      name: 'invitationAcceptErrorInvalid',
      desc: '',
      args: [],
    );
  }

  /// `Questo invito è scaduto.`
  String get invitationAcceptErrorExpired {
    return Intl.message(
      'Questo invito è scaduto.',
      name: 'invitationAcceptErrorExpired',
      desc: '',
      args: [],
    );
  }

  /// `Questo invito è associato a un'altra email. Esegui il logout dall'account corrente, poi riapri questo link e accedi con l'email invitata.`
  String get invitationAcceptErrorEmailMismatch {
    return Intl.message(
      'Questo invito è associato a un\'altra email. Esegui il logout dall\'account corrente, poi riapri questo link e accedi con l\'email invitata.',
      name: 'invitationAcceptErrorEmailMismatch',
      desc: '',
      args: [],
    );
  }

  /// `Vai all'applicazione`
  String get invitationGoToApplication {
    return Intl.message(
      'Vai all\'applicazione',
      name: 'invitationGoToApplication',
      desc: '',
      args: [],
    );
  }

  /// `Impossibile completare l'operazione. Riprova.`
  String get invitationAcceptErrorGeneric {
    return Intl.message(
      'Impossibile completare l\'operazione. Riprova.',
      name: 'invitationAcceptErrorGeneric',
      desc: '',
      args: [],
    );
  }

  /// `Accesso`
  String get operatorsScopeTitle {
    return Intl.message(
      'Accesso',
      name: 'operatorsScopeTitle',
      desc: '',
      args: [],
    );
  }

  /// `Tutte le sedi`
  String get operatorsScopeBusiness {
    return Intl.message(
      'Tutte le sedi',
      name: 'operatorsScopeBusiness',
      desc: '',
      args: [],
    );
  }

  /// `Accesso completo a tutte le sedi del business`
  String get operatorsScopeBusinessDesc {
    return Intl.message(
      'Accesso completo a tutte le sedi del business',
      name: 'operatorsScopeBusinessDesc',
      desc: '',
      args: [],
    );
  }

  /// `Sedi specifiche`
  String get operatorsScopeLocations {
    return Intl.message(
      'Sedi specifiche',
      name: 'operatorsScopeLocations',
      desc: '',
      args: [],
    );
  }

  /// `Accesso limitato alle sedi selezionate`
  String get operatorsScopeLocationsDesc {
    return Intl.message(
      'Accesso limitato alle sedi selezionate',
      name: 'operatorsScopeLocationsDesc',
      desc: '',
      args: [],
    );
  }

  /// `Seleziona sedi`
  String get operatorsScopeSelectLocations {
    return Intl.message(
      'Seleziona sedi',
      name: 'operatorsScopeSelectLocations',
      desc: '',
      args: [],
    );
  }

  /// `Seleziona almeno una sede`
  String get operatorsScopeLocationsRequired {
    return Intl.message(
      'Seleziona almeno una sede',
      name: 'operatorsScopeLocationsRequired',
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

  /// `Elimina invito`
  String get operatorsDeleteInvite {
    return Intl.message(
      'Elimina invito',
      name: 'operatorsDeleteInvite',
      desc: '',
      args: [],
    );
  }

  /// `Vuoi eliminare definitivamente l'invito per {email}?`
  String operatorsDeleteInviteConfirm(String email) {
    return Intl.message(
      'Vuoi eliminare definitivamente l\'invito per $email?',
      name: 'operatorsDeleteInviteConfirm',
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

  /// `Accesso completo a tutte le funzionalità. Può gestire altri operatori e modificare impostazioni del business.`
  String get operatorsRoleAdminDesc {
    return Intl.message(
      'Accesso completo a tutte le funzionalità. Può gestire altri operatori e modificare impostazioni del business.',
      name: 'operatorsRoleAdminDesc',
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

  /// `Gestisce agenda e clienti. Vede e gestisce tutti gli appuntamenti, ma non può gestire operatori né impostazioni.`
  String get operatorsRoleManagerDesc {
    return Intl.message(
      'Gestisce agenda e clienti. Vede e gestisce tutti gli appuntamenti, ma non può gestire operatori né impostazioni.',
      name: 'operatorsRoleManagerDesc',
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

  /// `Vede e gestisce solo i propri appuntamenti. Può creare prenotazioni assegnate a sé stesso.`
  String get operatorsRoleStaffDesc {
    return Intl.message(
      'Vede e gestisce solo i propri appuntamenti. Può creare prenotazioni assegnate a sé stesso.',
      name: 'operatorsRoleStaffDesc',
      desc: '',
      args: [],
    );
  }

  /// `Visualizzatore`
  String get operatorsRoleViewer {
    return Intl.message(
      'Visualizzatore',
      name: 'operatorsRoleViewer',
      desc: '',
      args: [],
    );
  }

  /// `Può consultare appuntamenti, servizi, staff e disponibilità. Nessuna modifica consentita.`
  String get operatorsRoleViewerDesc {
    return Intl.message(
      'Può consultare appuntamenti, servizi, staff e disponibilità. Nessuna modifica consentita.',
      name: 'operatorsRoleViewerDesc',
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

  /// `Accettato il {date}`
  String operatorsAcceptedOn(String date) {
    return Intl.message(
      'Accettato il $date',
      name: 'operatorsAcceptedOn',
      desc: '',
      args: [date],
    );
  }

  /// `{count} inviti archiviati`
  String operatorsInvitesHistoryCount(int count) {
    return Intl.message(
      '$count inviti archiviati',
      name: 'operatorsInvitesHistoryCount',
      desc: '',
      args: [count],
    );
  }

  /// `In attesa`
  String get operatorsInviteStatusPending {
    return Intl.message(
      'In attesa',
      name: 'operatorsInviteStatusPending',
      desc: '',
      args: [],
    );
  }

  /// `Accettato`
  String get operatorsInviteStatusAccepted {
    return Intl.message(
      'Accettato',
      name: 'operatorsInviteStatusAccepted',
      desc: '',
      args: [],
    );
  }

  /// `Rifiutato`
  String get operatorsInviteStatusDeclined {
    return Intl.message(
      'Rifiutato',
      name: 'operatorsInviteStatusDeclined',
      desc: '',
      args: [],
    );
  }

  /// `Revocato`
  String get operatorsInviteStatusRevoked {
    return Intl.message(
      'Revocato',
      name: 'operatorsInviteStatusRevoked',
      desc: '',
      args: [],
    );
  }

  /// `Scaduto`
  String get operatorsInviteStatusExpired {
    return Intl.message(
      'Scaduto',
      name: 'operatorsInviteStatusExpired',
      desc: '',
      args: [],
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

  /// `Recupera password`
  String get authResetPasswordTitle {
    return Intl.message(
      'Recupera password',
      name: 'authResetPasswordTitle',
      desc: '',
      args: [],
    );
  }

  /// `Inserisci la tua email. Ti invieremo un link per reimpostare la password.`
  String get authResetPasswordMessage {
    return Intl.message(
      'Inserisci la tua email. Ti invieremo un link per reimpostare la password.',
      name: 'authResetPasswordMessage',
      desc: '',
      args: [],
    );
  }

  /// `Invia`
  String get authResetPasswordSend {
    return Intl.message(
      'Invia',
      name: 'authResetPasswordSend',
      desc: '',
      args: [],
    );
  }

  /// `Se l'email esiste nel sistema, riceverai un link per reimpostare la password.`
  String get authResetPasswordSuccess {
    return Intl.message(
      'Se l\'email esiste nel sistema, riceverai un link per reimpostare la password.',
      name: 'authResetPasswordSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Si è verificato un errore. Riprova più tardi.`
  String get authResetPasswordError {
    return Intl.message(
      'Si è verificato un errore. Riprova più tardi.',
      name: 'authResetPasswordError',
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

  /// `Profilo aggiornato con successo`
  String get profileUpdateSuccess {
    return Intl.message(
      'Profilo aggiornato con successo',
      name: 'profileUpdateSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Attenzione: cambiando email dovrai usarla per il login`
  String get profileEmailChangeWarning {
    return Intl.message(
      'Attenzione: cambiando email dovrai usarla per il login',
      name: 'profileEmailChangeWarning',
      desc: '',
      args: [],
    );
  }

  /// `Cambia password`
  String get profileChangePassword {
    return Intl.message(
      'Cambia password',
      name: 'profileChangePassword',
      desc: '',
      args: [],
    );
  }

  /// `Cambia business`
  String get profileSwitchBusiness {
    return Intl.message(
      'Cambia business',
      name: 'profileSwitchBusiness',
      desc: '',
      args: [],
    );
  }

  /// `Nuovo planning`
  String get planningCreateTitle {
    return Intl.message(
      'Nuovo planning',
      name: 'planningCreateTitle',
      desc: '',
      args: [],
    );
  }

  /// `Modifica planning`
  String get planningEditTitle {
    return Intl.message(
      'Modifica planning',
      name: 'planningEditTitle',
      desc: '',
      args: [],
    );
  }

  /// `Elimina planning`
  String get planningDeleteTitle {
    return Intl.message(
      'Elimina planning',
      name: 'planningDeleteTitle',
      desc: '',
      args: [],
    );
  }

  /// `Sei sicuro di voler eliminare questo planning? Gli orari settimanali verranno rimossi.`
  String get planningDeleteConfirm {
    return Intl.message(
      'Sei sicuro di voler eliminare questo planning? Gli orari settimanali verranno rimossi.',
      name: 'planningDeleteConfirm',
      desc: '',
      args: [],
    );
  }

  /// `Tipo planning`
  String get planningType {
    return Intl.message(
      'Tipo planning',
      name: 'planningType',
      desc: '',
      args: [],
    );
  }

  /// `Settimanale`
  String get planningTypeWeekly {
    return Intl.message(
      'Settimanale',
      name: 'planningTypeWeekly',
      desc: '',
      args: [],
    );
  }

  /// `Bisettimanale`
  String get planningTypeBiweekly {
    return Intl.message(
      'Bisettimanale',
      name: 'planningTypeBiweekly',
      desc: '',
      args: [],
    );
  }

  /// `Non disponibile`
  String get planningTypeUnavailable {
    return Intl.message(
      'Non disponibile',
      name: 'planningTypeUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `Data inizio validità`
  String get planningValidFrom {
    return Intl.message(
      'Data inizio validità',
      name: 'planningValidFrom',
      desc: '',
      args: [],
    );
  }

  /// `Data fine validità`
  String get planningValidTo {
    return Intl.message(
      'Data fine validità',
      name: 'planningValidTo',
      desc: '',
      args: [],
    );
  }

  /// `Senza scadenza`
  String get planningOpenEnded {
    return Intl.message(
      'Senza scadenza',
      name: 'planningOpenEnded',
      desc: '',
      args: [],
    );
  }

  /// `Valida dal {from} al {to}`
  String planningValidFromTo(String from, String to) {
    return Intl.message(
      'Valida dal $from al $to',
      name: 'planningValidFromTo',
      desc: '',
      args: [from, to],
    );
  }

  /// `Valida dal {from}`
  String planningValidFromOnly(String from) {
    return Intl.message(
      'Valida dal $from',
      name: 'planningValidFromOnly',
      desc: '',
      args: [from],
    );
  }

  /// `{hours}h/settimana`
  String planningWeeklyHours(int hours) {
    return Intl.message(
      '${hours}h/settimana',
      name: 'planningWeeklyHours',
      desc: '',
      args: [hours],
    );
  }

  /// `Sett. A: {hoursA}h | Sett. B: {hoursB}h | Tot: {total}h`
  String planningBiweeklyHours(int hoursA, int hoursB, int total) {
    return Intl.message(
      'Sett. A: ${hoursA}h | Sett. B: ${hoursB}h | Tot: ${total}h',
      name: 'planningBiweeklyHours',
      desc: '',
      args: [hoursA, hoursB, total],
    );
  }

  /// `Mostra planning scaduti ({count})`
  String planningShowExpired(int count) {
    return Intl.message(
      'Mostra planning scaduti ($count)',
      name: 'planningShowExpired',
      desc: '',
      args: [count],
    );
  }

  /// `Nascondi planning scaduti`
  String get planningHideExpired {
    return Intl.message(
      'Nascondi planning scaduti',
      name: 'planningHideExpired',
      desc: '',
      args: [],
    );
  }

  /// `Imposta data fine`
  String get planningSetEndDate {
    return Intl.message(
      'Imposta data fine',
      name: 'planningSetEndDate',
      desc: '',
      args: [],
    );
  }

  /// `Seleziona data`
  String get planningSelectDate {
    return Intl.message(
      'Seleziona data',
      name: 'planningSelectDate',
      desc: '',
      args: [],
    );
  }

  /// `Planning`
  String get planningListTitle {
    return Intl.message(
      'Planning',
      name: 'planningListTitle',
      desc: '',
      args: [],
    );
  }

  /// `Nessun planning definito`
  String get planningListEmpty {
    return Intl.message(
      'Nessun planning definito',
      name: 'planningListEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Aggiungi planning`
  String get planningListAdd {
    return Intl.message(
      'Aggiungi planning',
      name: 'planningListAdd',
      desc: '',
      args: [],
    );
  }

  /// `Settimana A`
  String get planningWeekA {
    return Intl.message(
      'Settimana A',
      name: 'planningWeekA',
      desc: '',
      args: [],
    );
  }

  /// `Settimana B`
  String get planningWeekB {
    return Intl.message(
      'Settimana B',
      name: 'planningWeekB',
      desc: '',
      args: [],
    );
  }

  /// `Settimana attuale: {week}`
  String planningCurrentWeek(String week) {
    return Intl.message(
      'Settimana attuale: $week',
      name: 'planningCurrentWeek',
      desc: '',
      args: [week],
    );
  }

  /// `Dal {from} al {to}`
  String planningValidityRange(String from, String to) {
    return Intl.message(
      'Dal $from al $to',
      name: 'planningValidityRange',
      desc: '',
      args: [from, to],
    );
  }

  /// `Dal {from}`
  String planningValidityFrom(String from) {
    return Intl.message(
      'Dal $from',
      name: 'planningValidityFrom',
      desc: '',
      args: [from],
    );
  }

  /// `Attivo`
  String get planningActive {
    return Intl.message('Attivo', name: 'planningActive', desc: '', args: []);
  }

  /// `Futuro`
  String get planningFuture {
    return Intl.message('Futuro', name: 'planningFuture', desc: '', args: []);
  }

  /// `Passato`
  String get planningPast {
    return Intl.message('Passato', name: 'planningPast', desc: '', args: []);
  }

  /// `Prezzo`
  String get appointmentPriceLabel {
    return Intl.message(
      'Prezzo',
      name: 'appointmentPriceLabel',
      desc: '',
      args: [],
    );
  }

  /// `Prezzo personalizzato`
  String get appointmentPriceHint {
    return Intl.message(
      'Prezzo personalizzato',
      name: 'appointmentPriceHint',
      desc: '',
      args: [],
    );
  }

  /// `Ripristina prezzo del servizio`
  String get appointmentPriceResetTooltip {
    return Intl.message(
      'Ripristina prezzo del servizio',
      name: 'appointmentPriceResetTooltip',
      desc: '',
      args: [],
    );
  }

  /// `Gratuito`
  String get appointmentPriceFree {
    return Intl.message(
      'Gratuito',
      name: 'appointmentPriceFree',
      desc: '',
      args: [],
    );
  }

  /// `Storico prenotazione`
  String get bookingHistoryTitle {
    return Intl.message(
      'Storico prenotazione',
      name: 'bookingHistoryTitle',
      desc: '',
      args: [],
    );
  }

  /// `Nessun evento registrato`
  String get bookingHistoryEmpty {
    return Intl.message(
      'Nessun evento registrato',
      name: 'bookingHistoryEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Caricamento storico...`
  String get bookingHistoryLoading {
    return Intl.message(
      'Caricamento storico...',
      name: 'bookingHistoryLoading',
      desc: '',
      args: [],
    );
  }

  /// `Errore nel caricamento dello storico`
  String get bookingHistoryError {
    return Intl.message(
      'Errore nel caricamento dello storico',
      name: 'bookingHistoryError',
      desc: '',
      args: [],
    );
  }

  /// `Prenotazione creata`
  String get bookingHistoryEventCreated {
    return Intl.message(
      'Prenotazione creata',
      name: 'bookingHistoryEventCreated',
      desc: '',
      args: [],
    );
  }

  /// `Prenotazione modificata`
  String get bookingHistoryEventUpdated {
    return Intl.message(
      'Prenotazione modificata',
      name: 'bookingHistoryEventUpdated',
      desc: '',
      args: [],
    );
  }

  /// `Prenotazione cancellata`
  String get bookingHistoryEventCancelled {
    return Intl.message(
      'Prenotazione cancellata',
      name: 'bookingHistoryEventCancelled',
      desc: '',
      args: [],
    );
  }

  /// `Servizio aggiunto`
  String get bookingHistoryEventItemAdded {
    return Intl.message(
      'Servizio aggiunto',
      name: 'bookingHistoryEventItemAdded',
      desc: '',
      args: [],
    );
  }

  /// `Servizio rimosso`
  String get bookingHistoryEventItemDeleted {
    return Intl.message(
      'Servizio rimosso',
      name: 'bookingHistoryEventItemDeleted',
      desc: '',
      args: [],
    );
  }

  /// `Appuntamento modificato`
  String get bookingHistoryEventAppointmentUpdated {
    return Intl.message(
      'Appuntamento modificato',
      name: 'bookingHistoryEventAppointmentUpdated',
      desc: '',
      args: [],
    );
  }

  /// `Orario modificato`
  String get bookingHistoryEventTimeChanged {
    return Intl.message(
      'Orario modificato',
      name: 'bookingHistoryEventTimeChanged',
      desc: '',
      args: [],
    );
  }

  /// `Operatore cambiato`
  String get bookingHistoryEventStaffChanged {
    return Intl.message(
      'Operatore cambiato',
      name: 'bookingHistoryEventStaffChanged',
      desc: '',
      args: [],
    );
  }

  /// `Prezzo modificato`
  String get bookingHistoryEventPriceChanged {
    return Intl.message(
      'Prezzo modificato',
      name: 'bookingHistoryEventPriceChanged',
      desc: '',
      args: [],
    );
  }

  /// `Durata modificata`
  String get bookingHistoryEventDurationChanged {
    return Intl.message(
      'Durata modificata',
      name: 'bookingHistoryEventDurationChanged',
      desc: '',
      args: [],
    );
  }

  /// `Prenotazione riprogrammata`
  String get bookingHistoryEventReplaced {
    return Intl.message(
      'Prenotazione riprogrammata',
      name: 'bookingHistoryEventReplaced',
      desc: '',
      args: [],
    );
  }

  /// `Operatore`
  String get bookingHistoryActorStaff {
    return Intl.message(
      'Operatore',
      name: 'bookingHistoryActorStaff',
      desc: '',
      args: [],
    );
  }

  /// `Cliente`
  String get bookingHistoryActorCustomer {
    return Intl.message(
      'Cliente',
      name: 'bookingHistoryActorCustomer',
      desc: '',
      args: [],
    );
  }

  /// `Sistema`
  String get bookingHistoryActorSystem {
    return Intl.message(
      'Sistema',
      name: 'bookingHistoryActorSystem',
      desc: '',
      args: [],
    );
  }

  /// `Campi modificati: {fields}`
  String bookingHistoryChangedFields(String fields) {
    return Intl.message(
      'Campi modificati: $fields',
      name: 'bookingHistoryChangedFields',
      desc: '',
      args: [fields],
    );
  }

  /// `CANCELLATO`
  String get cancelledBadge {
    return Intl.message(
      'CANCELLATO',
      name: 'cancelledBadge',
      desc: '',
      args: [],
    );
  }

  /// `ANNULLATA`
  String get clientAppointmentsCancelledBadge {
    return Intl.message(
      'ANNULLATA',
      name: 'clientAppointmentsCancelledBadge',
      desc: '',
      args: [],
    );
  }

  /// `Ripeti questo appuntamento`
  String get recurrenceRepeatBooking {
    return Intl.message(
      'Ripeti questo appuntamento',
      name: 'recurrenceRepeatBooking',
      desc: '',
      args: [],
    );
  }

  /// `Frequenza`
  String get recurrenceFrequency {
    return Intl.message(
      'Frequenza',
      name: 'recurrenceFrequency',
      desc: '',
      args: [],
    );
  }

  /// `Ogni`
  String get recurrenceEvery {
    return Intl.message('Ogni', name: 'recurrenceEvery', desc: '', args: []);
  }

  /// `giorno`
  String get recurrenceDay {
    return Intl.message('giorno', name: 'recurrenceDay', desc: '', args: []);
  }

  /// `giorni`
  String get recurrenceDays {
    return Intl.message('giorni', name: 'recurrenceDays', desc: '', args: []);
  }

  /// `settimana`
  String get recurrenceWeek {
    return Intl.message(
      'settimana',
      name: 'recurrenceWeek',
      desc: '',
      args: [],
    );
  }

  /// `settimane`
  String get recurrenceWeeks {
    return Intl.message(
      'settimane',
      name: 'recurrenceWeeks',
      desc: '',
      args: [],
    );
  }

  /// `mese`
  String get recurrenceMonth {
    return Intl.message('mese', name: 'recurrenceMonth', desc: '', args: []);
  }

  /// `mesi`
  String get recurrenceMonths {
    return Intl.message('mesi', name: 'recurrenceMonths', desc: '', args: []);
  }

  /// `Termina`
  String get recurrenceEnds {
    return Intl.message('Termina', name: 'recurrenceEnds', desc: '', args: []);
  }

  /// `Per un anno`
  String get recurrenceNever {
    return Intl.message(
      'Per un anno',
      name: 'recurrenceNever',
      desc: '',
      args: [],
    );
  }

  /// `Dopo`
  String get recurrenceAfter {
    return Intl.message('Dopo', name: 'recurrenceAfter', desc: '', args: []);
  }

  /// `occorrenze`
  String get recurrenceOccurrences {
    return Intl.message(
      'occorrenze',
      name: 'recurrenceOccurrences',
      desc: '',
      args: [],
    );
  }

  /// `Il`
  String get recurrenceOnDate {
    return Intl.message('Il', name: 'recurrenceOnDate', desc: '', args: []);
  }

  /// `Seleziona data`
  String get recurrenceSelectDate {
    return Intl.message(
      'Seleziona data',
      name: 'recurrenceSelectDate',
      desc: '',
      args: [],
    );
  }

  /// `Anteprima appuntamenti`
  String get recurrencePreviewTitle {
    return Intl.message(
      'Anteprima appuntamenti',
      name: 'recurrencePreviewTitle',
      desc: '',
      args: [],
    );
  }

  /// `{count} appuntamenti`
  String recurrencePreviewCount(int count) {
    return Intl.message(
      '$count appuntamenti',
      name: 'recurrencePreviewCount',
      desc: '',
      args: [count],
    );
  }

  /// `{count} selezionati`
  String recurrencePreviewSelected(int count) {
    return Intl.message(
      '$count selezionati',
      name: 'recurrencePreviewSelected',
      desc: '',
      args: [count],
    );
  }

  /// `{count} conflitti`
  String recurrencePreviewConflicts(int count) {
    return Intl.message(
      '$count conflitti',
      name: 'recurrencePreviewConflicts',
      desc: '',
      args: [count],
    );
  }

  /// `Deseleziona le date che non vuoi creare`
  String get recurrencePreviewHint {
    return Intl.message(
      'Deseleziona le date che non vuoi creare',
      name: 'recurrencePreviewHint',
      desc: '',
      args: [],
    );
  }

  /// `Crea {count} appuntamenti`
  String recurrencePreviewConfirm(int count) {
    return Intl.message(
      'Crea $count appuntamenti',
      name: 'recurrencePreviewConfirm',
      desc: '',
      args: [count],
    );
  }

  /// `Serie creata`
  String get recurrenceSummaryTitle {
    return Intl.message(
      'Serie creata',
      name: 'recurrenceSummaryTitle',
      desc: '',
      args: [],
    );
  }

  /// `{count} appuntamenti creati`
  String recurrenceSummaryCreated(int count) {
    return Intl.message(
      '$count appuntamenti creati',
      name: 'recurrenceSummaryCreated',
      desc: '',
      args: [count],
    );
  }

  /// `{count} saltati per conflitto`
  String recurrenceSummarySkipped(int count) {
    return Intl.message(
      '$count saltati per conflitto',
      name: 'recurrenceSummarySkipped',
      desc: '',
      args: [count],
    );
  }

  /// `Errore nella creazione della serie`
  String get recurrenceSummaryError {
    return Intl.message(
      'Errore nella creazione della serie',
      name: 'recurrenceSummaryError',
      desc: '',
      args: [],
    );
  }

  /// `Appuntamenti:`
  String get recurrenceSummaryAppointments {
    return Intl.message(
      'Appuntamenti:',
      name: 'recurrenceSummaryAppointments',
      desc: '',
      args: [],
    );
  }

  /// `Saltato per conflitto`
  String get recurrenceSummaryConflict {
    return Intl.message(
      'Saltato per conflitto',
      name: 'recurrenceSummaryConflict',
      desc: '',
      args: [],
    );
  }

  /// `Eliminato`
  String get recurrenceSummaryDeleted {
    return Intl.message(
      'Eliminato',
      name: 'recurrenceSummaryDeleted',
      desc: '',
      args: [],
    );
  }

  /// `Appuntamento ricorrente`
  String get recurrenceSeriesIcon {
    return Intl.message(
      'Appuntamento ricorrente',
      name: 'recurrenceSeriesIcon',
      desc: '',
      args: [],
    );
  }

  /// `{index} di {total}`
  String recurrenceSeriesOf(int index, int total) {
    return Intl.message(
      '$index di $total',
      name: 'recurrenceSeriesOf',
      desc: '',
      args: [index, total],
    );
  }

  /// `Elimina appuntamento ricorrente`
  String get recurringDeleteTitle {
    return Intl.message(
      'Elimina appuntamento ricorrente',
      name: 'recurringDeleteTitle',
      desc: '',
      args: [],
    );
  }

  /// `Questo è l'appuntamento {index} di {total} nella serie.`
  String recurringDeleteMessage(int index, int total) {
    return Intl.message(
      'Questo è l\'appuntamento $index di $total nella serie.',
      name: 'recurringDeleteMessage',
      desc: '',
      args: [index, total],
    );
  }

  /// `Quali appuntamenti vuoi eliminare?`
  String get recurringDeleteChooseScope {
    return Intl.message(
      'Quali appuntamenti vuoi eliminare?',
      name: 'recurringDeleteChooseScope',
      desc: '',
      args: [],
    );
  }

  /// `Modifica appuntamento ricorrente`
  String get recurringEditTitle {
    return Intl.message(
      'Modifica appuntamento ricorrente',
      name: 'recurringEditTitle',
      desc: '',
      args: [],
    );
  }

  /// `Questo è l'appuntamento {index} di {total} nella serie.`
  String recurringEditMessage(int index, int total) {
    return Intl.message(
      'Questo è l\'appuntamento $index di $total nella serie.',
      name: 'recurringEditMessage',
      desc: '',
      args: [index, total],
    );
  }

  /// `Quali appuntamenti vuoi modificare?`
  String get recurringEditChooseScope {
    return Intl.message(
      'Quali appuntamenti vuoi modificare?',
      name: 'recurringEditChooseScope',
      desc: '',
      args: [],
    );
  }

  /// `Solo questo`
  String get recurringScopeOnlyThis {
    return Intl.message(
      'Solo questo',
      name: 'recurringScopeOnlyThis',
      desc: '',
      args: [],
    );
  }

  /// `Questo e futuri`
  String get recurringScopeThisAndFuture {
    return Intl.message(
      'Questo e futuri',
      name: 'recurringScopeThisAndFuture',
      desc: '',
      args: [],
    );
  }

  /// `Tutti`
  String get recurringScopeAll {
    return Intl.message('Tutti', name: 'recurringScopeAll', desc: '', args: []);
  }

  /// `Durata totale: {duration}`
  String bookingTotalDuration(String duration) {
    return Intl.message(
      'Durata totale: $duration',
      name: 'bookingTotalDuration',
      desc: '',
      args: [duration],
    );
  }

  /// `Totale: {price}`
  String bookingTotalPrice(String price) {
    return Intl.message(
      'Totale: $price',
      name: 'bookingTotalPrice',
      desc: '',
      args: [price],
    );
  }

  /// `È necessario selezionare un cliente per gli appuntamenti ricorrenti`
  String get recurrenceClientRequired {
    return Intl.message(
      'È necessario selezionare un cliente per gli appuntamenti ricorrenti',
      name: 'recurrenceClientRequired',
      desc: '',
      args: [],
    );
  }

  /// `Sovrapposizioni`
  String get recurrenceConflictHandling {
    return Intl.message(
      'Sovrapposizioni',
      name: 'recurrenceConflictHandling',
      desc: '',
      args: [],
    );
  }

  /// `Salta date con conflitti`
  String get recurrenceConflictSkip {
    return Intl.message(
      'Salta date con conflitti',
      name: 'recurrenceConflictSkip',
      desc: '',
      args: [],
    );
  }

  /// `Non crea appuntamenti se ci sono sovrapposizioni`
  String get recurrenceConflictSkipDescription {
    return Intl.message(
      'Non crea appuntamenti se ci sono sovrapposizioni',
      name: 'recurrenceConflictSkipDescription',
      desc: '',
      args: [],
    );
  }

  /// `Crea comunque`
  String get recurrenceConflictForce {
    return Intl.message(
      'Crea comunque',
      name: 'recurrenceConflictForce',
      desc: '',
      args: [],
    );
  }

  /// `Crea gli appuntamenti anche se ci sono sovrapposizioni`
  String get recurrenceConflictForceDescription {
    return Intl.message(
      'Crea gli appuntamenti anche se ci sono sovrapposizioni',
      name: 'recurrenceConflictForceDescription',
      desc: '',
      args: [],
    );
  }

  /// `Report`
  String get reportsTitle {
    return Intl.message('Report', name: 'reportsTitle', desc: '', args: []);
  }

  /// `Nessun dato disponibile`
  String get reportsNoData {
    return Intl.message(
      'Nessun dato disponibile',
      name: 'reportsNoData',
      desc: '',
      args: [],
    );
  }

  /// `Aggiorna`
  String get actionRefresh {
    return Intl.message('Aggiorna', name: 'actionRefresh', desc: '', args: []);
  }

  /// `Preset periodo`
  String get reportsPresets {
    return Intl.message(
      'Preset periodo',
      name: 'reportsPresets',
      desc: '',
      args: [],
    );
  }

  /// `Scegli periodo`
  String get reportsPresetCustom {
    return Intl.message(
      'Scegli periodo',
      name: 'reportsPresetCustom',
      desc: '',
      args: [],
    );
  }

  /// `Oggi`
  String get reportsPresetToday {
    return Intl.message('Oggi', name: 'reportsPresetToday', desc: '', args: []);
  }

  /// `Questa settimana`
  String get reportsPresetWeek {
    return Intl.message(
      'Questa settimana',
      name: 'reportsPresetWeek',
      desc: '',
      args: [],
    );
  }

  /// `Mese corrente`
  String get reportsPresetMonth {
    return Intl.message(
      'Mese corrente',
      name: 'reportsPresetMonth',
      desc: '',
      args: [],
    );
  }

  /// `Mese scorso`
  String get reportsPresetLastMonth {
    return Intl.message(
      'Mese scorso',
      name: 'reportsPresetLastMonth',
      desc: '',
      args: [],
    );
  }

  /// `Trimestre corrente`
  String get reportsPresetQuarter {
    return Intl.message(
      'Trimestre corrente',
      name: 'reportsPresetQuarter',
      desc: '',
      args: [],
    );
  }

  /// `Semestre corrente`
  String get reportsPresetSemester {
    return Intl.message(
      'Semestre corrente',
      name: 'reportsPresetSemester',
      desc: '',
      args: [],
    );
  }

  /// `Anno corrente`
  String get reportsPresetYear {
    return Intl.message(
      'Anno corrente',
      name: 'reportsPresetYear',
      desc: '',
      args: [],
    );
  }

  /// `Ultimi 3 mesi`
  String get reportsPresetLast3Months {
    return Intl.message(
      'Ultimi 3 mesi',
      name: 'reportsPresetLast3Months',
      desc: '',
      args: [],
    );
  }

  /// `Ultimi 6 mesi`
  String get reportsPresetLast6Months {
    return Intl.message(
      'Ultimi 6 mesi',
      name: 'reportsPresetLast6Months',
      desc: '',
      args: [],
    );
  }

  /// `Anno precedente`
  String get reportsPresetLastYear {
    return Intl.message(
      'Anno precedente',
      name: 'reportsPresetLastYear',
      desc: '',
      args: [],
    );
  }

  /// `Includi intero periodo (anche futuro)`
  String get reportsFullPeriodToggle {
    return Intl.message(
      'Includi intero periodo (anche futuro)',
      name: 'reportsFullPeriodToggle',
      desc: '',
      args: [],
    );
  }

  /// `Sedi`
  String get reportsFilterLocations {
    return Intl.message(
      'Sedi',
      name: 'reportsFilterLocations',
      desc: '',
      args: [],
    );
  }

  /// `Staff`
  String get reportsFilterStaff {
    return Intl.message(
      'Staff',
      name: 'reportsFilterStaff',
      desc: '',
      args: [],
    );
  }

  /// `Servizi`
  String get reportsFilterServices {
    return Intl.message(
      'Servizi',
      name: 'reportsFilterServices',
      desc: '',
      args: [],
    );
  }

  /// `Stato`
  String get reportsFilterStatus {
    return Intl.message(
      'Stato',
      name: 'reportsFilterStatus',
      desc: '',
      args: [],
    );
  }

  /// `Confermato`
  String get statusConfirmed {
    return Intl.message(
      'Confermato',
      name: 'statusConfirmed',
      desc: '',
      args: [],
    );
  }

  /// `Completato`
  String get statusCompleted {
    return Intl.message(
      'Completato',
      name: 'statusCompleted',
      desc: '',
      args: [],
    );
  }

  /// `Cancellato`
  String get statusCancelled {
    return Intl.message(
      'Cancellato',
      name: 'statusCancelled',
      desc: '',
      args: [],
    );
  }

  /// `Seleziona tutti`
  String get actionSelectAll {
    return Intl.message(
      'Seleziona tutti',
      name: 'actionSelectAll',
      desc: '',
      args: [],
    );
  }

  /// `Deseleziona tutti`
  String get actionDeselectAll {
    return Intl.message(
      'Deseleziona tutti',
      name: 'actionDeselectAll',
      desc: '',
      args: [],
    );
  }

  /// `Applica`
  String get actionApply {
    return Intl.message('Applica', name: 'actionApply', desc: '', args: []);
  }

  /// `Appuntamenti`
  String get reportsTotalAppointments {
    return Intl.message(
      'Appuntamenti',
      name: 'reportsTotalAppointments',
      desc: '',
      args: [],
    );
  }

  /// `Incasso`
  String get reportsTotalRevenue {
    return Intl.message(
      'Incasso',
      name: 'reportsTotalRevenue',
      desc: '',
      args: [],
    );
  }

  /// `Ore lavorate`
  String get reportsTotalHours {
    return Intl.message(
      'Ore lavorate',
      name: 'reportsTotalHours',
      desc: '',
      args: [],
    );
  }

  /// `Occupazione`
  String get reportsOccupancyPercentage {
    return Intl.message(
      'Occupazione',
      name: 'reportsOccupancyPercentage',
      desc: '',
      args: [],
    );
  }

  /// `Clienti unici`
  String get reportsUniqueClients {
    return Intl.message(
      'Clienti unici',
      name: 'reportsUniqueClients',
      desc: '',
      args: [],
    );
  }

  /// `Per operatore`
  String get reportsByStaff {
    return Intl.message(
      'Per operatore',
      name: 'reportsByStaff',
      desc: '',
      args: [],
    );
  }

  /// `Per sede`
  String get reportsByLocation {
    return Intl.message(
      'Per sede',
      name: 'reportsByLocation',
      desc: '',
      args: [],
    );
  }

  /// `Per servizio`
  String get reportsByService {
    return Intl.message(
      'Per servizio',
      name: 'reportsByService',
      desc: '',
      args: [],
    );
  }

  /// `Per giorno della settimana`
  String get reportsByDayOfWeek {
    return Intl.message(
      'Per giorno della settimana',
      name: 'reportsByDayOfWeek',
      desc: '',
      args: [],
    );
  }

  /// `Per periodo`
  String get reportsByPeriod {
    return Intl.message(
      'Per periodo',
      name: 'reportsByPeriod',
      desc: '',
      args: [],
    );
  }

  /// `Per fascia oraria`
  String get reportsByHour {
    return Intl.message(
      'Per fascia oraria',
      name: 'reportsByHour',
      desc: '',
      args: [],
    );
  }

  /// `Staff`
  String get reportsWorkHoursTitle {
    return Intl.message(
      'Staff',
      name: 'reportsWorkHoursTitle',
      desc: '',
      args: [],
    );
  }

  /// `Appuntamenti`
  String get reportsTabAppointments {
    return Intl.message(
      'Appuntamenti',
      name: 'reportsTabAppointments',
      desc: '',
      args: [],
    );
  }

  /// `Team`
  String get reportsTabStaff {
    return Intl.message('Team', name: 'reportsTabStaff', desc: '', args: []);
  }

  /// `Riepilogo ore programmate, lavorate e assenze`
  String get reportsWorkHoursSubtitle {
    return Intl.message(
      'Riepilogo ore programmate, lavorate e assenze',
      name: 'reportsWorkHoursSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Programmate`
  String get reportsWorkHoursScheduled {
    return Intl.message(
      'Programmate',
      name: 'reportsWorkHoursScheduled',
      desc: '',
      args: [],
    );
  }

  /// `Prenotate`
  String get reportsWorkHoursWorked {
    return Intl.message(
      'Prenotate',
      name: 'reportsWorkHoursWorked',
      desc: '',
      args: [],
    );
  }

  /// `Blocchi`
  String get reportsWorkHoursBlocked {
    return Intl.message(
      'Blocchi',
      name: 'reportsWorkHoursBlocked',
      desc: '',
      args: [],
    );
  }

  /// `Ferie/Assenze`
  String get reportsWorkHoursOff {
    return Intl.message(
      'Ferie/Assenze',
      name: 'reportsWorkHoursOff',
      desc: '',
      args: [],
    );
  }

  /// `Effettive`
  String get reportsWorkHoursAvailable {
    return Intl.message(
      'Effettive',
      name: 'reportsWorkHoursAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Occupazione`
  String get reportsWorkHoursUtilization {
    return Intl.message(
      'Occupazione',
      name: 'reportsWorkHoursUtilization',
      desc: '',
      args: [],
    );
  }

  /// `Programmate`
  String get reportsColScheduledHours {
    return Intl.message(
      'Programmate',
      name: 'reportsColScheduledHours',
      desc: '',
      args: [],
    );
  }

  /// `Prenotate`
  String get reportsColWorkedHours {
    return Intl.message(
      'Prenotate',
      name: 'reportsColWorkedHours',
      desc: '',
      args: [],
    );
  }

  /// `Blocchi`
  String get reportsColBlockedHours {
    return Intl.message(
      'Blocchi',
      name: 'reportsColBlockedHours',
      desc: '',
      args: [],
    );
  }

  /// `Ferie/Assenze`
  String get reportsColOffHours {
    return Intl.message(
      'Ferie/Assenze',
      name: 'reportsColOffHours',
      desc: '',
      args: [],
    );
  }

  /// `Effettive`
  String get reportsColAvailableHours {
    return Intl.message(
      'Effettive',
      name: 'reportsColAvailableHours',
      desc: '',
      args: [],
    );
  }

  /// `Occupazione`
  String get reportsColUtilization {
    return Intl.message(
      'Occupazione',
      name: 'reportsColUtilization',
      desc: '',
      args: [],
    );
  }

  /// `Operatore`
  String get reportsColStaff {
    return Intl.message(
      'Operatore',
      name: 'reportsColStaff',
      desc: '',
      args: [],
    );
  }

  /// `Appuntamenti`
  String get reportsColAppointments {
    return Intl.message(
      'Appuntamenti',
      name: 'reportsColAppointments',
      desc: '',
      args: [],
    );
  }

  /// `Incasso`
  String get reportsColRevenue {
    return Intl.message(
      'Incasso',
      name: 'reportsColRevenue',
      desc: '',
      args: [],
    );
  }

  /// `Ore`
  String get reportsColHours {
    return Intl.message('Ore', name: 'reportsColHours', desc: '', args: []);
  }

  /// `Media`
  String get reportsColAvgRevenue {
    return Intl.message(
      'Media',
      name: 'reportsColAvgRevenue',
      desc: '',
      args: [],
    );
  }

  /// `%`
  String get reportsColPercentage {
    return Intl.message('%', name: 'reportsColPercentage', desc: '', args: []);
  }

  /// `Sede`
  String get reportsColLocation {
    return Intl.message('Sede', name: 'reportsColLocation', desc: '', args: []);
  }

  /// `Servizio`
  String get reportsColService {
    return Intl.message(
      'Servizio',
      name: 'reportsColService',
      desc: '',
      args: [],
    );
  }

  /// `Categoria`
  String get reportsColCategory {
    return Intl.message(
      'Categoria',
      name: 'reportsColCategory',
      desc: '',
      args: [],
    );
  }

  /// `Durata media`
  String get reportsColAvgDuration {
    return Intl.message(
      'Durata media',
      name: 'reportsColAvgDuration',
      desc: '',
      args: [],
    );
  }

  /// `Giorno`
  String get reportsColDay {
    return Intl.message('Giorno', name: 'reportsColDay', desc: '', args: []);
  }

  /// `Periodo`
  String get reportsColPeriod {
    return Intl.message(
      'Periodo',
      name: 'reportsColPeriod',
      desc: '',
      args: [],
    );
  }

  /// `Ora`
  String get reportsColHour {
    return Intl.message('Ora', name: 'reportsColHour', desc: '', args: []);
  }

  /// `Lunedì`
  String get dayMonday {
    return Intl.message('Lunedì', name: 'dayMonday', desc: '', args: []);
  }

  /// `Martedì`
  String get dayTuesday {
    return Intl.message('Martedì', name: 'dayTuesday', desc: '', args: []);
  }

  /// `Mercoledì`
  String get dayWednesday {
    return Intl.message('Mercoledì', name: 'dayWednesday', desc: '', args: []);
  }

  /// `Giovedì`
  String get dayThursday {
    return Intl.message('Giovedì', name: 'dayThursday', desc: '', args: []);
  }

  /// `Venerdì`
  String get dayFriday {
    return Intl.message('Venerdì', name: 'dayFriday', desc: '', args: []);
  }

  /// `Sabato`
  String get daySaturday {
    return Intl.message('Sabato', name: 'daySaturday', desc: '', args: []);
  }

  /// `Domenica`
  String get daySunday {
    return Intl.message('Domenica', name: 'daySunday', desc: '', args: []);
  }

  /// `Risorse richieste`
  String get serviceRequiredResourcesLabel {
    return Intl.message(
      'Risorse richieste',
      name: 'serviceRequiredResourcesLabel',
      desc: '',
      args: [],
    );
  }

  /// `Nessuna risorsa richiesta`
  String get resourceNoneLabel {
    return Intl.message(
      'Nessuna risorsa richiesta',
      name: 'resourceNoneLabel',
      desc: '',
      args: [],
    );
  }

  /// `Seleziona risorse`
  String get resourceSelectLabel {
    return Intl.message(
      'Seleziona risorse',
      name: 'resourceSelectLabel',
      desc: '',
      args: [],
    );
  }

  /// `Risorse`
  String get resourcesTitle {
    return Intl.message('Risorse', name: 'resourcesTitle', desc: '', args: []);
  }

  /// `Nessuna risorsa configurata per questa sede`
  String get resourcesEmpty {
    return Intl.message(
      'Nessuna risorsa configurata per questa sede',
      name: 'resourcesEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Le risorse sono attrezzature o spazi (es. cabine, lettini) che possono essere associati ai servizi`
  String get resourcesEmptyHint {
    return Intl.message(
      'Le risorse sono attrezzature o spazi (es. cabine, lettini) che possono essere associati ai servizi',
      name: 'resourcesEmptyHint',
      desc: '',
      args: [],
    );
  }

  /// `Nuova risorsa`
  String get resourceNew {
    return Intl.message(
      'Nuova risorsa',
      name: 'resourceNew',
      desc: '',
      args: [],
    );
  }

  /// `Modifica risorsa`
  String get resourceEdit {
    return Intl.message(
      'Modifica risorsa',
      name: 'resourceEdit',
      desc: '',
      args: [],
    );
  }

  /// `Nome risorsa`
  String get resourceNameLabel {
    return Intl.message(
      'Nome risorsa',
      name: 'resourceNameLabel',
      desc: '',
      args: [],
    );
  }

  /// `Quantità disponibile`
  String get resourceQuantityLabel {
    return Intl.message(
      'Quantità disponibile',
      name: 'resourceQuantityLabel',
      desc: '',
      args: [],
    );
  }

  /// `Tipo (opzionale)`
  String get resourceTypeLabel {
    return Intl.message(
      'Tipo (opzionale)',
      name: 'resourceTypeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Note (opzionale)`
  String get resourceNoteLabel {
    return Intl.message(
      'Note (opzionale)',
      name: 'resourceNoteLabel',
      desc: '',
      args: [],
    );
  }

  /// `Eliminare questa risorsa?`
  String get resourceDeleteConfirm {
    return Intl.message(
      'Eliminare questa risorsa?',
      name: 'resourceDeleteConfirm',
      desc: '',
      args: [],
    );
  }

  /// `I servizi che usano questa risorsa non saranno più vincolati alla sua disponibilità`
  String get resourceDeleteWarning {
    return Intl.message(
      'I servizi che usano questa risorsa non saranno più vincolati alla sua disponibilità',
      name: 'resourceDeleteWarning',
      desc: '',
      args: [],
    );
  }

  /// `Servizi che usano questa risorsa`
  String get resourceServicesLabel {
    return Intl.message(
      'Servizi che usano questa risorsa',
      name: 'resourceServicesLabel',
      desc: '',
      args: [],
    );
  }

  /// `Nessun servizio associato`
  String get resourceNoServicesSelected {
    return Intl.message(
      'Nessun servizio associato',
      name: 'resourceNoServicesSelected',
      desc: '',
      args: [],
    );
  }

  /// `Seleziona servizi`
  String get resourceSelectServices {
    return Intl.message(
      'Seleziona servizi',
      name: 'resourceSelectServices',
      desc: '',
      args: [],
    );
  }

  /// `1 servizio`
  String get resourceServiceCountSingular {
    return Intl.message(
      '1 servizio',
      name: 'resourceServiceCountSingular',
      desc: '',
      args: [],
    );
  }

  /// `{count} servizi`
  String resourceServiceCountPlural(int count) {
    return Intl.message(
      '$count servizi',
      name: 'resourceServiceCountPlural',
      desc: '',
      args: [count],
    );
  }

  /// `Qtà richiesta`
  String get resourceQuantityRequired {
    return Intl.message(
      'Qtà richiesta',
      name: 'resourceQuantityRequired',
      desc: '',
      args: [],
    );
  }

  /// `Elenco Prenotazioni`
  String get bookingsListTitle {
    return Intl.message(
      'Elenco Prenotazioni',
      name: 'bookingsListTitle',
      desc: '',
      args: [],
    );
  }

  /// `Nessuna prenotazione trovata`
  String get bookingsListEmpty {
    return Intl.message(
      'Nessuna prenotazione trovata',
      name: 'bookingsListEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Prova a modificare i filtri di ricerca`
  String get bookingsListEmptyHint {
    return Intl.message(
      'Prova a modificare i filtri di ricerca',
      name: 'bookingsListEmptyHint',
      desc: '',
      args: [],
    );
  }

  /// `Filtri`
  String get bookingsListFilterTitle {
    return Intl.message(
      'Filtri',
      name: 'bookingsListFilterTitle',
      desc: '',
      args: [],
    );
  }

  /// `Sede`
  String get bookingsListFilterLocation {
    return Intl.message(
      'Sede',
      name: 'bookingsListFilterLocation',
      desc: '',
      args: [],
    );
  }

  /// `Operatore`
  String get bookingsListFilterStaff {
    return Intl.message(
      'Operatore',
      name: 'bookingsListFilterStaff',
      desc: '',
      args: [],
    );
  }

  /// `Servizio`
  String get bookingsListFilterService {
    return Intl.message(
      'Servizio',
      name: 'bookingsListFilterService',
      desc: '',
      args: [],
    );
  }

  /// `Cerca cliente`
  String get bookingsListFilterClient {
    return Intl.message(
      'Cerca cliente',
      name: 'bookingsListFilterClient',
      desc: '',
      args: [],
    );
  }

  /// `Nome, email o telefono`
  String get bookingsListFilterClientHint {
    return Intl.message(
      'Nome, email o telefono',
      name: 'bookingsListFilterClientHint',
      desc: '',
      args: [],
    );
  }

  /// `Stato`
  String get bookingsListFilterStatus {
    return Intl.message(
      'Stato',
      name: 'bookingsListFilterStatus',
      desc: '',
      args: [],
    );
  }

  /// `Periodo`
  String get bookingsListFilterPeriod {
    return Intl.message(
      'Periodo',
      name: 'bookingsListFilterPeriod',
      desc: '',
      args: [],
    );
  }

  /// `Includi passati`
  String get bookingsListFilterIncludePast {
    return Intl.message(
      'Includi passati',
      name: 'bookingsListFilterIncludePast',
      desc: '',
      args: [],
    );
  }

  /// `Solo futuri`
  String get bookingsListFilterFutureOnly {
    return Intl.message(
      'Solo futuri',
      name: 'bookingsListFilterFutureOnly',
      desc: '',
      args: [],
    );
  }

  /// `Data appuntamento`
  String get bookingsListSortByAppointment {
    return Intl.message(
      'Data appuntamento',
      name: 'bookingsListSortByAppointment',
      desc: '',
      args: [],
    );
  }

  /// `Data creazione`
  String get bookingsListSortByCreated {
    return Intl.message(
      'Data creazione',
      name: 'bookingsListSortByCreated',
      desc: '',
      args: [],
    );
  }

  /// `Crescente`
  String get bookingsListSortAsc {
    return Intl.message(
      'Crescente',
      name: 'bookingsListSortAsc',
      desc: '',
      args: [],
    );
  }

  /// `Decrescente`
  String get bookingsListSortDesc {
    return Intl.message(
      'Decrescente',
      name: 'bookingsListSortDesc',
      desc: '',
      args: [],
    );
  }

  /// `Data/Ora`
  String get bookingsListColumnDateTime {
    return Intl.message(
      'Data/Ora',
      name: 'bookingsListColumnDateTime',
      desc: '',
      args: [],
    );
  }

  /// `Creato il`
  String get bookingsListColumnCreatedAt {
    return Intl.message(
      'Creato il',
      name: 'bookingsListColumnCreatedAt',
      desc: '',
      args: [],
    );
  }

  /// `Creato da`
  String get bookingsListColumnCreatedBy {
    return Intl.message(
      'Creato da',
      name: 'bookingsListColumnCreatedBy',
      desc: '',
      args: [],
    );
  }

  /// `Cliente`
  String get bookingsListColumnClient {
    return Intl.message(
      'Cliente',
      name: 'bookingsListColumnClient',
      desc: '',
      args: [],
    );
  }

  /// `Servizi`
  String get bookingsListColumnServices {
    return Intl.message(
      'Servizi',
      name: 'bookingsListColumnServices',
      desc: '',
      args: [],
    );
  }

  /// `Operatore`
  String get bookingsListColumnStaff {
    return Intl.message(
      'Operatore',
      name: 'bookingsListColumnStaff',
      desc: '',
      args: [],
    );
  }

  /// `Stato`
  String get bookingsListColumnStatus {
    return Intl.message(
      'Stato',
      name: 'bookingsListColumnStatus',
      desc: '',
      args: [],
    );
  }

  /// `Prezzo`
  String get bookingsListColumnPrice {
    return Intl.message(
      'Prezzo',
      name: 'bookingsListColumnPrice',
      desc: '',
      args: [],
    );
  }

  /// `Azioni`
  String get bookingsListColumnActions {
    return Intl.message(
      'Azioni',
      name: 'bookingsListColumnActions',
      desc: '',
      args: [],
    );
  }

  /// `Modifica`
  String get bookingsListActionEdit {
    return Intl.message(
      'Modifica',
      name: 'bookingsListActionEdit',
      desc: '',
      args: [],
    );
  }

  /// `Cancella`
  String get bookingsListActionCancel {
    return Intl.message(
      'Cancella',
      name: 'bookingsListActionCancel',
      desc: '',
      args: [],
    );
  }

  /// `Dettagli`
  String get bookingsListActionView {
    return Intl.message(
      'Dettagli',
      name: 'bookingsListActionView',
      desc: '',
      args: [],
    );
  }

  /// `Confermato`
  String get bookingsListStatusConfirmed {
    return Intl.message(
      'Confermato',
      name: 'bookingsListStatusConfirmed',
      desc: '',
      args: [],
    );
  }

  /// `Cancellato`
  String get bookingsListStatusCancelled {
    return Intl.message(
      'Cancellato',
      name: 'bookingsListStatusCancelled',
      desc: '',
      args: [],
    );
  }

  /// `Completato`
  String get bookingsListStatusCompleted {
    return Intl.message(
      'Completato',
      name: 'bookingsListStatusCompleted',
      desc: '',
      args: [],
    );
  }

  /// `No show`
  String get bookingsListStatusNoShow {
    return Intl.message(
      'No show',
      name: 'bookingsListStatusNoShow',
      desc: '',
      args: [],
    );
  }

  /// `In attesa`
  String get bookingsListStatusPending {
    return Intl.message(
      'In attesa',
      name: 'bookingsListStatusPending',
      desc: '',
      args: [],
    );
  }

  /// `Online`
  String get bookingsListSourceOnline {
    return Intl.message(
      'Online',
      name: 'bookingsListSourceOnline',
      desc: '',
      args: [],
    );
  }

  /// `Telefono`
  String get bookingsListSourcePhone {
    return Intl.message(
      'Telefono',
      name: 'bookingsListSourcePhone',
      desc: '',
      args: [],
    );
  }

  /// `Walk-in`
  String get bookingsListSourceWalkIn {
    return Intl.message(
      'Walk-in',
      name: 'bookingsListSourceWalkIn',
      desc: '',
      args: [],
    );
  }

  /// `Gestionale`
  String get bookingsListSourceInternal {
    return Intl.message(
      'Gestionale',
      name: 'bookingsListSourceInternal',
      desc: '',
      args: [],
    );
  }

  /// `{count} prenotazioni`
  String bookingsListTotalCount(int count) {
    return Intl.message(
      '$count prenotazioni',
      name: 'bookingsListTotalCount',
      desc: '',
      args: [count],
    );
  }

  /// `Carica altre`
  String get bookingsListLoadMore {
    return Intl.message(
      'Carica altre',
      name: 'bookingsListLoadMore',
      desc: '',
      args: [],
    );
  }

  /// `Reset filtri`
  String get bookingsListResetFilters {
    return Intl.message(
      'Reset filtri',
      name: 'bookingsListResetFilters',
      desc: '',
      args: [],
    );
  }

  /// `Tutte le sedi`
  String get bookingsListAllLocations {
    return Intl.message(
      'Tutte le sedi',
      name: 'bookingsListAllLocations',
      desc: '',
      args: [],
    );
  }

  /// `Tutti gli operatori`
  String get bookingsListAllStaff {
    return Intl.message(
      'Tutti gli operatori',
      name: 'bookingsListAllStaff',
      desc: '',
      args: [],
    );
  }

  /// `Tutti i servizi`
  String get bookingsListAllServices {
    return Intl.message(
      'Tutti i servizi',
      name: 'bookingsListAllServices',
      desc: '',
      args: [],
    );
  }

  /// `Tutti gli stati`
  String get bookingsListAllStatus {
    return Intl.message(
      'Tutti gli stati',
      name: 'bookingsListAllStatus',
      desc: '',
      args: [],
    );
  }

  /// `Cancellare prenotazione?`
  String get bookingsListCancelConfirmTitle {
    return Intl.message(
      'Cancellare prenotazione?',
      name: 'bookingsListCancelConfirmTitle',
      desc: '',
      args: [],
    );
  }

  /// `Questa azione non può essere annullata.`
  String get bookingsListCancelConfirmMessage {
    return Intl.message(
      'Questa azione non può essere annullata.',
      name: 'bookingsListCancelConfirmMessage',
      desc: '',
      args: [],
    );
  }

  /// `Prenotazione cancellata`
  String get bookingsListCancelSuccess {
    return Intl.message(
      'Prenotazione cancellata',
      name: 'bookingsListCancelSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Caricamento...`
  String get bookingsListLoading {
    return Intl.message(
      'Caricamento...',
      name: 'bookingsListLoading',
      desc: '',
      args: [],
    );
  }

  /// `Nessun cliente`
  String get bookingsListNoClient {
    return Intl.message(
      'Nessun cliente',
      name: 'bookingsListNoClient',
      desc: '',
      args: [],
    );
  }

  /// `Gestisci i servizi offerti, categorie e listini`
  String get moreServicesDescription {
    return Intl.message(
      'Gestisci i servizi offerti, categorie e listini',
      name: 'moreServicesDescription',
      desc: '',
      args: [],
    );
  }

  /// `Gestisci operatori, sedi e orari di lavoro`
  String get moreTeamDescription {
    return Intl.message(
      'Gestisci operatori, sedi e orari di lavoro',
      name: 'moreTeamDescription',
      desc: '',
      args: [],
    );
  }

  /// `Visualizza statistiche e andamento attività`
  String get moreReportsDescription {
    return Intl.message(
      'Visualizza statistiche e andamento attività',
      name: 'moreReportsDescription',
      desc: '',
      args: [],
    );
  }

  /// `Consulta lo storico delle prenotazioni`
  String get moreBookingsDescription {
    return Intl.message(
      'Consulta lo storico delle prenotazioni',
      name: 'moreBookingsDescription',
      desc: '',
      args: [],
    );
  }

  /// `Visualizza lo storico delle notifiche prenotazioni`
  String get moreBookingNotificationsDescription {
    return Intl.message(
      'Visualizza lo storico delle notifiche prenotazioni',
      name: 'moreBookingNotificationsDescription',
      desc: '',
      args: [],
    );
  }

  /// `Gestisci i tuoi dati personali e le credenziali`
  String get moreProfileDescription {
    return Intl.message(
      'Gestisci i tuoi dati personali e le credenziali',
      name: 'moreProfileDescription',
      desc: '',
      args: [],
    );
  }

  /// `Passa a un altro business`
  String get moreSwitchBusinessDescription {
    return Intl.message(
      'Passa a un altro business',
      name: 'moreSwitchBusinessDescription',
      desc: '',
      args: [],
    );
  }

  /// `Notifiche Prenotazioni`
  String get bookingNotificationsTitle {
    return Intl.message(
      'Notifiche Prenotazioni',
      name: 'bookingNotificationsTitle',
      desc: '',
      args: [],
    );
  }

  /// `{count} notifiche`
  String bookingNotificationsTotalCount(int count) {
    return Intl.message(
      '$count notifiche',
      name: 'bookingNotificationsTotalCount',
      desc: '',
      args: [count],
    );
  }

  /// `Nessuna notifica trovata`
  String get bookingNotificationsEmpty {
    return Intl.message(
      'Nessuna notifica trovata',
      name: 'bookingNotificationsEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Prova a modificare i filtri di ricerca`
  String get bookingNotificationsEmptyHint {
    return Intl.message(
      'Prova a modificare i filtri di ricerca',
      name: 'bookingNotificationsEmptyHint',
      desc: '',
      args: [],
    );
  }

  /// `Carica altre`
  String get bookingNotificationsLoadMore {
    return Intl.message(
      'Carica altre',
      name: 'bookingNotificationsLoadMore',
      desc: '',
      args: [],
    );
  }

  /// `Cerca`
  String get bookingNotificationsSearchLabel {
    return Intl.message(
      'Cerca',
      name: 'bookingNotificationsSearchLabel',
      desc: '',
      args: [],
    );
  }

  /// `Cliente, destinatario, oggetto`
  String get bookingNotificationsSearchHint {
    return Intl.message(
      'Cliente, destinatario, oggetto',
      name: 'bookingNotificationsSearchHint',
      desc: '',
      args: [],
    );
  }

  /// `Stato`
  String get bookingNotificationsFilterStatus {
    return Intl.message(
      'Stato',
      name: 'bookingNotificationsFilterStatus',
      desc: '',
      args: [],
    );
  }

  /// `Tipo`
  String get bookingNotificationsFilterType {
    return Intl.message(
      'Tipo',
      name: 'bookingNotificationsFilterType',
      desc: '',
      args: [],
    );
  }

  /// `Tutti gli stati`
  String get bookingNotificationsStatusAll {
    return Intl.message(
      'Tutti gli stati',
      name: 'bookingNotificationsStatusAll',
      desc: '',
      args: [],
    );
  }

  /// `In coda`
  String get bookingNotificationsStatusPending {
    return Intl.message(
      'In coda',
      name: 'bookingNotificationsStatusPending',
      desc: '',
      args: [],
    );
  }

  /// `In elaborazione`
  String get bookingNotificationsStatusProcessing {
    return Intl.message(
      'In elaborazione',
      name: 'bookingNotificationsStatusProcessing',
      desc: '',
      args: [],
    );
  }

  /// `Inviata`
  String get bookingNotificationsStatusSent {
    return Intl.message(
      'Inviata',
      name: 'bookingNotificationsStatusSent',
      desc: '',
      args: [],
    );
  }

  /// `Fallita`
  String get bookingNotificationsStatusFailed {
    return Intl.message(
      'Fallita',
      name: 'bookingNotificationsStatusFailed',
      desc: '',
      args: [],
    );
  }

  /// `Tutti i tipi`
  String get bookingNotificationsTypeAll {
    return Intl.message(
      'Tutti i tipi',
      name: 'bookingNotificationsTypeAll',
      desc: '',
      args: [],
    );
  }

  /// `Prenotazione creata`
  String get bookingNotificationsChannelConfirmed {
    return Intl.message(
      'Prenotazione creata',
      name: 'bookingNotificationsChannelConfirmed',
      desc: '',
      args: [],
    );
  }

  /// `Prenotazione riprogrammata`
  String get bookingNotificationsChannelRescheduled {
    return Intl.message(
      'Prenotazione riprogrammata',
      name: 'bookingNotificationsChannelRescheduled',
      desc: '',
      args: [],
    );
  }

  /// `Prenotazione annullata`
  String get bookingNotificationsChannelCancelled {
    return Intl.message(
      'Prenotazione annullata',
      name: 'bookingNotificationsChannelCancelled',
      desc: '',
      args: [],
    );
  }

  /// `Promemoria prenotazione`
  String get bookingNotificationsChannelReminder {
    return Intl.message(
      'Promemoria prenotazione',
      name: 'bookingNotificationsChannelReminder',
      desc: '',
      args: [],
    );
  }

  /// `Tipo`
  String get bookingNotificationsFieldType {
    return Intl.message(
      'Tipo',
      name: 'bookingNotificationsFieldType',
      desc: '',
      args: [],
    );
  }

  /// `Cliente`
  String get bookingNotificationsFieldClient {
    return Intl.message(
      'Cliente',
      name: 'bookingNotificationsFieldClient',
      desc: '',
      args: [],
    );
  }

  /// `Sede`
  String get bookingNotificationsFieldLocation {
    return Intl.message(
      'Sede',
      name: 'bookingNotificationsFieldLocation',
      desc: '',
      args: [],
    );
  }

  /// `Appuntamento`
  String get bookingNotificationsFieldAppointment {
    return Intl.message(
      'Appuntamento',
      name: 'bookingNotificationsFieldAppointment',
      desc: '',
      args: [],
    );
  }

  /// `Destinatario`
  String get bookingNotificationsFieldRecipient {
    return Intl.message(
      'Destinatario',
      name: 'bookingNotificationsFieldRecipient',
      desc: '',
      args: [],
    );
  }

  /// `Creata il`
  String get bookingNotificationsFieldCreatedAt {
    return Intl.message(
      'Creata il',
      name: 'bookingNotificationsFieldCreatedAt',
      desc: '',
      args: [],
    );
  }

  /// `Inviata il`
  String get bookingNotificationsFieldSentAt {
    return Intl.message(
      'Inviata il',
      name: 'bookingNotificationsFieldSentAt',
      desc: '',
      args: [],
    );
  }

  /// `Errore`
  String get bookingNotificationsFieldError {
    return Intl.message(
      'Errore',
      name: 'bookingNotificationsFieldError',
      desc: '',
      args: [],
    );
  }

  /// `Nessun oggetto`
  String get bookingNotificationsNoSubject {
    return Intl.message(
      'Nessun oggetto',
      name: 'bookingNotificationsNoSubject',
      desc: '',
      args: [],
    );
  }

  /// `N/D`
  String get bookingNotificationsNotAvailable {
    return Intl.message(
      'N/D',
      name: 'bookingNotificationsNotAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Email Notifiche Prenotazioni Online`
  String get businessOnlineBookingsNotificationEmailLabel {
    return Intl.message(
      'Email Notifiche Prenotazioni Online',
      name: 'businessOnlineBookingsNotificationEmailLabel',
      desc: '',
      args: [],
    );
  }

  /// `es. prenotazioni@salone.it`
  String get businessOnlineBookingsNotificationEmailHint {
    return Intl.message(
      'es. prenotazioni@salone.it',
      name: 'businessOnlineBookingsNotificationEmailHint',
      desc: '',
      args: [],
    );
  }

  /// `Riceve notifiche solo per prenotazioni eseguite dal cliente`
  String get businessOnlineBookingsNotificationEmailHelper {
    return Intl.message(
      'Riceve notifiche solo per prenotazioni eseguite dal cliente',
      name: 'businessOnlineBookingsNotificationEmailHelper',
      desc: '',
      args: [],
    );
  }

  /// `Accedi alle altre funzionalità dell'applicazione`
  String get moreSubtitle {
    return Intl.message(
      'Accedi alle altre funzionalità dell\'applicazione',
      name: 'moreSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Date di chiusura`
  String get closuresTitle {
    return Intl.message(
      'Date di chiusura',
      name: 'closuresTitle',
      desc: '',
      args: [],
    );
  }

  /// `A partire da oggi`
  String get closuresFilterFromToday {
    return Intl.message(
      'A partire da oggi',
      name: 'closuresFilterFromToday',
      desc: '',
      args: [],
    );
  }

  /// `Tutti`
  String get closuresFilterAll {
    return Intl.message('Tutti', name: 'closuresFilterAll', desc: '', args: []);
  }

  /// `Nessuna chiusura programmata`
  String get closuresEmpty {
    return Intl.message(
      'Nessuna chiusura programmata',
      name: 'closuresEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Nessuna chiusura programmata per il periodo selezionato`
  String get closuresEmptyForPeriod {
    return Intl.message(
      'Nessuna chiusura programmata per il periodo selezionato',
      name: 'closuresEmptyForPeriod',
      desc: '',
      args: [],
    );
  }

  /// `Aggiungi i periodi di chiusura dell'attività (es. festività, ferie)`
  String get closuresEmptyHint {
    return Intl.message(
      'Aggiungi i periodi di chiusura dell\'attività (es. festività, ferie)',
      name: 'closuresEmptyHint',
      desc: '',
      args: [],
    );
  }

  /// `Prossime chiusure`
  String get closuresUpcoming {
    return Intl.message(
      'Prossime chiusure',
      name: 'closuresUpcoming',
      desc: '',
      args: [],
    );
  }

  /// `Chiusure precedenti`
  String get closuresPast {
    return Intl.message(
      'Chiusure precedenti',
      name: 'closuresPast',
      desc: '',
      args: [],
    );
  }

  /// `per un totale di {count, plural, =1{1 giorno} other{{count} giorni}}`
  String closuresTotalDays(int count) {
    return Intl.message(
      'per un totale di ${Intl.plural(count, one: '1 giorno', other: '$count giorni')}',
      name: 'closuresTotalDays',
      desc: '',
      args: [count],
    );
  }

  /// `Nuova chiusura`
  String get closuresNewTitle {
    return Intl.message(
      'Nuova chiusura',
      name: 'closuresNewTitle',
      desc: '',
      args: [],
    );
  }

  /// `Modifica chiusura`
  String get closuresEditTitle {
    return Intl.message(
      'Modifica chiusura',
      name: 'closuresEditTitle',
      desc: '',
      args: [],
    );
  }

  /// `Data inizio`
  String get closuresStartDate {
    return Intl.message(
      'Data inizio',
      name: 'closuresStartDate',
      desc: '',
      args: [],
    );
  }

  /// `Data fine`
  String get closuresEndDate {
    return Intl.message(
      'Data fine',
      name: 'closuresEndDate',
      desc: '',
      args: [],
    );
  }

  /// `Motivo (opzionale)`
  String get closuresReason {
    return Intl.message(
      'Motivo (opzionale)',
      name: 'closuresReason',
      desc: '',
      args: [],
    );
  }

  /// `es. Festività, Ferie estive, Manutenzione...`
  String get closuresReasonHint {
    return Intl.message(
      'es. Festività, Ferie estive, Manutenzione...',
      name: 'closuresReasonHint',
      desc: '',
      args: [],
    );
  }

  /// `Eliminare questa chiusura?`
  String get closuresDeleteConfirm {
    return Intl.message(
      'Eliminare questa chiusura?',
      name: 'closuresDeleteConfirm',
      desc: '',
      args: [],
    );
  }

  /// `Gli slot di prenotazione in questo periodo torneranno disponibili.`
  String get closuresDeleteConfirmMessage {
    return Intl.message(
      'Gli slot di prenotazione in questo periodo torneranno disponibili.',
      name: 'closuresDeleteConfirmMessage',
      desc: '',
      args: [],
    );
  }

  /// `Le date si sovrappongono con un'altra chiusura esistente`
  String get closuresOverlapError {
    return Intl.message(
      'Le date si sovrappongono con un\'altra chiusura esistente',
      name: 'closuresOverlapError',
      desc: '',
      args: [],
    );
  }

  /// `La data di fine deve essere uguale o successiva alla data di inizio`
  String get closuresInvalidDateRange {
    return Intl.message(
      'La data di fine deve essere uguale o successiva alla data di inizio',
      name: 'closuresInvalidDateRange',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, =1{1 giorno} other{{count} giorni}}`
  String closuresDays(int count) {
    return Intl.plural(
      count,
      one: '1 giorno',
      other: '$count giorni',
      name: 'closuresDays',
      desc: '',
      args: [count],
    );
  }

  /// `Giorno singolo`
  String get closuresSingleDay {
    return Intl.message(
      'Giorno singolo',
      name: 'closuresSingleDay',
      desc: '',
      args: [],
    );
  }

  /// `Periodo`
  String get closuresDateRange {
    return Intl.message(
      'Periodo',
      name: 'closuresDateRange',
      desc: '',
      args: [],
    );
  }

  /// `Chiusura aggiunta`
  String get closuresAddSuccess {
    return Intl.message(
      'Chiusura aggiunta',
      name: 'closuresAddSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Chiusura aggiornata`
  String get closuresUpdateSuccess {
    return Intl.message(
      'Chiusura aggiornata',
      name: 'closuresUpdateSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Chiusura eliminata`
  String get closuresDeleteSuccess {
    return Intl.message(
      'Chiusura eliminata',
      name: 'closuresDeleteSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Sedi interessate`
  String get closuresLocations {
    return Intl.message(
      'Sedi interessate',
      name: 'closuresLocations',
      desc: '',
      args: [],
    );
  }

  /// `Seleziona tutte`
  String get closuresSelectAll {
    return Intl.message(
      'Seleziona tutte',
      name: 'closuresSelectAll',
      desc: '',
      args: [],
    );
  }

  /// `Deseleziona tutte`
  String get closuresDeselectAll {
    return Intl.message(
      'Deseleziona tutte',
      name: 'closuresDeselectAll',
      desc: '',
      args: [],
    );
  }

  /// `Seleziona almeno una sede`
  String get closuresSelectAtLeastOneLocation {
    return Intl.message(
      'Seleziona almeno una sede',
      name: 'closuresSelectAtLeastOneLocation',
      desc: '',
      args: [],
    );
  }

  /// `Nessuna sede configurata`
  String get closuresNoLocations {
    return Intl.message(
      'Nessuna sede configurata',
      name: 'closuresNoLocations',
      desc: '',
      args: [],
    );
  }

  /// `Tutte le sedi`
  String get closuresAllLocations {
    return Intl.message(
      'Tutte le sedi',
      name: 'closuresAllLocations',
      desc: '',
      args: [],
    );
  }

  /// `Aggiungi chiusura`
  String get closuresAddButton {
    return Intl.message(
      'Aggiungi chiusura',
      name: 'closuresAddButton',
      desc: '',
      args: [],
    );
  }

  /// `Importa festività`
  String get closuresImportHolidays {
    return Intl.message(
      'Importa festività',
      name: 'closuresImportHolidays',
      desc: '',
      args: [],
    );
  }

  /// `Importa festività nazionali`
  String get closuresImportHolidaysTitle {
    return Intl.message(
      'Importa festività nazionali',
      name: 'closuresImportHolidaysTitle',
      desc: '',
      args: [],
    );
  }

  /// `Anno:`
  String get closuresImportHolidaysYear {
    return Intl.message(
      'Anno:',
      name: 'closuresImportHolidaysYear',
      desc: '',
      args: [],
    );
  }

  /// `Applica alle sedi:`
  String get closuresImportHolidaysLocations {
    return Intl.message(
      'Applica alle sedi:',
      name: 'closuresImportHolidaysLocations',
      desc: '',
      args: [],
    );
  }

  /// `Seleziona le festività da importare:`
  String get closuresImportHolidaysList {
    return Intl.message(
      'Seleziona le festività da importare:',
      name: 'closuresImportHolidaysList',
      desc: '',
      args: [],
    );
  }

  /// `Importa {count, plural, =1{1 festività} other{{count} festività}}`
  String closuresImportHolidaysAction(int count) {
    return Intl.message(
      'Importa ${Intl.plural(count, one: '1 festività', other: '$count festività')}',
      name: 'closuresImportHolidaysAction',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, =1{1 festività importata} other{{count} festività importate}}`
  String closuresImportHolidaysSuccess(int count) {
    return Intl.plural(
      count,
      one: '1 festività importata',
      other: '$count festività importate',
      name: 'closuresImportHolidaysSuccess',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, =1{1 festività già presente} other{{count} festività già presenti}} (contrassegnate con ✓)`
  String closuresImportHolidaysAlreadyAdded(int count) {
    return Intl.message(
      '${Intl.plural(count, one: '1 festività già presente', other: '$count festività già presenti')} (contrassegnate con ✓)',
      name: 'closuresImportHolidaysAlreadyAdded',
      desc: '',
      args: [count],
    );
  }

  /// `Le festività automatiche non sono disponibili per il paese configurato nella sede.`
  String get closuresImportHolidaysUnsupportedCountry {
    return Intl.message(
      'Le festività automatiche non sono disponibili per il paese configurato nella sede.',
      name: 'closuresImportHolidaysUnsupportedCountry',
      desc: '',
      args: [],
    );
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
