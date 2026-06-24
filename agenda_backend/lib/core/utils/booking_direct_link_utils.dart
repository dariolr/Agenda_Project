import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/agenda/providers/business_providers.dart';
import '../../features/agenda/providers/location_providers.dart';
import '../environment/app_environment_config.dart';
import '../l10n/l10_extension.dart';
import '../models/location.dart';
import '../network/network_providers.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/feedback_dialog.dart';

String bookingDirectLinkCopiedMessage(
  BuildContext context, {
  required String targetType,
  required String url,
}) {
  final l10n = context.l10n;

  return switch (targetType) {
    'service_variant' => l10n.bookingDirectLinkCopiedServiceMessage(url),
    'service_package' => l10n.bookingDirectLinkCopiedPackageMessage(url),
    'class_event' => l10n.bookingDirectLinkCopiedEventMessage(url),
    'service_category' => l10n.bookingDirectLinkCopiedCategoryMessage(url),
    'staff' => l10n.bookingDirectLinkCopiedStaffMessage(url),
    _ => url,
  };
}

Future<void> copyBookingDirectLink(
  BuildContext context,
  WidgetRef ref, {
  required String targetType,
  required int targetId,
  String? scopeType,
  int? locationId,
}) async {
  try {
    final businessId = ref.read(currentBusinessIdProvider);
    final currentLocationId = ref.read(currentLocationIdProvider);
    if (businessId <= 0) {
      return;
    }

    final resolved = await _resolveDirectLinkCopyTarget(
      context,
      ref,
      businessId: businessId,
      targetType: targetType,
      targetId: targetId,
      requestedScopeType: scopeType,
      requestedLocationId: locationId,
      currentLocationId: currentLocationId,
    );
    if (resolved == null) return;

    if (resolved.scopeType == 'location' && resolved.locationId <= 0) return;

    final link = await ref
        .read(apiClientProvider)
        .createOrGetBookingDirectLink(
          businessId: businessId,
          locationId: resolved.scopeType == 'location'
              ? resolved.locationId
              : null,
          targetType: targetType,
          targetId: targetId,
          scopeType: resolved.scopeType,
        );
    final url = (link['url'] as String?)?.trim();
    if (url == null || url.isEmpty) {
      throw StateError('Missing direct link URL');
    }
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    await _showBookingLinkCopiedDialog(
      context,
      message: bookingDirectLinkCopiedMessage(
        context,
        targetType: targetType,
        url: url,
      ),
      url: url,
    );
  } catch (_) {
    if (!context.mounted) return;
    await FeedbackDialog.showError(
      context,
      title: context.l10n.errorTitle,
      message: context.l10n.networkUnknownError,
    );
  }
}

Future<void> copyLocationBookingLink(
  BuildContext context,
  WidgetRef ref, {
  required int locationId,
}) async {
  try {
    final slug = ref.read(currentBusinessProvider).slug?.trim();
    if (slug == null || slug.isEmpty) {
      await FeedbackDialog.showError(
        context,
        title: context.l10n.errorTitle,
        message: context.l10n.bookingLocationLinkMissingBusinessSlugMessage,
      );
      return;
    }

    final url = buildPublicBookingUrl(slug: slug, locationId: locationId);
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    await _showBookingLinkCopiedDialog(
      context,
      message: context.l10n.bookingLocationLinkCopiedMessage(url),
      url: url,
    );
  } catch (_) {
    if (!context.mounted) return;
    await FeedbackDialog.showError(
      context,
      title: context.l10n.errorTitle,
      message: context.l10n.networkUnknownError,
    );
  }
}

Future<void> _showBookingLinkCopiedDialog(
  BuildContext context, {
  required String message,
  required String url,
}) {
  return FeedbackDialog.showSuccess(
    context,
    title: context.l10n.closuresImportHolidaysLinkCopied,
    message: message,
    actionLabel: context.l10n.bookingLinkOpenAction,
    onAction: () => launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    ),
  );
}

String buildPublicBookingUrl({
  required String slug,
  int? locationId,
}) {
  final baseUri = Uri.parse(publicBookingBaseUrl());
  return baseUri
      .replace(
        pathSegments: <String>[slug, 'booking'],
        queryParameters: locationId != null && locationId > 0
            ? <String, String>{'location': '$locationId'}
            : null,
      )
      .toString();
}

