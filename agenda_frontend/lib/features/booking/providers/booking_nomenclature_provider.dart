import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10_extension.dart';
import 'locations_provider.dart';

class _NomenclatureTerm {
  final String singular;
  final String plural;

  const _NomenclatureTerm({required this.singular, required this.plural});
}

String _lowercaseLeading(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toLowerCase()}${value.substring(1)}';
}

String? _normalizeLabel(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

_NomenclatureTerm _resolveTerm(
  String? customLabel, {
  required String fallbackSingular,
  required String fallbackPlural,
}) {
  final normalized = _normalizeLabel(customLabel);
  if (normalized == null) {
    return _NomenclatureTerm(
      singular: fallbackSingular,
      plural: fallbackPlural,
    );
  }

  // Supporta sia "singolare|plurale" che "singolare/plurale".
  final parts = normalized
      .split(RegExp(r'\s*[|/]\s*'))
      .where((part) => part.trim().isNotEmpty)
      .map((part) => part.trim())
      .toList();

  if (parts.length >= 2) {
    return _NomenclatureTerm(singular: parts.first, plural: parts[1]);
  }

  return _NomenclatureTerm(singular: normalized, plural: normalized);
}

_NomenclatureTerm _serviceTerm(BuildContext context, String? customLabel) {
  final term = _resolveTerm(
    customLabel,
    fallbackSingular: context.l10n.bookingServiceSingularLabel,
    fallbackPlural: context.l10n.bookingStepServices,
  );
  return term;
}

_NomenclatureTerm _serviceTermSentence(
  BuildContext context,
  String? customLabel,
) {
  final term = _serviceTerm(context, customLabel);
  return _NomenclatureTerm(
    singular: _lowercaseLeading(term.singular),
    plural: _lowercaseLeading(term.plural),
  );
}

final bookingStaffDisplayLabelProvider = Provider<String?>((ref) {
  return null;
});

final bookingServiceDisplayLabelProvider = Provider<String?>((ref) {
  return null;
});

final bookingLocationDisplayLabelProvider = Provider<String?>((ref) {
  return null;
});

String normalizeBookingStaffIconKey(String? raw) {
  final key = raw?.trim().toLowerCase();
  switch (key) {
    case 'person':
    case 'door':
    case 'team':
    case 'tennis':
    case 'soccer':
    case 'resource':
    case 'room':
    case 'court':
    case 'equipment':
    case 'wellness':
    case 'medical':
    case 'beauty':
    case 'education':
    case 'pet':
    case 'generic':
      return key!;
    default:
      return 'person';
  }
}

IconData bookingStaffIconFromKey(String? raw) {
  switch (normalizeBookingStaffIconKey(raw)) {
    case 'person':
      return Icons.person;
    case 'door':
      return Icons.meeting_room_outlined;
    case 'team':
      return Icons.groups_outlined;
    case 'tennis':
      return Icons.sports_tennis_outlined;
    case 'soccer':
      return Icons.sports_soccer_outlined;
    case 'resource':
      return Icons.category_outlined;
    case 'room':
      return Icons.fitness_center_outlined;
    case 'court':
      return Icons.sports_soccer_outlined;
    case 'equipment':
      return Icons.handyman_outlined;
    case 'wellness':
      return Icons.spa_outlined;
    case 'medical':
      return Icons.medical_services_outlined;
    case 'beauty':
      return Icons.auto_awesome_outlined;
    case 'education':
      return Icons.school_outlined;
    case 'pet':
      return Icons.pets_outlined;
    case 'generic':
      return Icons.widgets_outlined;
    default:
      return Icons.person;
  }
}

final bookingStaffIconProvider = Provider<IconData>((ref) {
  final location = ref.watch(effectiveLocationProvider);
  return bookingStaffIconFromKey(location?.staffIconKey);
});

Map<String, String>? _resolveOverridesForAllUsers(
  Map<String, Map<String, String>>? allOverrides, {
  required Locale locale,
  String fallbackLanguageCode = 'it',
}) {
  // Regola prodotto: se la location imposta override, vale per tutti gli utenti.
  if (allOverrides == null || allOverrides.isEmpty) {
    return null;
  }

  final localeCandidates = <String>{
    locale.toLanguageTag().toLowerCase(),
    locale.languageCode.toLowerCase(),
  };
  for (final key in localeCandidates) {
    final localeOverride = allOverrides[key];
    if (localeOverride != null && localeOverride.isNotEmpty) {
      return localeOverride;
    }
  }

  // Priorità esplicita chiavi globali.
  for (final globalKey in const ['default', 'global', '*']) {
    final global = allOverrides[globalKey];
    if (global != null && global.isNotEmpty) {
      return global;
    }
  }

  final fallbackOverride = allOverrides[fallbackLanguageCode];
  if (fallbackOverride != null && fallbackOverride.isNotEmpty) {
    return fallbackOverride;
  }

  // Se non ci sono chiavi globali, usa il primo blocco disponibile (globale di fatto).
  for (final entry in allOverrides.entries) {
    if (entry.value.isNotEmpty) {
      return entry.value;
    }
  }
  return null;
}

final bookingTextOverridesForLocaleProvider =
    Provider.family<Map<String, String>?, Locale>((ref, locale) {
      final effectiveLocation = ref.watch(effectiveLocationProvider);
      return _resolveOverridesForAllUsers(
        effectiveLocation?.bookingTextOverrides,
        locale: locale,
      );
    });

String? _overrideText(
  Map<String, String>? phraseOverrides,
  String key, {
  int? count,
}) {
  final raw = phraseOverrides?[key]?.trim();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  String normalized = raw;
  final words = normalized.split(RegExp(r'\s+'));
  if (words.length.isEven) {
    final half = words.length ~/ 2;
    final firstHalf = words.take(half).join(' ');
    final secondHalf = words.skip(half).join(' ');
    if (firstHalf.toLowerCase() == secondHalf.toLowerCase()) {
      normalized = secondHalf;
    }
  }
  if (count != null) {
    if (normalized.contains('{count}')) {
      return normalized.replaceAll('{count}', '$count');
    }
    // UX non tecnica: se manca il placeholder, anteponi il numero.
    final withCount = '$count ';
    if (normalized.startsWith(withCount)) {
      return normalized;
    }
    return '$count $normalized';
  }
  return normalized;
}

String bookingStaffStepLabel(
  BuildContext context,
  String? customLabel, {
  Map<String, String>? phraseOverrides,
}) {
  final override = _overrideText(phraseOverrides, 'staff_step_label');
  if (override != null) {
    return override;
  }
  return customLabel ?? context.l10n.bookingStepStaff;
}

String bookingLocationStepLabel(
  BuildContext context,
  String? customLabel, {
  Map<String, String>? phraseOverrides,
}) {
  final override = _overrideText(phraseOverrides, 'location_step_label');
  if (override != null) {
    return override;
  }
  return customLabel ?? context.l10n.bookingStepLocation;
}

String bookingLocationTitle(
  BuildContext context,
  String? customLabel, {
  Map<String, String>? phraseOverrides,
}) {
  final override = _overrideText(phraseOverrides, 'location_title');
  if (override != null) {
    return override;
  }
  return customLabel == null
      ? context.l10n.locationTitle
      : context.l10n.bookingChooseCustomLabel(customLabel);
}

String bookingLocationSubtitle(
  BuildContext context,
  String? customLabel, {
  Map<String, String>? phraseOverrides,
}) {
  final override = _overrideText(phraseOverrides, 'location_subtitle');
  if (override != null) {
    return override;
  }
  return context.l10n.locationSubtitle;
}

String bookingLocationEmptyLabel(
  BuildContext context,
  String? customLabel, {
  Map<String, String>? phraseOverrides,
}) {
  final override = _overrideText(phraseOverrides, 'location_empty');
  if (override != null) {
    return override;
  }
  return customLabel == null
      ? context.l10n.locationEmpty
      : context.l10n.locationEmptyCustom(customLabel);
}

String bookingServicesStepLabel(
  BuildContext context,
  String? customLabel, {
  Map<String, String>? phraseOverrides,
}) {
  final override = _overrideText(phraseOverrides, 'services_step_label');
  if (override != null) {
    return override;
  }
  return _serviceTerm(context, customLabel).plural;
}

String bookingServicesTitle(
  BuildContext context,
  String? customLabel, {
  Map<String, String>? phraseOverrides,
}) {
  final override = _overrideText(phraseOverrides, 'services_title');
  if (override != null) {
    return override;
  }
  final term = _serviceTerm(context, customLabel);
  return customLabel == null
      ? context.l10n.servicesTitle
      : context.l10n.bookingChooseCustomLabel(term.plural);
}

String bookingServicesSubtitle(
  BuildContext context,
  String? customLabel, {
  Map<String, String>? phraseOverrides,
}) {
  final override = _overrideText(phraseOverrides, 'services_subtitle');
  if (override != null) {
    return override;
  }
  final term = _serviceTermSentence(context, customLabel);
  return customLabel == null
      ? context.l10n.servicesSubtitle
      : context.l10n.servicesSubtitleCustom(term.plural);
}

String bookingServicesEmptyTitle(
  BuildContext context,
  String? customLabel, {
  Map<String, String>? phraseOverrides,
}) {
  final override = _overrideText(phraseOverrides, 'services_empty_title');
  if (override != null) {
    return override;
  }
  final term = _serviceTermSentence(context, customLabel);
  return customLabel == null
      ? context.l10n.servicesEmpty
      : context.l10n.servicesEmptyCustom(term.plural);
}

String bookingServicesEmptySubtitle(
  BuildContext context,
  String? customLabel, {
  Map<String, String>? phraseOverrides,
}) {
  final override = _overrideText(phraseOverrides, 'services_empty_subtitle');
  if (override != null) {
    return override;
  }
  final term = _serviceTermSentence(context, customLabel);
  return customLabel == null
      ? context.l10n.servicesEmptySubtitle
      : context.l10n.servicesEmptySubtitleCustom(term.plural);
}

String bookingServicesSelectedLabel(
  BuildContext context,
  String? customLabel,
  int count, {
  Map<String, String>? phraseOverrides,
}) {
  if (count == 0) {
    final override = _overrideText(phraseOverrides, 'services_selected_none');
    if (override != null) {
      return override;
    }
  } else if (count == 1) {
    final override = _overrideText(phraseOverrides, 'services_selected_one');
    if (override != null) {
      return override;
    }
  } else {
    var override = _overrideText(
      phraseOverrides,
      'services_selected_many',
      count: count,
    );
    // Campo unificato dal gestionale: se manca la chiave dedicata "many",
    // usa il valore di summary_services_label.
    override ??= _overrideText(
      phraseOverrides,
      'summary_services_label',
      count: count,
    );
    if (override != null) {
      return override;
    }
  }
  final term = _serviceTermSentence(context, customLabel);
  if (customLabel == null) {
    return context.l10n.servicesSelected(count);
  }
  if (count == 0) {
    return context.l10n.servicesSelectedNoneCustom(term.plural);
  }
  if (count == 1) {
    return context.l10n.servicesSelectedOneCustom(term.singular);
  }
  return context.l10n.servicesSelectedManyCustom(count, term.plural);
}

String bookingSummaryServicesLabel(
  BuildContext context,
  String? customLabel, {
  Map<String, String>? phraseOverrides,
}) {
  final override = _overrideText(phraseOverrides, 'summary_services_label');
  if (override != null) {
    return override;
  }
  final term = _serviceTerm(context, customLabel);
  return customLabel == null
      ? context.l10n.summaryServices
      : context.l10n.summaryServicesCustom(term.plural);
}

String bookingStaffTitle(
  BuildContext context,
  String? customLabel, {
  Map<String, String>? phraseOverrides,
}) {
  final override = _overrideText(phraseOverrides, 'staff_title');
  if (override != null) {
    return override;
  }
  return customLabel == null
      ? context.l10n.staffTitle
      : context.l10n.bookingChooseCustomLabel(customLabel);
}

String bookingStaffSubtitle(
  BuildContext context,
  String? customLabel, {
  Map<String, String>? phraseOverrides,
}) {
  final override = _overrideText(phraseOverrides, 'staff_subtitle');
  if (override != null) {
    return override;
  }
  return customLabel == null
      ? context.l10n.staffSubtitle
      : context.l10n.staffSubtitleCustom(customLabel);
}

String bookingAnyStaffLabel(
  BuildContext context,
  String? customLabel, {
  Map<String, String>? phraseOverrides,
}) {
  final override = _overrideText(phraseOverrides, 'staff_any_label');
  if (override != null) {
    return override;
  }
  return customLabel == null
      ? context.l10n.staffAnyOperator
      : context.l10n.staffAnyOperatorCustom(customLabel);
}

String bookingAnyStaffSubtitle(
  BuildContext context,
  String? customLabel, {
  Map<String, String>? phraseOverrides,
}) {
  final override = _overrideText(phraseOverrides, 'staff_any_subtitle');
  if (override != null) {
    return override;
  }
  return customLabel == null
      ? context.l10n.staffAnyOperatorSubtitle
      : context.l10n.staffAnyOperatorSubtitleCustom(customLabel);
}

String bookingNoStaffAvailableLabel(
  BuildContext context,
  String? customLabel, {
  Map<String, String>? phraseOverrides,
}) {
  final override = _overrideText(phraseOverrides, 'staff_empty');
  if (override != null) {
    return override;
  }
  return customLabel == null
      ? context.l10n.staffEmpty
      : context.l10n.staffEmptyCustom(customLabel);
}

String bookingNoStaffForServicesLabel(
  BuildContext context,
  String? customStaffLabel,
  String? customServiceLabel, {
  Map<String, String>? phraseOverrides,
}) {
  final override = _overrideText(phraseOverrides, 'no_staff_for_services');
  if (override != null) {
    return override;
  }
  if (customStaffLabel == null && customServiceLabel == null) {
    return context.l10n.noStaffForAllServices;
  }
  final staffLabel = customStaffLabel ?? context.l10n.bookingStepStaff;
  final serviceLabel = _serviceTermSentence(context, customServiceLabel).plural;
  return context.l10n.noStaffForAllServicesCustom(staffLabel, serviceLabel);
}

String bookingErrorInvalidServiceMessage(
  BuildContext context,
  String? customServiceLabel, {
  Map<String, String>? phraseOverrides,
}) {
  final override = _overrideText(phraseOverrides, 'error_invalid_service');
  if (override != null) {
    return override;
  }
  final serviceLabel = _serviceTermSentence(context, customServiceLabel).plural;
  if (customServiceLabel == null) {
    return context.l10n.bookingErrorInvalidService;
  }
  return context.l10n.bookingErrorInvalidServiceCustom(serviceLabel);
}

String bookingErrorInvalidStaffMessage(
  BuildContext context,
  String? customStaffLabel,
  String? customServiceLabel, {
  Map<String, String>? phraseOverrides,
}) {
  final override = _overrideText(phraseOverrides, 'error_invalid_staff');
  if (override != null) {
    return override;
  }
  if (customStaffLabel == null && customServiceLabel == null) {
    return context.l10n.bookingErrorInvalidStaff;
  }
  final staffLabel = customStaffLabel ?? context.l10n.bookingStepStaff;
  final serviceLabel = _serviceTermSentence(context, customServiceLabel).plural;
  return context.l10n.bookingErrorInvalidStaffCustom(staffLabel, serviceLabel);
}

String bookingErrorInvalidLocationMessage(
  BuildContext context,
  String? customLocationLabel, {
  Map<String, String>? phraseOverrides,
}) {
  final override = _overrideText(phraseOverrides, 'error_invalid_location');
  if (override != null) {
    return override;
  }
  if (customLocationLabel == null) {
    return context.l10n.bookingErrorInvalidLocation;
  }
  return context.l10n.bookingErrorInvalidLocationCustom(customLocationLabel);
}

String bookingErrorStaffUnavailableMessage(
  BuildContext context,
  String? customStaffLabel, {
  Map<String, String>? phraseOverrides,
}) {
  final override = _overrideText(phraseOverrides, 'error_staff_unavailable');
  if (override != null) {
    return override;
  }
  if (customStaffLabel == null) {
    return context.l10n.bookingErrorStaffUnavailable;
  }
  return context.l10n.bookingErrorStaffUnavailableCustom(customStaffLabel);
}

String bookingMissingSelectedServicesMessage(
  BuildContext context,
  String? customServiceLabel, {
  Map<String, String>? phraseOverrides,
}) {
  final override = _overrideText(phraseOverrides, 'error_missing_services');
  if (override != null) {
    return override;
  }
  final serviceLabel = _serviceTermSentence(context, customServiceLabel).plural;
  if (customServiceLabel == null) {
    return context.l10n.bookingErrorMissingServices;
  }
  return context.l10n.bookingErrorMissingServicesCustom(serviceLabel);
}

String bookingErrorServiceUnavailableMessage(
  BuildContext context,
  String? customServiceLabel, {
  Map<String, String>? phraseOverrides,
}) {
  final override = _overrideText(phraseOverrides, 'error_service_unavailable');
  if (override != null) {
    return override;
  }
  if (customServiceLabel == null) {
    return context.l10n.errorServiceUnavailable;
  }
  final serviceLabel = _serviceTermSentence(
    context,
    customServiceLabel,
  ).singular;
  return context.l10n.errorServiceUnavailableCustom(serviceLabel);
}
