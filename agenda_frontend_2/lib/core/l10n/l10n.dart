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

  /// `Prenota Online`
  String get appTitle {
    return Intl.message('Prenota Online', name: 'appTitle', desc: '', args: []);
  }

  /// `Indietro`
  String get actionBack {
    return Intl.message('Indietro', name: 'actionBack', desc: '', args: []);
  }

  /// `Avanti`
  String get actionNext {
    return Intl.message('Avanti', name: 'actionNext', desc: '', args: []);
  }

  /// `Conferma`
  String get actionConfirm {
    return Intl.message('Conferma', name: 'actionConfirm', desc: '', args: []);
  }

  /// `Annulla`
  String get actionCancel {
    return Intl.message('Annulla', name: 'actionCancel', desc: '', args: []);
  }

  /// `Chiudi`
  String get actionClose {
    return Intl.message('Chiudi', name: 'actionClose', desc: '', args: []);
  }

  /// `Riprova`
  String get actionRetry {
    return Intl.message('Riprova', name: 'actionRetry', desc: '', args: []);
  }

  /// `Accedi`
  String get actionLogin {
    return Intl.message('Accedi', name: 'actionLogin', desc: '', args: []);
  }

  /// `Registrati`
  String get actionRegister {
    return Intl.message(
      'Registrati',
      name: 'actionRegister',
      desc: '',
      args: [],
    );
  }

  /// `Esci`
  String get actionLogout {
    return Intl.message('Esci', name: 'actionLogout', desc: '', args: []);
  }

  /// `Errore`
  String get errorTitle {
    return Intl.message('Errore', name: 'errorTitle', desc: '', args: []);
  }

  /// `Si è verificato un errore`
  String get errorGeneric {
    return Intl.message(
      'Si è verificato un errore',
      name: 'errorGeneric',
      desc: '',
      args: [],
    );
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

  /// `Nessuna disponibilità per la data selezionata`
  String get errorNoAvailability {
    return Intl.message(
      'Nessuna disponibilità per la data selezionata',
      name: 'errorNoAvailability',
      desc: '',
      args: [],
    );
  }

  /// `Errore nel caricamento dei servizi`
  String get errorLoadingServices {
    return Intl.message(
      'Errore nel caricamento dei servizi',
      name: 'errorLoadingServices',
      desc: '',
      args: [],
    );
  }

  /// `Errore nel caricamento degli operatori`
  String get errorLoadingStaff {
    return Intl.message(
      'Errore nel caricamento degli operatori',
      name: 'errorLoadingStaff',
      desc: '',
      args: [],
    );
  }

  /// `Errore nel caricamento delle disponibilità`
  String get errorLoadingAvailability {
    return Intl.message(
      'Errore nel caricamento delle disponibilità',
      name: 'errorLoadingAvailability',
      desc: '',
      args: [],
    );
  }

  /// `Benvenuto`
  String get authWelcome {
    return Intl.message('Benvenuto', name: 'authWelcome', desc: '', args: []);
  }

  /// `Accedi al tuo account`
  String get authLoginTitle {
    return Intl.message(
      'Accedi al tuo account',
      name: 'authLoginTitle',
      desc: '',
      args: [],
    );
  }

  /// `Crea un nuovo account`
  String get authRegisterTitle {
    return Intl.message(
      'Crea un nuovo account',
      name: 'authRegisterTitle',
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

  /// `Conferma password`
  String get authConfirmPassword {
    return Intl.message(
      'Conferma password',
      name: 'authConfirmPassword',
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

  /// `Password dimenticata?`
  String get authForgotPassword {
    return Intl.message(
      'Password dimenticata?',
      name: 'authForgotPassword',
      desc: '',
      args: [],
    );
  }

  /// `Non hai un account?`
  String get authNoAccount {
    return Intl.message(
      'Non hai un account?',
      name: 'authNoAccount',
      desc: '',
      args: [],
    );
  }

  /// `Hai già un account?`
  String get authHaveAccount {
    return Intl.message(
      'Hai già un account?',
      name: 'authHaveAccount',
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

  /// `Password troppo corta (min. 6 caratteri)`
  String get authInvalidPassword {
    return Intl.message(
      'Password troppo corta (min. 6 caratteri)',
      name: 'authInvalidPassword',
      desc: '',
      args: [],
    );
  }

  /// `Le password non coincidono`
  String get authPasswordMismatch {
    return Intl.message(
      'Le password non coincidono',
      name: 'authPasswordMismatch',
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

  /// `Numero di telefono non valido`
  String get authInvalidPhone {
    return Intl.message(
      'Numero di telefono non valido',
      name: 'authInvalidPhone',
      desc: '',
      args: [],
    );
  }

  /// `Accesso effettuato`
  String get authLoginSuccess {
    return Intl.message(
      'Accesso effettuato',
      name: 'authLoginSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Registrazione completata`
  String get authRegisterSuccess {
    return Intl.message(
      'Registrazione completata',
      name: 'authRegisterSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Credenziali non valide`
  String get authLoginFailed {
    return Intl.message(
      'Credenziali non valide',
      name: 'authLoginFailed',
      desc: '',
      args: [],
    );
  }

  /// `Registrazione fallita`
  String get authRegisterFailed {
    return Intl.message(
      'Registrazione fallita',
      name: 'authRegisterFailed',
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

  /// `Inserisci la tua email e ti invieremo le istruzioni per reimpostare la password.`
  String get authResetPasswordMessage {
    return Intl.message(
      'Inserisci la tua email e ti invieremo le istruzioni per reimpostare la password.',
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

  /// `Email inviata! Controlla la tua casella di posta.`
  String get authResetPasswordSuccess {
    return Intl.message(
      'Email inviata! Controlla la tua casella di posta.',
      name: 'authResetPasswordSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Errore durante l'invio. Riprova.`
  String get authResetPasswordError {
    return Intl.message(
      'Errore durante l\'invio. Riprova.',
      name: 'authResetPasswordError',
      desc: '',
      args: [],
    );
  }

  /// `Prenota appuntamento`
  String get bookingTitle {
    return Intl.message(
      'Prenota appuntamento',
      name: 'bookingTitle',
      desc: '',
      args: [],
    );
  }

  /// `Servizi`
  String get bookingStepServices {
    return Intl.message(
      'Servizi',
      name: 'bookingStepServices',
      desc: '',
      args: [],
    );
  }

  /// `Operatore`
  String get bookingStepStaff {
    return Intl.message(
      'Operatore',
      name: 'bookingStepStaff',
      desc: '',
      args: [],
    );
  }

  /// `Data e ora`
  String get bookingStepDateTime {
    return Intl.message(
      'Data e ora',
      name: 'bookingStepDateTime',
      desc: '',
      args: [],
    );
  }

  /// `Riepilogo`
  String get bookingStepSummary {
    return Intl.message(
      'Riepilogo',
      name: 'bookingStepSummary',
      desc: '',
      args: [],
    );
  }

  /// `Scegli i servizi`
  String get servicesTitle {
    return Intl.message(
      'Scegli i servizi',
      name: 'servicesTitle',
      desc: '',
      args: [],
    );
  }

  /// `Puoi selezionare uno o più servizi`
  String get servicesSubtitle {
    return Intl.message(
      'Puoi selezionare uno o più servizi',
      name: 'servicesSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, =0{Nessun servizio selezionato} =1{1 servizio selezionato} other{{count} servizi selezionati}}`
  String servicesSelected(int count) {
    return Intl.plural(
      count,
      zero: 'Nessun servizio selezionato',
      one: '1 servizio selezionato',
      other: '$count servizi selezionati',
      name: 'servicesSelected',
      desc: '',
      args: [count],
    );
  }

  /// `Totale: {total}`
  String servicesTotal(String total) {
    return Intl.message(
      'Totale: $total',
      name: 'servicesTotal',
      desc: '',
      args: [total],
    );
  }

  /// `{duration} min`
  String servicesDuration(int duration) {
    return Intl.message(
      '$duration min',
      name: 'servicesDuration',
      desc: '',
      args: [duration],
    );
  }

  /// `Gratis`
  String get servicesFree {
    return Intl.message('Gratis', name: 'servicesFree', desc: '', args: []);
  }

  /// `da {price}`
  String servicesPriceFrom(String price) {
    return Intl.message(
      'da $price',
      name: 'servicesPriceFrom',
      desc: '',
      args: [price],
    );
  }

  /// `Scegli l'operatore`
  String get staffTitle {
    return Intl.message(
      'Scegli l\'operatore',
      name: 'staffTitle',
      desc: '',
      args: [],
    );
  }

  /// `Seleziona con chi desideri essere servito`
  String get staffSubtitle {
    return Intl.message(
      'Seleziona con chi desideri essere servito',
      name: 'staffSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Qualsiasi operatore disponibile`
  String get staffAnyOperator {
    return Intl.message(
      'Qualsiasi operatore disponibile',
      name: 'staffAnyOperator',
      desc: '',
      args: [],
    );
  }

  /// `Ti assegneremo il primo operatore libero`
  String get staffAnyOperatorSubtitle {
    return Intl.message(
      'Ti assegneremo il primo operatore libero',
      name: 'staffAnyOperatorSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Scegli data e ora`
  String get dateTimeTitle {
    return Intl.message(
      'Scegli data e ora',
      name: 'dateTimeTitle',
      desc: '',
      args: [],
    );
  }

  /// `Seleziona quando desideri prenotare`
  String get dateTimeSubtitle {
    return Intl.message(
      'Seleziona quando desideri prenotare',
      name: 'dateTimeSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Prima disponibilità: {date}`
  String dateTimeFirstAvailable(String date) {
    return Intl.message(
      'Prima disponibilità: $date',
      name: 'dateTimeFirstAvailable',
      desc: '',
      args: [date],
    );
  }

  /// `Nessun orario disponibile per questa data`
  String get dateTimeNoSlots {
    return Intl.message(
      'Nessun orario disponibile per questa data',
      name: 'dateTimeNoSlots',
      desc: '',
      args: [],
    );
  }

  /// `Seleziona una data`
  String get dateTimeSelectDate {
    return Intl.message(
      'Seleziona una data',
      name: 'dateTimeSelectDate',
      desc: '',
      args: [],
    );
  }

  /// `Mattina`
  String get dateTimeMorning {
    return Intl.message('Mattina', name: 'dateTimeMorning', desc: '', args: []);
  }

  /// `Pomeriggio`
  String get dateTimeAfternoon {
    return Intl.message(
      'Pomeriggio',
      name: 'dateTimeAfternoon',
      desc: '',
      args: [],
    );
  }

  /// `Sera`
  String get dateTimeEvening {
    return Intl.message('Sera', name: 'dateTimeEvening', desc: '', args: []);
  }

  /// `Riepilogo prenotazione`
  String get summaryTitle {
    return Intl.message(
      'Riepilogo prenotazione',
      name: 'summaryTitle',
      desc: '',
      args: [],
    );
  }

  /// `Controlla i dettagli prima di confermare`
  String get summarySubtitle {
    return Intl.message(
      'Controlla i dettagli prima di confermare',
      name: 'summarySubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Servizi selezionati`
  String get summaryServices {
    return Intl.message(
      'Servizi selezionati',
      name: 'summaryServices',
      desc: '',
      args: [],
    );
  }

  /// `Operatore`
  String get summaryOperator {
    return Intl.message(
      'Operatore',
      name: 'summaryOperator',
      desc: '',
      args: [],
    );
  }

  /// `Data e ora`
  String get summaryDateTime {
    return Intl.message(
      'Data e ora',
      name: 'summaryDateTime',
      desc: '',
      args: [],
    );
  }

  /// `Durata totale`
  String get summaryDuration {
    return Intl.message(
      'Durata totale',
      name: 'summaryDuration',
      desc: '',
      args: [],
    );
  }

  /// `Prezzo totale`
  String get summaryPrice {
    return Intl.message(
      'Prezzo totale',
      name: 'summaryPrice',
      desc: '',
      args: [],
    );
  }

  /// `Note (opzionale)`
  String get summaryNotes {
    return Intl.message(
      'Note (opzionale)',
      name: 'summaryNotes',
      desc: '',
      args: [],
    );
  }

  /// `Aggiungi eventuali note per l'appuntamento...`
  String get summaryNotesHint {
    return Intl.message(
      'Aggiungi eventuali note per l\'appuntamento...',
      name: 'summaryNotesHint',
      desc: '',
      args: [],
    );
  }

  /// `Prenotazione confermata!`
  String get confirmationTitle {
    return Intl.message(
      'Prenotazione confermata!',
      name: 'confirmationTitle',
      desc: '',
      args: [],
    );
  }

  /// `Ti abbiamo inviato un'email di conferma`
  String get confirmationSubtitle {
    return Intl.message(
      'Ti abbiamo inviato un\'email di conferma',
      name: 'confirmationSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Codice prenotazione: {id}`
  String confirmationBookingId(String id) {
    return Intl.message(
      'Codice prenotazione: $id',
      name: 'confirmationBookingId',
      desc: '',
      args: [id],
    );
  }

  /// `Nuova prenotazione`
  String get confirmationNewBooking {
    return Intl.message(
      'Nuova prenotazione',
      name: 'confirmationNewBooking',
      desc: '',
      args: [],
    );
  }

  /// `Torna alla home`
  String get confirmationGoHome {
    return Intl.message(
      'Torna alla home',
      name: 'confirmationGoHome',
      desc: '',
      args: [],
    );
  }

  /// `{minutes} min`
  String durationMinutes(int minutes) {
    return Intl.message(
      '$minutes min',
      name: 'durationMinutes',
      desc: '',
      args: [minutes],
    );
  }

  /// `{minutes} min`
  String durationMinute(int minutes) {
    return Intl.message(
      '$minutes min',
      name: 'durationMinute',
      desc: '',
      args: [minutes],
    );
  }

  /// `{hours} ora`
  String durationHour(int hours) {
    return Intl.message(
      '$hours ora',
      name: 'durationHour',
      desc: '',
      args: [hours],
    );
  }

  /// `{hours} ora {minutes} min`
  String durationHourMinute(int hours, int minutes) {
    return Intl.message(
      '$hours ora $minutes min',
      name: 'durationHourMinute',
      desc: '',
      args: [hours, minutes],
    );
  }

  /// `€{price}`
  String priceFormat(String price) {
    return Intl.message(
      '€$price',
      name: 'priceFormat',
      desc: '',
      args: [price],
    );
  }

  /// `Gennaio`
  String get monthJanuary {
    return Intl.message('Gennaio', name: 'monthJanuary', desc: '', args: []);
  }

  /// `Febbraio`
  String get monthFebruary {
    return Intl.message('Febbraio', name: 'monthFebruary', desc: '', args: []);
  }

  /// `Marzo`
  String get monthMarch {
    return Intl.message('Marzo', name: 'monthMarch', desc: '', args: []);
  }

  /// `Aprile`
  String get monthApril {
    return Intl.message('Aprile', name: 'monthApril', desc: '', args: []);
  }

  /// `Maggio`
  String get monthMay {
    return Intl.message('Maggio', name: 'monthMay', desc: '', args: []);
  }

  /// `Giugno`
  String get monthJune {
    return Intl.message('Giugno', name: 'monthJune', desc: '', args: []);
  }

  /// `Luglio`
  String get monthJuly {
    return Intl.message('Luglio', name: 'monthJuly', desc: '', args: []);
  }

  /// `Agosto`
  String get monthAugust {
    return Intl.message('Agosto', name: 'monthAugust', desc: '', args: []);
  }

  /// `Settembre`
  String get monthSeptember {
    return Intl.message(
      'Settembre',
      name: 'monthSeptember',
      desc: '',
      args: [],
    );
  }

  /// `Ottobre`
  String get monthOctober {
    return Intl.message('Ottobre', name: 'monthOctober', desc: '', args: []);
  }

  /// `Novembre`
  String get monthNovember {
    return Intl.message('Novembre', name: 'monthNovember', desc: '', args: []);
  }

  /// `Dicembre`
  String get monthDecember {
    return Intl.message('Dicembre', name: 'monthDecember', desc: '', args: []);
  }

  /// `Lun`
  String get weekdayMon {
    return Intl.message('Lun', name: 'weekdayMon', desc: '', args: []);
  }

  /// `Mar`
  String get weekdayTue {
    return Intl.message('Mar', name: 'weekdayTue', desc: '', args: []);
  }

  /// `Mer`
  String get weekdayWed {
    return Intl.message('Mer', name: 'weekdayWed', desc: '', args: []);
  }

  /// `Gio`
  String get weekdayThu {
    return Intl.message('Gio', name: 'weekdayThu', desc: '', args: []);
  }

  /// `Ven`
  String get weekdayFri {
    return Intl.message('Ven', name: 'weekdayFri', desc: '', args: []);
  }

  /// `Sab`
  String get weekdaySat {
    return Intl.message('Sab', name: 'weekdaySat', desc: '', args: []);
  }

  /// `Dom`
  String get weekdaySun {
    return Intl.message('Dom', name: 'weekdaySun', desc: '', args: []);
  }

  /// `Campo obbligatorio`
  String get validationRequired {
    return Intl.message(
      'Campo obbligatorio',
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
}

class AppLocalizationDelegate extends LocalizationsDelegate<L10n> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[Locale.fromSubtags(languageCode: 'it')];
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
