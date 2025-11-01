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

  static String m0(path) => "Pagina non trovata: ${path}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "actionCancel": MessageLookupByLibrary.simpleMessage("Annulla"),
        "actionConfirm": MessageLookupByLibrary.simpleMessage("Conferma"),
        "actionDelete": MessageLookupByLibrary.simpleMessage("Elimina"),
        "actionMove": MessageLookupByLibrary.simpleMessage("Sposta"),
        "actionResize": MessageLookupByLibrary.simpleMessage("Ridimensiona"),
        "appTitle": MessageLookupByLibrary.simpleMessage("Agenda"),
        "appointmentDeletedMessage":
            MessageLookupByLibrary.simpleMessage("Appuntamento eliminato"),
        "clientsTitle": MessageLookupByLibrary.simpleMessage("Elenco Clienti"),
        "deleteConfirmationTitle":
            MessageLookupByLibrary.simpleMessage("Confermi l’eliminazione?"),
        "errorNotFound": m0,
        "errorTitle": MessageLookupByLibrary.simpleMessage("Errore"),
        "navAgenda": MessageLookupByLibrary.simpleMessage("Agenda"),
        "navClients": MessageLookupByLibrary.simpleMessage("Clienti"),
        "navServices": MessageLookupByLibrary.simpleMessage("Servizi"),
        "navStaff": MessageLookupByLibrary.simpleMessage("Staff"),
        "servicesTitle": MessageLookupByLibrary.simpleMessage("Elenco Servizi"),
        "staffScreenPlaceholder":
            MessageLookupByLibrary.simpleMessage("Schermata Staff"),
        "staffTitle": MessageLookupByLibrary.simpleMessage("Elenco Staff")
      };
}