String publicBookingBaseUrl() {
  final webBaseUrl = _configuredWebBaseUrl();
  if (webBaseUrl == null) {
    return 'https://prenota.romeolab.it';
  }

  final webBaseUri = Uri.parse(webBaseUrl);
  return switch (webBaseUri.host) {
    'gestionale.romeolab.it' => 'https://prenota.romeolab.it',
    'demo-gestionale.romeolab.it' => 'https://demo-prenota.romeolab.it',
    'staging-gestionale.romeolab.it' => 'https://staging-prenota.romeolab.it',
    _ => webBaseUrl,
  };
}

String? _configuredWebBaseUrl() {
  try {
    return AppEnvironmentConfig.current.webBaseUrl;
  } catch (_) {
    return null;
  }
}

Future<_DirectLinkCopyTarget?> _resolveDirectLinkCopyTarget(
  BuildContext context,
  WidgetRef ref, {
  required int businessId,
  required String targetType,
  required int targetId,
  required String? requestedScopeType,
  required int? requestedLocationId,
  required int currentLocationId,
}) async {
  if (requestedScopeType != null) {
    return _DirectLinkCopyTarget(
      scopeType: requestedScopeType,
      locationId: requestedScopeType == 'location'
          ? (requestedLocationId ?? currentLocationId)
          : 0,
    );
  }

  if (targetType != 'service_category' && targetType != 'staff') {
    return _DirectLinkCopyTarget(
      scopeType: 'location',
      locationId: currentLocationId,
    );
  }

  final apiClient = ref.read(apiClientProvider);
  final info = await apiClient.getBookingDirectLinkInfo(
    businessId: businessId,
    targetType: targetType,
    targetId: targetId,
    scopeType: 'business',
  );
  final compatibleLocationIds =
      (info['compatible_location_ids'] as List<dynamic>? ?? const [])
          .map((value) => value is int ? value : int.tryParse('$value') ?? 0)
          .where((id) => id > 0)
          .toList();

  if (!context.mounted) return null;

  if (compatibleLocationIds.isEmpty) {
    await FeedbackDialog.showError(
      context,
      title: context.l10n.errorTitle,
      message: context.l10n.bookingDirectLinkNoCompatibleLocationsMessage,
    );
    return null;
  }

  if (compatibleLocationIds.length == 1) {
    return _DirectLinkCopyTarget(
      scopeType: 'location',
      locationId: compatibleLocationIds.first,
    );
  }

  final copyBusinessLevel = await _askDirectLinkScope(context);
  if (copyBusinessLevel == null) return null;

  if (copyBusinessLevel) {
    return const _DirectLinkCopyTarget(scopeType: 'business', locationId: 0);
  }

  if (compatibleLocationIds.contains(currentLocationId)) {
    return _DirectLinkCopyTarget(
      scopeType: 'location',
      locationId: currentLocationId,
    );
  }

  if (!context.mounted) return null;
  final selectedLocationId = await _askDirectLinkLocation(
    context,
    ref,
    compatibleLocationIds,
  );
  if (selectedLocationId == null) return null;

  return _DirectLinkCopyTarget(
    scopeType: 'location',
    locationId: selectedLocationId,
  );
}

Future<bool?> _askDirectLinkScope(BuildContext context) {
  return showAppFormDialog<bool>(
    context,
    builder: (dialogContext) => AppFormDialog(
      title: Text(context.l10n.bookingDirectLinkScopeChoiceTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.business_outlined),
            title: Text(context.l10n.bookingDirectLinkBusinessScopeAction),
            onTap: () => Navigator.of(dialogContext).pop(true),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(context.l10n.bookingDirectLinkLocationScopeAction),
            onTap: () => Navigator.of(dialogContext).pop(false),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(context.l10n.actionCancel),
        ),
      ],
    ),
  );
}

Future<int?> _askDirectLinkLocation(
  BuildContext context,
  WidgetRef ref,
  List<int> compatibleLocationIds,
) {
  final locations =
      ref
          .read(locationsProvider)
          .where((location) => compatibleLocationIds.contains(location.id))
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  final locationsById = {
    for (final location in locations) location.id: location,
  };

  return showAppFormDialog<int>(
    context,
    builder: (dialogContext) => AppFormDialog(
      title: Text(context.l10n.bookingDirectLinkLocationChoiceTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final locationId in compatibleLocationIds)
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text(
                _locationLabel(locationsById[locationId], locationId),
              ),
              onTap: () => Navigator.of(dialogContext).pop(locationId),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(context.l10n.actionCancel),
        ),
      ],
    ),
  );
}

String _locationLabel(Location? location, int locationId) =>
    location?.name.trim().isNotEmpty == true
    ? location!.name
    : 'ID: $locationId';

class _DirectLinkCopyTarget {
  const _DirectLinkCopyTarget({
    required this.scopeType,
    required this.locationId,
  });

  final String scopeType;
  final int locationId;
}
