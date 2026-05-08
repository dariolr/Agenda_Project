import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/date_time_formats.dart';
import '../../../core/l10n/l10_extension.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/same_tab_redirect.dart';
import '../../../core/services/tenant_time_service.dart';
import '../../../core/widgets/feedback_dialog.dart';
import '../../agenda/providers/business_providers.dart';
import '../../agenda/providers/tenant_time_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/billing_config_view_model.dart';
import '../providers/billing_provider.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key, this.checkoutCanceled = false});

  final bool checkoutCanceled;

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      WidgetsBinding.instance.addObserver(this);
    }
    Future.microtask(_refreshInitialSubscription);
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!kIsWeb && state == AppLifecycleState.resumed) {
      ref.invalidate(billingSubscriptionProvider);
    }
  }

  Future<void> _refreshInitialSubscription() async {
    if (!widget.checkoutCanceled) {
      ref.invalidate(billingSubscriptionProvider);
      return;
    }

    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId > 0) {
      try {
        await ref
            .read(billingRepositoryProvider)
            .getSubscription(businessId, checkoutCancelled: true);
      } catch (_) {
        // The provider refresh below will surface any loading error in the UI.
      }
    }
    ref.invalidate(billingSubscriptionProvider);
  }

  @override
  Widget build(BuildContext context) {
    final billingAsync = ref.watch(billingSubscriptionProvider);
    final isSuperadmin = ref.watch(
      authProvider.select((state) => state.user?.isSuperadmin ?? false),
    );

    return Scaffold(
      body: billingAsync.when(
        data: (billing) => _BillingContent(
          billing: billing,
          checkoutCanceled: widget.checkoutCanceled,
          isSuperadmin: isSuperadmin,
        ),
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
  const _BillingContent({
    required this.billing,
    required this.checkoutCanceled,
    required this.isSuperadmin,
  });

  final BillingConfigViewModel billing;
  final bool checkoutCanceled;
  final bool isSuperadmin;

  @override
  ConsumerState<_BillingContent> createState() => _BillingContentState();
}

class _BillingContentState extends ConsumerState<_BillingContent> {
  bool _loadingCheckout = false;
  bool _loadingPortal = false;
  bool _loadingCancelCheckout = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final billing = widget.billing;
    final canActivate = _canActivate(billing);
    final canReactivate = _canReactivate(billing);
    final canManage = _canManage(billing);
    final isStartedCheckout = _isStartedPendingCheckout(billing);
    final isActionLoading =
        _loadingCheckout || _loadingPortal || _loadingCancelCheckout;

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
                    if (_isStartedPendingCheckout(billing)) ...[
                      _BillingNotice(
                        message: context.l10n.billingCheckoutStartedMessage,
                      ),
                      const SizedBox(height: 16),
                    ] else if (_shouldShowCheckoutIncompleteNotice(billing)) ...[
                      _BillingNotice(
                        message: context.l10n.billingCheckoutIncompleteMessage,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _InfoRow(
                      label: context.l10n.billingMonthlyAmountLabel,
                      value: _formatAmount(billing),
                    ),
                    _InfoRow(
                      label: context.l10n.billingStatusLabel,
                      value: _statusLabel(context, billing),
                      valueColor: _statusColor(colorScheme, billing),
                      valueFontWeight: FontWeight.w700,
                    ),
                    if (billing.currentPeriodEnd != null)
                      _InfoRow(
                        label: billing.cancelAtPeriodEnd
                            ? context
                                  .l10n
                                  .billingCurrentPeriodEndCancellationLabel
                            : context.l10n.billingCurrentPeriodEndLabel,
                        value: _formatDate(context, billing.currentPeriodEnd!),
                      ),
                    if (widget.isSuperadmin) ...[
                      const SizedBox(height: 12),
                      Divider(color: colorScheme.outlineVariant),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.billingSuperadminFieldsTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _DiagnosticRow(
                        label: context.l10n.billingBillingEnabledLabel,
                        value: _formatBool(billing.billingEnabled),
                      ),
                      _DiagnosticRow(
                        label: context.l10n.billingStatusFieldLabel,
                        value: billing.status,
                      ),
                      _DiagnosticRow(
                        label: context.l10n.billingCancelAtPeriodEndLabel,
                        value: _formatBool(billing.cancelAtPeriodEnd),
                      ),
                      _DiagnosticRow(
                        label: context.l10n.billingProviderCodeFieldLabel,
                        value: _formatNullable(billing.providerCode),
                      ),
                      _DiagnosticRow(
                        label: context.l10n.billingProviderPriceReferenceLabel,
                        value: _formatNullable(billing.providerPriceReference),
                      ),
                      _DiagnosticRow(
                        label: context.l10n.billingProviderCustomerIdLabel,
                        value: _formatNullable(billing.providerCustomerId),
                      ),
                      _DiagnosticRow(
                        label: context.l10n.billingProviderSubscriptionIdLabel,
                        value: _formatNullable(billing.providerSubscriptionId),
                      ),
                      _DiagnosticRow(
                        label: context.l10n.billingCurrentPeriodStartFieldLabel,
                        value: _formatDiagnosticDate(
                          billing.currentPeriodStart,
                        ),
                      ),
                      _DiagnosticRow(
                        label: context.l10n.billingCurrentPeriodEndFieldLabel,
                        value: _formatDiagnosticDate(billing.currentPeriodEnd),
                      ),
                      _DiagnosticRow(
                        label: context.l10n.billingCanceledAtFieldLabel,
                        value: _formatDiagnosticDate(billing.canceledAt),
                      ),
                      _DiagnosticRow(
                        label: context.l10n.billingLastPaymentAtFieldLabel,
                        value: _formatDiagnosticDate(billing.lastPaymentAt),
                      ),
                      _DiagnosticRow(
                        label:
                            context.l10n.billingLastPaymentFailedAtFieldLabel,
                        value: _formatDiagnosticDate(
                          billing.lastPaymentFailedAt,
                        ),
                      ),
                      _DiagnosticRow(
                        label: context.l10n.billingLastCheckoutSessionIdLabel,
                        value: _formatNullable(billing.lastCheckoutSessionId),
                      ),
                      _DiagnosticRow(
                        label: context.l10n.billingCanStartCheckoutFieldLabel,
                        value: _formatBool(billing.canStartCheckout),
                      ),
                      _DiagnosticRow(
                        label: context.l10n.billingCanOpenPortalFieldLabel,
                        value: _formatBool(billing.canOpenPortal),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (isStartedCheckout)
                          FilledButton.icon(
                            onPressed: isActionLoading
                                ? null
                                : () => _resumeCheckout(context),
                            icon: _loadingCheckout
                                ? const _ButtonProgressIndicator()
                                : const Icon(Icons.open_in_new),
                            label: Text(context.l10n.billingResumeCheckoutAction),
                          ),
                        if (isStartedCheckout)
                          FilledButton.tonalIcon(
                            onPressed: isActionLoading
                                ? null
                                : () => _cancelCheckout(context),
                            icon: _loadingCancelCheckout
                                ? const _ButtonProgressIndicator()
                                : const Icon(Icons.restart_alt),
                            label: Text(
                              context.l10n.billingCancelCheckoutRetryAction,
                            ),
                          ),
                        if (!isStartedCheckout && canActivate)
                          FilledButton.icon(
                            onPressed: isActionLoading
                                ? null
                                : () => _openCheckout(context),
                            icon: _loadingCheckout
                                ? const _ButtonProgressIndicator()
                                : const Icon(Icons.arrow_forward),
                            label: Text(_activateActionLabel(context, billing)),
                          ),
                        if (canReactivate)
                          FilledButton.icon(
                            onPressed: isActionLoading
                                ? null
                                : () => _openPortal(context),
                            icon: _loadingPortal
                                ? const _ButtonProgressIndicator()
                                : const Icon(Icons.refresh),
                            label: Text(context.l10n.billingReactivateAction),
                          ),
                        if (canManage)
                          FilledButton.tonalIcon(
                            onPressed: isActionLoading
                                ? null
                                : () => _openPortal(context),
                            icon: _loadingPortal
                                ? const _ButtonProgressIndicator()
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
    if (!billing.billingEnabled) return false;
    if (billing.status == 'active' && billing.cancelAtPeriodEnd) return false;
    if (billing.status == 'pending_checkout') {
      return _isRetryablePendingCheckout(billing);
    }
    if ((billing.status == 'past_due' || billing.status == 'unpaid') &&
        billing.lastPaymentAt == null) {
      return billing.canStartCheckout;
    }
    return {
      'inactive',
      'canceled',
      'unpaid',
      'error',
      'not_required',
    }.contains(billing.status);
  }

  String _activateActionLabel(
    BuildContext context,
    BillingConfigViewModel billing,
  ) {
    if (billing.status == 'pending_checkout' &&
        _isRetryablePendingCheckout(billing)) {
      return context.l10n.billingRetryPaymentAction;
    }
    if ((billing.status == 'past_due' || billing.status == 'unpaid') &&
        billing.lastPaymentAt == null) {
      return context.l10n.billingRetryActivationAction;
    }

    return context.l10n.billingActivateAction;
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

  bool _isPendingCheckoutWithoutPayment(BillingConfigViewModel billing) {
    return billing.status == 'pending_checkout' && billing.lastPaymentAt == null;
  }

  bool _isRetryablePendingCheckout(BillingConfigViewModel billing) {
    return _isPendingCheckoutWithoutPayment(billing) &&
        billing.checkoutRetryable &&
        billing.checkoutState != 'started';
  }

  bool _isStartedPendingCheckout(BillingConfigViewModel billing) {
    return _isPendingCheckoutWithoutPayment(billing) &&
        (billing.checkoutState == 'started' ||
            (!billing.checkoutRetryable &&
                billing.lastCheckoutSessionId != null &&
                billing.lastCheckoutSessionId!.isNotEmpty));
  }

  bool _shouldShowCheckoutIncompleteNotice(BillingConfigViewModel billing) {
    if (widget.checkoutCanceled || _isRetryablePendingCheckout(billing)) {
      return true;
    }

    return billing.lastPaymentAt == null &&
        (billing.providerSubscriptionId == null ||
            billing.providerSubscriptionId!.isEmpty) &&
        billing.lastCheckoutSessionId != null &&
        billing.lastCheckoutSessionId!.isNotEmpty &&
        billing.checkoutRetryable;
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
      if (e.statusCode == 409 && e.code == 'subscription_already_exists') {
        ref.invalidate(billingSubscriptionProvider);
      } else if (e.statusCode == 409 && e.code == 'checkout_already_started') {
        ref.invalidate(billingSubscriptionProvider);
      }
      if (context.mounted) {
        await FeedbackDialog.showError(
          context,
          title: context.l10n.errorTitle,
          message: _checkoutErrorMessage(context, e),
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

  Future<void> _resumeCheckout(BuildContext context) async {
    setState(() => _loadingCheckout = true);
    try {
      final businessId = ref.read(currentBusinessIdProvider);
      final url = await ref
          .read(billingRepositoryProvider)
          .resumeCheckoutSession(businessId);
      await _redirect(url);
    } on ApiException catch (e) {
      ref.invalidate(billingSubscriptionProvider);
      if (context.mounted) {
        await FeedbackDialog.showError(
          context,
          title: context.l10n.errorTitle,
          message: _checkoutErrorMessage(context, e),
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

  Future<void> _cancelCheckout(BuildContext context) async {
    setState(() => _loadingCancelCheckout = true);
    try {
      final businessId = ref.read(currentBusinessIdProvider);
      await ref.read(billingRepositoryProvider).cancelCheckoutSession(businessId);
      ref.invalidate(billingSubscriptionProvider);
    } on ApiException catch (e) {
      ref.invalidate(billingSubscriptionProvider);
      if (context.mounted) {
        await FeedbackDialog.showError(
          context,
          title: context.l10n.errorTitle,
          message: _checkoutErrorMessage(context, e),
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
      if (mounted) setState(() => _loadingCancelCheckout = false);
    }
  }

  String _checkoutErrorMessage(BuildContext context, ApiException error) {
    if (error.statusCode == 409 && error.code == 'subscription_already_exists') {
      return context.l10n.billingSubscriptionAlreadyExistsError;
    }
    if (error.statusCode == 409 && error.code == 'checkout_already_started') {
      return context.l10n.billingCheckoutAlreadyStartedError;
    }

    return error.message;
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

  String _formatDate(BuildContext context, DateTime date) {
    final timezone = ref.read(effectiveTenantTimezoneProvider);
    final tenantDate = date.isUtc
        ? TenantTimeService.fromUtcToTenant(date, timezone)
        : TenantTimeService.assumeTenantLocal(date, timezone);
    return DateFormat.yMd(DtFmt.localeTag(context)).format(tenantDate);
  }

  String _formatDiagnosticDate(DateTime? date) {
    return date?.toIso8601String() ?? '-';
  }

  String _formatNullable(String? value) {
    return value == null || value.isEmpty ? '-' : value;
  }

  String _formatBool(bool value) {
    return value ? 'true' : 'false';
  }

  String _statusTitle(BuildContext context, BillingConfigViewModel billing) {
    if (!billing.billingEnabled) return context.l10n.billingNotRequiredTitle;
    if (billing.status == 'active') {
      if (billing.cancelAtPeriodEnd && billing.currentPeriodEnd != null) {
        return context.l10n.billingActiveUntilCancellationScheduledTitle(
          _formatDate(context, billing.currentPeriodEnd!),
        );
      }
      return context.l10n.billingActiveTitle;
    }
    if (billing.status == 'past_due' || billing.status == 'unpaid') {
      return context.l10n.billingPaymentFailedTitle;
    }
    return context.l10n.billingInactiveTitle;
  }

  String _statusLabel(BuildContext context, BillingConfigViewModel billing) {
    if (billing.status == 'active' && billing.cancelAtPeriodEnd) {
      return context.l10n.billingStatusCancellationScheduled;
    }

    return switch (billing.status) {
      'not_required' => context.l10n.billingStatusNotRequired,
      'inactive' => context.l10n.billingStatusInactive,
      'pending_checkout' =>
        _isPendingCheckoutWithoutPayment(billing)
            ? context.l10n.billingStatusPendingCheckout
            : context.l10n.billingStatusInactive,
      'active' => context.l10n.billingStatusActive,
      'past_due' => context.l10n.billingStatusPastDue,
      'unpaid' => context.l10n.billingStatusUnpaid,
      'canceled' => context.l10n.billingStatusCanceled,
      'error' => context.l10n.billingStatusError,
      _ => billing.status,
    };
  }

  Color? _statusColor(ColorScheme colorScheme, BillingConfigViewModel billing) {
    if (billing.status == 'active' && billing.cancelAtPeriodEnd) {
      return colorScheme.error;
    }
    if (billing.status == 'active') {
      return Colors.green.shade700;
    }
    return null;
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueFontWeight,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final FontWeight? valueFontWeight;

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
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: valueColor,
              fontWeight: valueFontWeight,
            ),
          ),
        ],
      ),
    );
  }
}

class _ButtonProgressIndicator extends StatelessWidget {
  const _ButtonProgressIndicator();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

class _BillingNotice extends StatelessWidget {
  const _BillingNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          SelectableText(value, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
