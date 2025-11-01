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
    assert(_current != null,
        'No instance of L10n was loaded. Try to initialize the L10n delegate before accessing L10n.current.');
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
    assert(instance != null,
        'No instance of L10n present in the widget tree. Did you add L10n.delegate in localizationsDelegates?');
    return instance!;
  }

  static L10n? maybeOf(BuildContext context) {
    return Localizations.of<L10n>(context, L10n);
  }

  /// `Agenda`
  String get appTitle {
    return Intl.message(
      'Agenda',
      name: 'appTitle',
      desc: '',
      args: [],
    );
  }

  /// `Agenda`
  String get navAgenda {
    return Intl.message(
      'Agenda',
      name: 'navAgenda',
      desc: '',
      args: [],
    );
  }

  /// `Clienti`
  String get navClients {
    return Intl.message(
      'Clienti',
      name: 'navClients',
      desc: '',
      args: [],
    );
  }

  /// `Servizi`
  String get navServices {
    return Intl.message(
      'Servizi',
      name: 'navServices',
      desc: '',
      args: [],
    );
  }

  /// `Staff`
  String get navStaff {
    return Intl.message(
      'Staff',
      name: 'navStaff',
      desc: '',
      args: [],
    );
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

  /// `Elenco Servizi`
  String get servicesTitle {
    return Intl.message(
      'Elenco Servizi',
      name: 'servicesTitle',
      desc: '',
      args: [],
    );
  }

  /// `Elenco Staff`
  String get staffTitle {
    return Intl.message(
      'Elenco Staff',
      name: 'staffTitle',
      desc: '',
      args: [],
    );
  }

  /// `Errore`
  String get errorTitle {
    return Intl.message(
      'Errore',
      name: 'errorTitle',
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

  /// `Schermata Staff`
  String get staffScreenPlaceholder {
    return Intl.message(
      'Schermata Staff',
      name: 'staffScreenPlaceholder',
      desc: '',
      args: [],
    );
  }

  /// `Ridimensiona`
  String get actionResize {
    return Intl.message(
      'Ridimensiona',
      name: 'actionResize',
      desc: '',
      args: [],
    );
  }

  /// `Sposta`
  String get actionMove {
    return Intl.message(
      'Sposta',
      name: 'actionMove',
      desc: '',
      args: [],
    );
  }

  /// `Elimina`
  String get actionDelete {
    return Intl.message(
      'Elimina',
      name: 'actionDelete',
      desc: '',
      args: [],
    );
  }

  /// `Annulla`
  String get actionCancel {
    return Intl.message(
      'Annulla',
      name: 'actionCancel',
      desc: '',
      args: [],
    );
  }

  /// `Conferma`
  String get actionConfirm {
    return Intl.message(
      'Conferma',
      name: 'actionConfirm',
      desc: '',
      args: [],
    );
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

  /// `Appuntamento eliminato`
  String get appointmentDeletedMessage {
    return Intl.message(
      'Appuntamento eliminato',
      name: 'appointmentDeletedMessage',
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
