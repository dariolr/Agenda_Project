import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/date_time_formats.dart';
import '../../../core/l10n/l10_extension.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/tenant_time_service.dart';
import '../../agenda/providers/business_providers.dart';
import '../../agenda/providers/tenant_time_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/billing_config_view_model.dart';
import '../providers/billing_provider.dart';
import 'widgets/billing_external_link.dart';

enum _BillingExternalPurpose { checkout, portal }

class _BillingExternalAction {
  const _BillingExternalAction({
    required this.key,
    required this.purpose,
    required this.label,
    required this.icon,
    this.tonal = false,
  });

  final String key;
  final _BillingExternalPurpose purpose;
  final String label;
  final IconData icon;
  final bool tonal;
}

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key, this.checkoutCanceled = false});

  final bool checkoutCanceled;

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(_refreshInitialSubscription);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    ref.invalidate(billingSubscriptionProvider);
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
        skipLoadingOnReload: false,
        skipLoadingOnRefresh: true,
        data: (billing) => _BillingContent(
          scrollController: _scrollController,
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
    required this.scrollController,
    required this.billing,
    required this.checkoutCanceled,
    required this.isSuperadmin,
  });

  final ScrollController scrollController;
  final BillingConfigViewModel billing;
  final bool checkoutCanceled;
  final bool isSuperadmin;

  @override
  ConsumerState<_BillingContent> createState() => _BillingContentState();
}

class _BillingContentState extends ConsumerState<_BillingContent> {
  bool _preparingExternalLink = false;
  String? _preparingActionKey;
  String? _preparedActionKey;
  String? _preparedExternalUrl;
  String? _prepareExternalLinkError;
  String? _failedActionKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final billing = widget.billing;
    final externalAction = _externalActionForBilling(context, billing);
    if (externalAction != null) {
      _scheduleExternalLinkPreparation(externalAction);
    }
    final preparedUrl = _preparedActionKey == externalAction?.key
        ? _preparedExternalUrl
        : null;

