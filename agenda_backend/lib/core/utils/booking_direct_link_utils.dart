
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/agenda/providers/business_providers.dart';
import '../../features/agenda/providers/location_providers.dart';
import '../l10n/l10_extension.dart';
import '../network/network_providers.dart';
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
    _ => url,
  };
}

Future<void> copyBookingDirectLink(
  BuildContext context,
  WidgetRef ref, {
  required String targetType,
  required int targetId,
}) async {
  try {
    final businessId = ref.read(currentBusinessIdProvider);
    final locationId = ref.read(currentLocationIdProvider);
    if (businessId <= 0 || locationId <= 0) return;
    final link = await ref.read(apiClientProvider).createOrGetBookingDirectLink(
      businessId: businessId,
      locationId: locationId,
      targetType: targetType,
      targetId: targetId,
    );
    final url = (link['url'] as String?)?.trim();
    if (url == null || url.isEmpty) {
      throw StateError('Missing direct link URL');
    }
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    await FeedbackDialog.showSuccess(
      context,
      title: context.l10n.closuresImportHolidaysLinkCopied,
      message: bookingDirectLinkCopiedMessage(
        context,
        targetType: targetType,
        url: url,
      ),
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
