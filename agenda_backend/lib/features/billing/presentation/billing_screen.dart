import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10_extension.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/same_tab_redirect.dart';
import '../../../core/widgets/feedback_dialog.dart';
import '../../agenda/providers/business_providers.dart';
import '../domain/billing_config_view_model.dart';
import '../providers/billing_provider.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() => ref.invalidate(billingSubscriptionProvider));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(billingSubscriptionProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final billingAsync = ref.watch(billingSubscriptionProvider);

    return Scaffold(
      body: billingAsync.when(
        data: (billing) => _BillingContent(billing: billing),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 42),
                const SizedBox(height: 12),
                Text(context.l10n.errorTitle),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(billingSubscriptionProvider),
                  child: Text(context.l10n.actionRetry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BillingContent extends ConsumerStatefulWidget {
  const _BillingContent({required this.billing});

  final BillingConfigViewModel billing;

  @override
  ConsumerState<_BillingContent> createState() => _BillingContentState();
}

class _BillingContentState extends ConsumerState<_BillingContent> {
  bool _loadingCheckout = false;
  bool _loadingPortal = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final billing = widget.billing;
    final canActivate = _canActivate(billing);
    final canReactivate = _canReactivate(billing);
    final canManage = _canManage(billing);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            context.l10n.billingTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        billing.billingEnabled
                            ? Icons.workspace_premium_outlined
                            : Icons.info_outline,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _statusTitle(context, billing),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!billing.billingEnabled)
                    Text(context.l10n.billingNotRequiredMessage)
                  else ...[
                    _InfoRow(
                      label: context.l10n.billingMonthlyAmountLabel,
                      value: _formatAmount(billing),
                    ),
                    _InfoRow(
                      label: context.l10n.billingStatusLabel,
                      value: _statusLabel(context, billing),
                    ),
                    if (billing.currentPeriodEnd != null)
                      _InfoRow(
                        label: billing.cancelAtPeriodEnd
                            ? context
                                  .l10n
                                  .billingCurrentPeriodEndCancellationLabel
                            : context.l10n.billingCurrentPeriodEndLabel,
                        value: _formatDate(billing.currentPeriodEnd!),
                      ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (canActivate)
                          FilledButton.icon(
                            onPressed: _loadingCheckout
                                ? null
                                : () => _openCheckout(context),
                            icon: _loadingCheckout
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.arrow_forward),
                            label: Text(context.l10n.billingActivateAction),
                          ),
                        if (canReactivate)
                          FilledButton.icon(
                            onPressed: _loadingPortal
                                ? null
                                : () => _openPortal(context),
                            icon: _loadingPortal
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.refresh),
                            label: Text(context.l10n.billingReactivateAction),
                          ),
                        if (canManage)
                          FilledButton.tonalIcon(
                            onPressed: _loadingPortal
                                ? null
                                : () => _openPortal(context),
                            icon: _loadingPortal
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.manage_accounts_outlined),
                            label: Text(context.l10n.billingManageAction),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canActivate(BillingConfigViewModel billing) {
    if (!billing.billingEnabled || billing.cancelAtPeriodEnd) return false;
    return {
      'inactive',
      'canceled',
      'unpaid',
      'error',
      'not_required',
    }.contains(billing.status);
  }

  bool _canReactivate(BillingConfigViewModel billing) {
    return billing.status == 'active' &&
        billing.cancelAtPeriodEnd &&
        billing.canOpenPortal;
  }

  bool _canManage(BillingConfigViewModel billing) {
    return billing.status == 'active' &&
        !billing.cancelAtPeriodEnd &&
        billing.canOpenPortal;
  }

  Future<void> _openCheckout(BuildContext context) async {
    setState(() => _loadingCheckout = true);
    try {
      final businessId = ref.read(currentBusinessIdProvider);
      final url = await ref
          .read(billingRepositoryProvider)
          .createCheckoutSession(businessId);
      await _redirect(url);
    } on ApiException catch (e) {
      if (context.mounted) {
        await FeedbackDialog.showError(
          context,
          title: context.l10n.errorTitle,
          message: e.message,
        );
      }
    } catch (_) {
      if (context.mounted) {
        await FeedbackDialog.showError(
          context,
          title: context.l10n.errorTitle,
          message: context.l10n.networkUnknownError,
        );
      }
    } finally {
      if (mounted) setState(() => _loadingCheckout = false);
    }
  }

  Future<void> _openPortal(BuildContext context) async {
    setState(() => _loadingPortal = true);
    try {
      final businessId = ref.read(currentBusinessIdProvider);
      final url = await ref
          .read(billingRepositoryProvider)
          .createPortalSession(businessId);
      await _redirect(url);
    } on ApiException catch (e) {
      if (context.mounted) {
        await FeedbackDialog.showError(
          context,
          title: context.l10n.errorTitle,
          message: e.message,
        );
      }
    } catch (_) {
      if (context.mounted) {
        await FeedbackDialog.showError(
          context,
          title: context.l10n.errorTitle,
          message: context.l10n.networkUnknownError,
        );
      }
    } finally {
      if (mounted) setState(() => _loadingPortal = false);
    }
  }

  Future<void> _redirect(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      throw const ApiException(
        code: 'invalid_url',
        message: 'URL non valido',
        statusCode: 400,
      );
    }
    await redirectInCurrentTab(uri.toString());
  }

  String _formatAmount(BillingConfigViewModel billing) {
    final cents = billing.amountCents ?? 0;
    return '${(cents / 100).toStringAsFixed(2)} ${billing.currency}';
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  String _statusTitle(BuildContext context, BillingConfigViewModel billing) {
    if (!billing.billingEnabled) return context.l10n.billingNotRequiredTitle;
    if (billing.status == 'active') {
      if (billing.cancelAtPeriodEnd && billing.currentPeriodEnd != null) {
        return context.l10n.billingActiveUntilCancellationScheduledTitle(
          _formatDate(billing.currentPeriodEnd!),
        );
      }
      return context.l10n.billingActiveTitle;
    }
    if (billing.status == 'past_due' || billing.status == 'unpaid') {
      return context.l10n.billingPaymentFailedTitle;
    }
    return context.l10n.billingRequiredTitle;
  }

  String _statusLabel(BuildContext context, BillingConfigViewModel billing) {
    if (billing.status == 'active' && billing.cancelAtPeriodEnd) {
      return context.l10n.billingStatusCancellationScheduled;
    }

    return switch (billing.status) {
      'not_required' => context.l10n.billingStatusNotRequired,
      'inactive' => context.l10n.billingStatusInactive,
      'pending_checkout' => context.l10n.billingStatusPendingCheckout,
      'active' => context.l10n.billingStatusActive,
      'past_due' => context.l10n.billingStatusPastDue,
      'unpaid' => context.l10n.billingStatusUnpaid,
      'canceled' => context.l10n.billingStatusCanceled,
      'error' => context.l10n.billingStatusError,
      _ => billing.status,
    };
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