    return SafeArea(
      child: ListView(
        key: const PageStorageKey<String>('billing-subscription-scroll'),
        controller: widget.scrollController,
        padding: const EdgeInsets.all(24),
        children: [
          if (billing.accessBlocked) ...[
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        billing.activationDeadlineAt != null
                            ? context.l10n.billingAccessBlockedMessageWithDate(
                                DtFmt.longDate(context, billing.activationDeadlineAt!),
                              )
                            : context.l10n.billingAccessBlockedMessage,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ] else if (!billing.accessBlocked &&
              billing.activationDeadlineAt != null &&
              billing.billingEnabled) ...[
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.l10n.billingActivationDeadlinePending(
                          DtFmt.longDate(context, billing.activationDeadlineAt!),
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
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
                    ] else if (_shouldShowCheckoutIncompleteNotice(
                      billing,
                    )) ...[
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
                    if (externalAction != null) ...[
                      if (_prepareExternalLinkError != null) ...[
                        _BillingNotice(message: _prepareExternalLinkError!),
                        const SizedBox(height: 16),
                      ],
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          BillingExternalLink(
                            url: preparedUrl,
                            icon: externalAction.icon,
                            label: externalAction.label,
                            tonal: externalAction.tonal,
                            loading: _preparingExternalLink,
                          ),
                          if (_prepareExternalLinkError != null)
                            FilledButton.tonalIcon(
                              onPressed: _preparingExternalLink
                                  ? null
                                  : () => _prepareExternalLink(
                                      externalAction,
                                      force: true,
                                    ),
                              icon: const Icon(Icons.refresh),
                              label: Text(context.l10n.actionRetry),
                            ),
                        ],
                      ),
                    ],
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
    if (billing.status == 'pending_checkout') return true;
    if ((billing.status == 'past_due' || billing.status == 'unpaid') &&
        _canManage(billing)) {
      return false;
    }
    return {
      'inactive',
      'canceled',
      'past_due',
      'unpaid',
      'error',
      'not_required',
    }.contains(billing.status);
  }

  String _activateActionLabel(
    BuildContext context,
    BillingConfigViewModel billing,
  ) {
    return context.l10n.billingActivateAction;
  }

  bool _canManage(BillingConfigViewModel billing) {
    if (!billing.canOpenPortal) return false;
    return {'active', 'past_due', 'unpaid'}.contains(billing.status);
  }

  bool _isPendingCheckoutWithoutPayment(BillingConfigViewModel billing) {
    return billing.status == 'pending_checkout' &&
        billing.lastPaymentAt == null;
  }

  bool _isRetryablePendingCheckout(BillingConfigViewModel billing) {
    return _isPendingCheckoutWithoutPayment(billing) &&
        billing.checkoutRetryable &&
        billing.checkoutState != 'started';
  }

  bool _isStartedPendingCheckout(BillingConfigViewModel billing) {
    return _isPendingCheckoutWithoutPayment(billing) &&
        billing.checkoutState == 'started';
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

  _BillingExternalAction? _externalActionForBilling(
    BuildContext context,
    BillingConfigViewModel billing,
  ) {
    if (_canActivate(billing)) {
      return _BillingExternalAction(
        key: 'checkout:create:${billing.status}:${billing.checkoutState}',
        purpose: _BillingExternalPurpose.checkout,
        label: _activateActionLabel(context, billing),
        icon: Icons.arrow_forward,
      );
    }
    if (_canManage(billing)) {
      return _BillingExternalAction(
        key: 'portal:manage',
        purpose: _BillingExternalPurpose.portal,
        label: context.l10n.billingManageAction,
        icon: Icons.manage_accounts_outlined,
        tonal: true,
      );
    }

    return null;
  }

  void _scheduleExternalLinkPreparation(_BillingExternalAction action) {
    if (_preparedActionKey == action.key ||
        _preparingActionKey == action.key ||
        _failedActionKey == action.key) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _prepareExternalLink(action);
    });
  }

  Future<void> _prepareExternalLink(
    _BillingExternalAction action, {
    bool force = false,
  }) async {
    if (!force &&
        (_preparedActionKey == action.key ||
            _preparingActionKey == action.key ||
            _failedActionKey == action.key)) {
      return;
    }

    setState(() {
      _preparingExternalLink = true;
      _preparingActionKey = action.key;
      _preparedActionKey = null;
      _preparedExternalUrl = null;
      _prepareExternalLinkError = null;
      _failedActionKey = null;
    });

    try {
      final businessId = ref.read(currentBusinessIdProvider);
      final repository = ref.read(billingRepositoryProvider);
      final url = switch (action.purpose) {
        _BillingExternalPurpose.checkout =>
          await repository.createCheckoutSession(businessId),
        _BillingExternalPurpose.portal => await repository.createPortalSession(
          businessId,
        ),
      };
      final validatedUrl = _validatedExternalUrl(url);
      if (!mounted) return;
      setState(() {
        _preparedActionKey = action.key;
        _preparedExternalUrl = validatedUrl;
        _prepareExternalLinkError = null;
      });
    } on ApiException catch (e) {
      if (e.statusCode == 409 && e.code == 'subscription_already_exists') {
        ref.invalidate(billingSubscriptionProvider);
      } else if (e.statusCode == 409 && e.code == 'checkout_already_started') {
        ref.invalidate(billingSubscriptionProvider);
      }
      if (!mounted) return;
      setState(() {
        _prepareExternalLinkError = _checkoutErrorMessage(context, e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _prepareExternalLinkError = context.l10n.networkUnknownError;
      });
    } finally {
      if (mounted) {
        setState(() {
          _preparingExternalLink = false;
          if (_prepareExternalLinkError != null) {
            _failedActionKey = action.key;
          }
          _preparingActionKey = null;
        });
      }
    }
  }

  String _checkoutErrorMessage(BuildContext context, ApiException error) {
    if (error.statusCode == 409 &&
        error.code == 'subscription_already_exists') {
      return context.l10n.billingSubscriptionAlreadyExistsError;
    }
    if (error.statusCode == 409 && error.code == 'checkout_already_started') {
      return context.l10n.billingCheckoutAlreadyStartedError;
    }

    return error.message;
  }

  String _validatedExternalUrl(String url) {
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
    return uri.toString();
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
      'pending_checkout' => context.l10n.billingStatusInactive,
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
