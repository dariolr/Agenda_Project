import 'package:agenda_backend/core/l10n/l10_extension.dart';
import 'package:agenda_backend/core/services/preferences_service.dart';
import 'package:agenda_backend/core/widgets/app_buttons.dart';
import 'package:agenda_backend/features/agenda/providers/business_providers.dart';
import 'package:agenda_backend/features/agenda/providers/tenant_time_provider.dart';
import 'package:agenda_backend/features/billing/providers/billing_notice_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BillingRequiredAgendaBanner extends ConsumerWidget {
  const BillingRequiredAgendaBanner({super.key});

  void _markSeenAndDismiss(WidgetRef ref) {
    final businessId = ref.read(currentBusinessIdProvider);
    final today = ref.read(tenantTodayProvider);
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setBool(PrefsKeys.billingNoticeSeen(businessId, dateStr), true);
    ref.invalidate(shouldShowBillingAgendaNoticeProvider);
    ref.invalidate(shouldShowBillingAgendaWarningIconProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shouldShowAsync = ref.watch(shouldShowBillingAgendaNoticeProvider);
    final show = shouldShowAsync.asData?.value ?? false;
    if (!show) return const SizedBox.shrink();

    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: colorScheme.errorContainer.withOpacity(0.12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: colorScheme.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.billingAgendaNoticeTitle,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  l10n.billingAgendaNoticeMessage,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          AppOutlinedActionButton(
            onPressed: () {
              _markSeenAndDismiss(ref);
              context.go('/altro/abbonamento?from_agenda=1');
            },
            child: Text(l10n.billingAgendaNoticeAction),
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: l10n.billingAgendaNoticeDismissTooltip,
            child: IconButton(
              onPressed: () => _markSeenAndDismiss(ref),
              icon: const Icon(Icons.close, size: 18),
              visualDensity: VisualDensity.compact,
              splashRadius: 16,
            ),
          ),
        ],
      ),
    );
  }
}
