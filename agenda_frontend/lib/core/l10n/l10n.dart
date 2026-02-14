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

  /// `Elimina`
  String get actionDelete {
    return Intl.message('Elimina', name: 'actionDelete', desc: '', args: []);
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

  /// `Caricamento...`
  String get loadingGeneric {
    return Intl.message(
      'Caricamento...',
      name: 'loadingGeneric',
      desc: '',
      args: [],
    );
  }

  /// `Sessione scaduta. Effettua nuovamente l'accesso.`
  String get sessionExpired {
    return Intl.message(
      'Sessione scaduta. Effettua nuovamente l\'accesso.',
      name: 'sessionExpired',
      desc: '',
      args: [],
    );
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

  /// `Impossibile caricare i servizi. Verifica la connessione e riprova.`
  String get errorLoadingServices {
    return Intl.message(
      'Impossibile caricare i servizi. Verifica la connessione e riprova.',
      name: 'errorLoadingServices',
      desc: '',
      args: [],
    );
  }

  /// `Impossibile caricare gli operatori. Verifica la connessione e riprova.`
  String get errorLoadingStaff {
    return Intl.message(
      'Impossibile caricare gli operatori. Verifica la connessione e riprova.',
      name: 'errorLoadingStaff',
      desc: '',
      args: [],
    );
  }

  /// `Impossibile caricare le disponibilità. Verifica la connessione e riprova.`
  String get errorLoadingAvailability {
    return Intl.message(
      'Impossibile caricare le disponibilità. Verifica la connessione e riprova.',
      name: 'errorLoadingAvailability',
      desc: '',
      args: [],
    );
  }

  /// `Caricamento disponibilità...`
  String get loadingAvailability {
    return Intl.message(
      'Caricamento disponibilità...',
      name: 'loadingAvailability',
      desc: '',
      args: [],
    );
  }

  /// `Nessun servizio disponibile al momento`
  String get servicesEmpty {
    return Intl.message(
      'Nessun servizio disponibile al momento',
      name: 'servicesEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Non ci sono servizi prenotabili online per questa attività`
  String get servicesEmptySubtitle {
    return Intl.message(
      'Non ci sono servizi prenotabili online per questa attività',
      name: 'servicesEmptySubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Nessun operatore disponibile al momento`
  String get staffEmpty {
    return Intl.message(
      'Nessun operatore disponibile al momento',
      name: 'staffEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Nessun operatore può eseguire tutti i servizi selezionati. Prova a selezionare meno servizi o servizi diversi.`
  String get noStaffForAllServices {
    return Intl.message(
      'Nessun operatore può eseguire tutti i servizi selezionati. Prova a selezionare meno servizi o servizi diversi.',
      name: 'noStaffForAllServices',
      desc: '',
      args: [],
    );
  }

  /// `La connessione sta impiegando troppo tempo. Riprova.`
  String get errorConnectionTimeout {
    return Intl.message(
      'La connessione sta impiegando troppo tempo. Riprova.',
      name: 'errorConnectionTimeout',
      desc: '',
      args: [],
    );
  }

  /// `Attività non trovata`
  String get errorBusinessNotFound {
    return Intl.message(
      'Attività non trovata',
      name: 'errorBusinessNotFound',
      desc: '',
      args: [],
    );
  }

  /// `L'attività richiesta non esiste. Verifica l'indirizzo o contatta direttamente l'attività.`
  String get errorBusinessNotFoundSubtitle {
    return Intl.message(
      'L\'attività richiesta non esiste. Verifica l\'indirizzo o contatta direttamente l\'attività.',
      name: 'errorBusinessNotFoundSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Attività non attiva`
  String get errorBusinessNotActive {
    return Intl.message(
      'Attività non attiva',
      name: 'errorBusinessNotActive',
      desc: '',
      args: [],
    );
  }

  /// `Questa attività non è ancora configurata per le prenotazioni online. Contatta direttamente l'attività.`
  String get errorBusinessNotActiveSubtitle {
    return Intl.message(
      'Questa attività non è ancora configurata per le prenotazioni online. Contatta direttamente l\'attività.',
      name: 'errorBusinessNotActiveSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Sede non disponibile`
  String get errorLocationNotFound {
    return Intl.message(
      'Sede non disponibile',
      name: 'errorLocationNotFound',
      desc: '',
      args: [],
    );
  }

  /// `La sede selezionata non è attiva. Contatta l'attività per maggiori informazioni.`
  String get errorLocationNotFoundSubtitle {
    return Intl.message(
      'La sede selezionata non è attiva. Contatta l\'attività per maggiori informazioni.',
      name: 'errorLocationNotFoundSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Servizio temporaneamente non disponibile`
  String get errorServiceUnavailable {
    return Intl.message(
      'Servizio temporaneamente non disponibile',
      name: 'errorServiceUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `Stiamo lavorando per risolvere il problema. Riprova tra qualche minuto.`
  String get errorServiceUnavailableSubtitle {
    return Intl.message(
      'Stiamo lavorando per risolvere il problema. Riprova tra qualche minuto.',
      name: 'errorServiceUnavailableSubtitle',
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

  /// `Ricordami`
  String get authRememberMe {
    return Intl.message(
      'Ricordami',
      name: 'authRememberMe',
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

  /// `La password deve contenere almeno 8 caratteri, una maiuscola, una minuscola e un numero`
  String get authInvalidPassword {
    return Intl.message(
      'La password deve contenere almeno 8 caratteri, una maiuscola, una minuscola e un numero',
      name: 'authInvalidPassword',
      desc: '',
      args: [],
    );
  }

  /// `Errore di validazione: {message}`
  String authPasswordValidationError(Object message) {
    return Intl.message(
      'Errore di validazione: $message',
      name: 'authPasswordValidationError',
      desc: '',
      args: [message],
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

  /// `Impossibile caricare le informazioni del business. Riprova.`
  String get authBusinessNotFound {
    return Intl.message(
      'Impossibile caricare le informazioni del business. Riprova.',
      name: 'authBusinessNotFound',
      desc: '',
      args: [],
    );
  }

  /// `Questa email è già registrata. Prova ad accedere.`
  String get authEmailAlreadyRegistered {
    return Intl.message(
      'Questa email è già registrata. Prova ad accedere.',
      name: 'authEmailAlreadyRegistered',
      desc: '',
      args: [],
    );
  }

  /// `Email o password non valide`
  String get authErrorInvalidCredentials {
    return Intl.message(
      'Email o password non valide',
      name: 'authErrorInvalidCredentials',
      desc: '',
      args: [],
    );
  }

  /// `Il tuo account è disabilitato`
  String get authErrorAccountDisabled {
    return Intl.message(
      'Il tuo account è disabilitato',
      name: 'authErrorAccountDisabled',
      desc: '',
      args: [],
    );
  }

  /// `Sessione scaduta. Effettua di nuovo il login.`
  String get authErrorTokenExpired {
    return Intl.message(
      'Sessione scaduta. Effettua di nuovo il login.',
      name: 'authErrorTokenExpired',
      desc: '',
      args: [],
    );
  }

  /// `Sessione non valida. Effettua di nuovo il login.`
  String get authErrorTokenInvalid {
    return Intl.message(
      'Sessione non valida. Effettua di nuovo il login.',
      name: 'authErrorTokenInvalid',
      desc: '',
      args: [],
    );
  }

  /// `Sessione revocata. Effettua di nuovo il login.`
  String get authErrorSessionRevoked {
    return Intl.message(
      'Sessione revocata. Effettua di nuovo il login.',
      name: 'authErrorSessionRevoked',
      desc: '',
      args: [],
    );
  }

  /// `Questa email è già registrata. Prova ad accedere.`
  String get authErrorEmailAlreadyExists {
    return Intl.message(
      'Questa email è già registrata. Prova ad accedere.',
      name: 'authErrorEmailAlreadyExists',
      desc: '',
      args: [],
    );
  }

  /// `Password troppo debole. Scegline una più sicura.`
  String get authErrorWeakPassword {
    return Intl.message(
      'Password troppo debole. Scegline una più sicura.',
      name: 'authErrorWeakPassword',
      desc: '',
      args: [],
    );
  }

  /// `Token di reset password non valido`
  String get authErrorInvalidResetToken {
    return Intl.message(
      'Token di reset password non valido',
      name: 'authErrorInvalidResetToken',
      desc: '',
      args: [],
    );
  }

  /// `Token di reset password scaduto`
  String get authErrorResetTokenExpired {
    return Intl.message(
      'Token di reset password scaduto',
      name: 'authErrorResetTokenExpired',
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

  /// `Email non trovata nel sistema. Verifica l'indirizzo o registrati.`
  String get authResetPasswordEmailNotFound {
    return Intl.message(
      'Email non trovata nel sistema. Verifica l\'indirizzo o registrati.',
      name: 'authResetPasswordEmailNotFound',
      desc: '',
      args: [],
    );
  }

  /// `Reimposta password`
  String get authResetPasswordConfirmTitle {
    return Intl.message(
      'Reimposta password',
      name: 'authResetPasswordConfirmTitle',
      desc: '',
      args: [],
    );
  }

  /// `Inserisci la nuova password`
  String get authResetPasswordConfirmMessage {
    return Intl.message(
      'Inserisci la nuova password',
      name: 'authResetPasswordConfirmMessage',
      desc: '',
      args: [],
    );
  }

  /// `Nuova password`
  String get authNewPassword {
    return Intl.message(
      'Nuova password',
      name: 'authNewPassword',
      desc: '',
      args: [],
    );
  }

  /// `Password reimpostata con successo!`
  String get authResetPasswordConfirmSuccess {
    return Intl.message(
      'Password reimpostata con successo!',
      name: 'authResetPasswordConfirmSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Token non valido o scaduto`
  String get authResetPasswordConfirmError {
    return Intl.message(
      'Token non valido o scaduto',
      name: 'authResetPasswordConfirmError',
      desc: '',
      args: [],
    );
  }

  /// `Cambia password`
  String get authChangePasswordTitle {
    return Intl.message(
      'Cambia password',
      name: 'authChangePasswordTitle',
      desc: '',
      args: [],
    );
  }

  /// `Password attuale`
  String get authCurrentPassword {
    return Intl.message(
      'Password attuale',
      name: 'authCurrentPassword',
      desc: '',
      args: [],
    );
  }

  /// `Password modificata con successo`
  String get authChangePasswordSuccess {
    return Intl.message(
      'Password modificata con successo',
      name: 'authChangePasswordSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Password attuale non corretta`
  String get authChangePasswordError {
    return Intl.message(
      'Password attuale non corretta',
      name: 'authChangePasswordError',
      desc: '',
      args: [],
    );
  }

  /// `Password troppo corta (min. 8 caratteri)`
  String get authPasswordTooShort {
    return Intl.message(
      'Password troppo corta (min. 8 caratteri)',
      name: 'authPasswordTooShort',
      desc: '',
      args: [],
    );
  }

  /// `La password deve contenere: maiuscola, minuscola, numero`
  String get authPasswordRequirements {
    return Intl.message(
      'La password deve contenere: maiuscola, minuscola, numero',
      name: 'authPasswordRequirements',
      desc: '',
      args: [],
    );
  }

  /// `Cambia password`
  String get authChangePassword {
    return Intl.message(
      'Cambia password',
      name: 'authChangePassword',
      desc: '',
      args: [],
    );
  }

  /// `Per visualizzare i tuoi appuntamenti, accedi con il tuo account o registrati se non ne hai ancora uno.`
  String get authRedirectFromMyBookings {
    return Intl.message(
      'Per visualizzare i tuoi appuntamenti, accedi con il tuo account o registrati se non ne hai ancora uno.',
      name: 'authRedirectFromMyBookings',
      desc: '',
      args: [],
    );
  }

  /// `Per prenotare un appuntamento, accedi con il tuo account o registrati se non ne hai ancora uno.`
  String get authRedirectFromBooking {
    return Intl.message(
      'Per prenotare un appuntamento, accedi con il tuo account o registrati se non ne hai ancora uno.',
      name: 'authRedirectFromBooking',
      desc: '',
      args: [],
    );
  }

  /// `Profilo`
  String get profileTitle {
    return Intl.message('Profilo', name: 'profileTitle', desc: '', args: []);
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

  /// `Sede`
  String get bookingStepLocation {
    return Intl.message(
      'Sede',
      name: 'bookingStepLocation',
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

  /// `Scegli la sede`
  String get locationTitle {
    return Intl.message(
      'Scegli la sede',
      name: 'locationTitle',
      desc: '',
      args: [],
    );
  }

  /// `Seleziona dove vuoi effettuare la prenotazione`
  String get locationSubtitle {
    return Intl.message(
      'Seleziona dove vuoi effettuare la prenotazione',
      name: 'locationSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Nessuna sede disponibile`
  String get locationEmpty {
    return Intl.message(
      'Nessuna sede disponibile',
      name: 'locationEmpty',
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

  /// `Pacchetti`
  String get servicePackagesTitle {
    return Intl.message(
      'Pacchetti',
      name: 'servicePackagesTitle',
      desc: '',
      args: [],
    );
  }

  /// `Oppure scegli un pacchetto pronto`
  String get servicePackagesSubtitle {
    return Intl.message(
      'Oppure scegli un pacchetto pronto',
      name: 'servicePackagesSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Caricamento pacchetti...`
  String get servicePackagesLoading {
    return Intl.message(
      'Caricamento pacchetti...',
      name: 'servicePackagesLoading',
      desc: '',
      args: [],
    );
  }

  /// `Impossibile caricare i pacchetti.`
  String get servicePackagesLoadError {
    return Intl.message(
      'Impossibile caricare i pacchetti.',
      name: 'servicePackagesLoadError',
      desc: '',
      args: [],
    );
  }

  /// `Pacchetto`
  String get servicePackageLabel {
    return Intl.message(
      'Pacchetto',
      name: 'servicePackageLabel',
      desc: '',
      args: [],
    );
  }

  /// `Categoria {id}`
  String servicesCategoryFallbackName(int id) {
    return Intl.message(
      'Categoria $id',
      name: 'servicesCategoryFallbackName',
      desc: '',
      args: [id],
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

  /// `Vai alla prima data disponibile`
  String get dateTimeGoToFirst {
    return Intl.message(
      'Vai alla prima data disponibile',
      name: 'dateTimeGoToFirst',
      desc: '',
      args: [],
    );
  }

  /// `Vai alla prossima data disponibile`
  String get dateTimeGoToNext {
    return Intl.message(
      'Vai alla prossima data disponibile',
      name: 'dateTimeGoToNext',
      desc: '',
      args: [],
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

  /// `L'orario selezionato non è più disponibile`
  String get bookingErrorSlotConflict {
    return Intl.message(
      'L\'orario selezionato non è più disponibile',
      name: 'bookingErrorSlotConflict',
      desc: '',
      args: [],
    );
  }

  /// `Uno o più servizi selezionati non sono disponibili`
  String get bookingErrorInvalidService {
    return Intl.message(
      'Uno o più servizi selezionati non sono disponibili',
      name: 'bookingErrorInvalidService',
      desc: '',
      args: [],
    );
  }

  /// `L'operatore selezionato non è disponibile per questi servizi`
  String get bookingErrorInvalidStaff {
    return Intl.message(
      'L\'operatore selezionato non è disponibile per questi servizi',
      name: 'bookingErrorInvalidStaff',
      desc: '',
      args: [],
    );
  }

  /// `La sede selezionata non è disponibile`
  String get bookingErrorInvalidLocation {
    return Intl.message(
      'La sede selezionata non è disponibile',
      name: 'bookingErrorInvalidLocation',
      desc: '',
      args: [],
    );
  }

  /// `Il cliente selezionato non è valido`
  String get bookingErrorInvalidClient {
    return Intl.message(
      'Il cliente selezionato non è valido',
      name: 'bookingErrorInvalidClient',
      desc: '',
      args: [],
    );
  }

  /// `L'orario selezionato non è valido`
  String get bookingErrorInvalidTime {
    return Intl.message(
      'L\'orario selezionato non è valido',
      name: 'bookingErrorInvalidTime',
      desc: '',
      args: [],
    );
  }

  /// `L'operatore selezionato non è disponibile in questo orario`
  String get bookingErrorStaffUnavailable {
    return Intl.message(
      'L\'operatore selezionato non è disponibile in questo orario',
      name: 'bookingErrorStaffUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `L'orario selezionato è fuori dall'orario di lavoro`
  String get bookingErrorOutsideWorkingHours {
    return Intl.message(
      'L\'orario selezionato è fuori dall\'orario di lavoro',
      name: 'bookingErrorOutsideWorkingHours',
      desc: '',
      args: [],
    );
  }

  /// `Prenotazione non trovata`
  String get bookingErrorNotFound {
    return Intl.message(
      'Prenotazione non trovata',
      name: 'bookingErrorNotFound',
      desc: '',
      args: [],
    );
  }

  /// `Non sei autorizzato a completare questa azione`
  String get bookingErrorUnauthorized {
    return Intl.message(
      'Non sei autorizzato a completare questa azione',
      name: 'bookingErrorUnauthorized',
      desc: '',
      args: [],
    );
  }

  /// `Controlla i dati inseriti`
  String get bookingErrorValidation {
    return Intl.message(
      'Controlla i dati inseriti',
      name: 'bookingErrorValidation',
      desc: '',
      args: [],
    );
  }

  /// `Si è verificato un errore. Riprova più tardi`
  String get bookingErrorServer {
    return Intl.message(
      'Si è verificato un errore. Riprova più tardi',
      name: 'bookingErrorServer',
      desc: '',
      args: [],
    );
  }

  /// `Questa prenotazione non può essere modificata`
  String get bookingErrorNotModifiable {
    return Intl.message(
      'Questa prenotazione non può essere modificata',
      name: 'bookingErrorNotModifiable',
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

  /// `Le mie prenotazioni`
  String get myBookings {
    return Intl.message(
      'Le mie prenotazioni',
      name: 'myBookings',
      desc: '',
      args: [],
    );
  }

  /// `Prossime`
  String get upcomingBookings {
    return Intl.message(
      'Prossime',
      name: 'upcomingBookings',
      desc: '',
      args: [],
    );
  }

  /// `Passate`
  String get pastBookings {
    return Intl.message('Passate', name: 'pastBookings', desc: '', args: []);
  }

  /// `Annullate`
  String get cancelledBookings {
    return Intl.message(
      'Annullate',
      name: 'cancelledBookings',
      desc: '',
      args: [],
    );
  }

  /// `Non hai prenotazioni in programma`
  String get noUpcomingBookings {
    return Intl.message(
      'Non hai prenotazioni in programma',
      name: 'noUpcomingBookings',
      desc: '',
      args: [],
    );
  }

  /// `Non hai prenotazioni passate`
  String get noPastBookings {
    return Intl.message(
      'Non hai prenotazioni passate',
      name: 'noPastBookings',
      desc: '',
      args: [],
    );
  }

  /// `Non hai prenotazioni annullate`
  String get noCancelledBookings {
    return Intl.message(
      'Non hai prenotazioni annullate',
      name: 'noCancelledBookings',
      desc: '',
      args: [],
    );
  }

  /// `Errore nel caricamento delle prenotazioni`
  String get errorLoadingBookings {
    return Intl.message(
      'Errore nel caricamento delle prenotazioni',
      name: 'errorLoadingBookings',
      desc: '',
      args: [],
    );
  }

  /// `Modificabile`
  String get modifiable {
    return Intl.message('Modificabile', name: 'modifiable', desc: '', args: []);
  }

  /// `Non modificabile`
  String get notModifiable {
    return Intl.message(
      'Non modificabile',
      name: 'notModifiable',
      desc: '',
      args: [],
    );
  }

  /// `{days, plural, =1{Modificabile fino a domani} other{Modificabile fino a {days} giorni}}`
  String modifiableUntilDays(int days) {
    return Intl.plural(
      days,
      one: 'Modificabile fino a domani',
      other: 'Modificabile fino a $days giorni',
      name: 'modifiableUntilDays',
      desc: '',
      args: [days],
    );
  }

  /// `{hours, plural, =1{Modificabile fino a 1 ora} other{Modificabile fino a {hours} ore}}`
  String modifiableUntilHours(int hours) {
    return Intl.plural(
      hours,
      one: 'Modificabile fino a 1 ora',
      other: 'Modificabile fino a $hours ore',
      name: 'modifiableUntilHours',
      desc: '',
      args: [hours],
    );
  }

  /// `{minutes, plural, =1{Modificabile fino a 1 minuto} other{Modificabile fino a {minutes} minuti}}`
  String modifiableUntilMinutes(int minutes) {
    return Intl.plural(
      minutes,
      one: 'Modificabile fino a 1 minuto',
      other: 'Modificabile fino a $minutes minuti',
      name: 'modifiableUntilMinutes',
      desc: '',
      args: [minutes],
    );
  }

  /// `Modificabile fino al {dateTime}`
  String modifiableUntilDateTime(Object dateTime) {
    return Intl.message(
      'Modificabile fino al $dateTime',
      name: 'modifiableUntilDateTime',
      desc: '',
      args: [dateTime],
    );
  }

  /// `Riprogramma`
  String get modify {
    return Intl.message('Riprogramma', name: 'modify', desc: '', args: []);
  }

  /// `Annulla`
  String get cancel {
    return Intl.message('Annulla', name: 'cancel', desc: '', args: []);
  }

  /// `Sì`
  String get yes {
    return Intl.message('Sì', name: 'yes', desc: '', args: []);
  }

  /// `No`
  String get no {
    return Intl.message('No', name: 'no', desc: '', args: []);
  }

  /// `Annulla prenotazione`
  String get cancelBookingTitle {
    return Intl.message(
      'Annulla prenotazione',
      name: 'cancelBookingTitle',
      desc: '',
      args: [],
    );
  }

  /// `Sei sicuro di voler annullare questa prenotazione?`
  String get cancelBookingConfirm {
    return Intl.message(
      'Sei sicuro di voler annullare questa prenotazione?',
      name: 'cancelBookingConfirm',
      desc: '',
      args: [],
    );
  }

  /// `Prenotazione annullata con successo`
  String get bookingCancelled {
    return Intl.message(
      'Prenotazione annullata con successo',
      name: 'bookingCancelled',
      desc: '',
      args: [],
    );
  }

  /// `Errore durante l'annullamento della prenotazione. Riprova.`
  String get bookingCancelFailed {
    return Intl.message(
      'Errore durante l\'annullamento della prenotazione. Riprova.',
      name: 'bookingCancelFailed',
      desc: '',
      args: [],
    );
  }

  /// `Annulla`
  String get actionCancelBooking {
    return Intl.message(
      'Annulla',
      name: 'actionCancelBooking',
      desc:
          'Azione per annullare una prenotazione dal punto di vista del cliente',
      args: [],
    );
  }

  /// `Funzione di modifica in sviluppo`
  String get modifyNotImplemented {
    return Intl.message(
      'Funzione di modifica in sviluppo',
      name: 'modifyNotImplemented',
      desc: '',
      args: [],
    );
  }

  /// `Modifica prenotazione`
  String get rescheduleBookingTitle {
    return Intl.message(
      'Modifica prenotazione',
      name: 'rescheduleBookingTitle',
      desc: '',
      args: [],
    );
  }

  /// `Prenotazione attuale`
  String get currentBooking {
    return Intl.message(
      'Prenotazione attuale',
      name: 'currentBooking',
      desc: '',
      args: [],
    );
  }

  /// `Seleziona nuova data`
  String get selectNewDate {
    return Intl.message(
      'Seleziona nuova data',
      name: 'selectNewDate',
      desc: '',
      args: [],
    );
  }

  /// `Seleziona data`
  String get selectDate {
    return Intl.message(
      'Seleziona data',
      name: 'selectDate',
      desc: '',
      args: [],
    );
  }

  /// `Seleziona nuovo orario`
  String get selectNewTime {
    return Intl.message(
      'Seleziona nuovo orario',
      name: 'selectNewTime',
      desc: '',
      args: [],
    );
  }

  /// `Conferma modifica`
  String get confirmReschedule {
    return Intl.message(
      'Conferma modifica',
      name: 'confirmReschedule',
      desc: '',
      args: [],
    );
  }

  /// `Prenotazione modificata con successo`
  String get bookingRescheduled {
    return Intl.message(
      'Prenotazione modificata con successo',
      name: 'bookingRescheduled',
      desc: '',
      args: [],
    );
  }

  /// `Lo slot non è più disponibile. La prenotazione originale è rimasta invariata.`
  String get slotNoLongerAvailable {
    return Intl.message(
      'Lo slot non è più disponibile. La prenotazione originale è rimasta invariata.',
      name: 'slotNoLongerAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Prenotazione aggiornata`
  String get bookingUpdatedTitle {
    return Intl.message(
      'Prenotazione aggiornata',
      name: 'bookingUpdatedTitle',
      desc: '',
      args: [],
    );
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

  /// `Prenotazione annullata`
  String get bookingHistoryEventCancelled {
    return Intl.message(
      'Prenotazione annullata',
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

  /// `Prenotazione sostituita`
  String get bookingHistoryEventReplaced {
    return Intl.message(
      'Prenotazione sostituita',
      name: 'bookingHistoryEventReplaced',
      desc: '',
      args: [],
    );
  }

  /// `Inviata email di tipo: {type}`
  String bookingHistoryEventNotificationSentTitle(Object type) {
    return Intl.message(
      'Inviata email di tipo: $type',
      name: 'bookingHistoryEventNotificationSentTitle',
      desc: '',
      args: [type],
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

  /// `Staff`
  String get bookingHistoryActorStaff {
    return Intl.message(
      'Staff',
      name: 'bookingHistoryActorStaff',
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

  /// `Destinatario: {email}`
  String bookingHistoryNotificationRecipient(Object email) {
    return Intl.message(
      'Destinatario: $email',
      name: 'bookingHistoryNotificationRecipient',
      desc: '',
      args: [email],
    );
  }

  /// `Data invio: {dateTime}`
  String bookingHistoryNotificationSentAt(Object dateTime) {
    return Intl.message(
      'Data invio: $dateTime',
      name: 'bookingHistoryNotificationSentAt',
      desc: '',
      args: [dateTime],
    );
  }

  /// `Conferma prenotazione`
  String get bookingHistoryNotificationChannelConfirmed {
    return Intl.message(
      'Conferma prenotazione',
      name: 'bookingHistoryNotificationChannelConfirmed',
      desc: '',
      args: [],
    );
  }

  /// `Promemoria prenotazione`
  String get bookingHistoryNotificationChannelReminder {
    return Intl.message(
      'Promemoria prenotazione',
      name: 'bookingHistoryNotificationChannelReminder',
      desc: '',
      args: [],
    );
  }

  /// `Cancellazione prenotazione`
  String get bookingHistoryNotificationChannelCancelled {
    return Intl.message(
      'Cancellazione prenotazione',
      name: 'bookingHistoryNotificationChannelCancelled',
      desc: '',
      args: [],
    );
  }

  /// `Riprogrammazione prenotazione`
  String get bookingHistoryNotificationChannelRescheduled {
    return Intl.message(
      'Riprogrammazione prenotazione',
      name: 'bookingHistoryNotificationChannelRescheduled',
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

  /// `ANNULLATA`
  String get cancelledBadge {
    return Intl.message(
      'ANNULLATA',
      name: 'cancelledBadge',
      desc: '',
      args: [],
    );
  }

  /// `Attività non trovata`
  String get businessNotFound {
    return Intl.message(
      'Attività non trovata',
      name: 'businessNotFound',
      desc: '',
      args: [],
    );
  }

  /// `Verifica l'indirizzo o contatta direttamente l'attività.`
  String get businessNotFoundHint {
    return Intl.message(
      'Verifica l\'indirizzo o contatta direttamente l\'attività.',
      name: 'businessNotFoundHint',
      desc: '',
      args: [],
    );
  }

  /// `Account associato ad un'altra attività`
  String get wrongBusinessAuthTitle {
    return Intl.message(
      'Account associato ad un\'altra attività',
      name: 'wrongBusinessAuthTitle',
      desc: '',
      args: [],
    );
  }

  /// `Per prenotare su {businessName}, devi accedere con un account registrato qui.`
  String wrongBusinessAuthMessage(String businessName) {
    return Intl.message(
      'Per prenotare su $businessName, devi accedere con un account registrato qui.',
      name: 'wrongBusinessAuthMessage',
      desc: '',
      args: [businessName],
    );
  }

  /// `Esci e accedi qui`
  String get wrongBusinessAuthAction {
    return Intl.message(
      'Esci e accedi qui',
      name: 'wrongBusinessAuthAction',
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
