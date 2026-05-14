import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10_extension.dart';
import '../../../core/models/online_payment_account.dart';
import '../../../core/widgets/app_switch.dart';
import '../../../core/widgets/external_link.dart';
import '../../../core/widgets/stripe_icon.dart';
import '../../../core/widgets/feedback_dialog.dart';
import '../../agenda/providers/business_providers.dart';
import '../providers/online_payment_accounts_provider.dart';

class OnlinePaymentsScreen extends ConsumerStatefulWidget {
  const OnlinePaymentsScreen({super.key});

  @override
  ConsumerState<OnlinePaymentsScreen> createState() =>
      _OnlinePaymentsScreenState();
}

class _OnlinePaymentsScreenState extends ConsumerState<OnlinePaymentsScreen>
    with WidgetsBindingObserver {
  bool _syncedOnMount = false;
  bool _syncing = false;
  List<OnlinePaymentAccount> _lastAccounts = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _syncAndInvalidate();
  }

  Future<void> _syncAndInvalidate() async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId <= 0) return;
    if (mounted) setState(() => _syncing = true);
    try {
      for (var attempt = 0; attempt < 4; attempt += 1) {
        if (attempt > 0) {
          await Future<void>.delayed(const Duration(seconds: 2));
          if (!mounted) return;
        }
        try {
          await ref
              .read(onlinePaymentAccountsRepositoryProvider)
              .sync(businessId: businessId, providerCode: 'stripe');
        } catch (_) {}
        if (!mounted) return;
        final accounts = await ref.refresh(
          onlinePaymentAccountsProvider.future,
        );
        _lastAccounts = accounts;
        if (_stripeIsReady(accounts) ||
            _stripeIsManuallyDisconnected(accounts)) {
          break;
        }
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(onlinePaymentAccountsProvider);
    final visibleAccounts = accountsAsync.value ?? _lastAccounts;
    if (accountsAsync.hasValue) {
      _lastAccounts = accountsAsync.value ?? const [];
    }

    if (accountsAsync.isLoading && visibleAccounts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (accountsAsync.hasError && visibleAccounts.isEmpty) {
      final error = accountsAsync.error;
      return Center(
        child: Text(
          error.toString(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      );
    }

    if (!_syncedOnMount && accountsAsync.hasValue) {
      _syncedOnMount = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncAndInvalidate();
      });
    }

    final stripe = _find(visibleAccounts, 'stripe');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _ProviderCard(
          account: stripe,
          providerCode: 'stripe',
          syncing: _syncing,
        ),
      ],
    );
  }

  OnlinePaymentAccount? _find(
    List<OnlinePaymentAccount> accounts,
    String code,
  ) {
    for (final account in accounts) {
      if (account.providerCode == code) return account;
    }
    return null;
  }

  bool _stripeIsReady(List<OnlinePaymentAccount> accounts) {
    final stripe = _find(accounts, 'stripe');
    return stripe != null &&
        stripe.onboardingStatus == 'active' &&
        stripe.chargesEnabled &&
        stripe.detailsSubmitted;
  }

  bool _stripeIsManuallyDisconnected(List<OnlinePaymentAccount> accounts) {
    final stripe = _find(accounts, 'stripe');
    return stripe?.onboardingStatus == 'disabled';
  }
}

class _ProviderCard extends ConsumerStatefulWidget {
  const _ProviderCard({
    required this.providerCode,
    this.account,
    this.syncing = false,
  });

  final String providerCode;
  final OnlinePaymentAccount? account;
  final bool syncing;

  @override
  ConsumerState<_ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends ConsumerState<_ProviderCard> {
  bool _busy = false;
  bool _loadingOnboardingUrl = false;
  String? _onboardingUrl;
  bool _onboardingUrlFailed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final account = widget.account;
    final status = account?.onboardingStatus ?? 'not_configured';
    final isConnected =
        account != null &&
        status == 'active' &&
        account.chargesEnabled &&
        account.detailsSubmitted;
    final isEnabled = account?.isEnabled ?? false;
    final isBusy = _busy || widget.syncing;

    if (!isConnected && !widget.syncing) _scheduleOnboardingUrlFetch();

    final connectIcon = _loadingOnboardingUrl
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.open_in_new);

    final ctaButton = isConnected
        ? OutlinedButton.icon(
            onPressed: isBusy ? null : () => _disable(context),
            icon: const Icon(Icons.link_off),
            label: Text(l10n.onlinePaymentsDisconnectStripe),
          )
        : ExternalLink(
            url: isBusy || widget.syncing || _loadingOnboardingUrl
                ? null
                : _onboardingUrl,
            builder: (ctx, open) => FilledButton.icon(
              onPressed: open == null
                  ? null
                  : () {
                      setState(() => _onboardingUrl = null);
                      ref.invalidate(onlinePaymentAccountsProvider);
                      open();
                    },
              icon: connectIcon,
              label: Text(l10n.onlinePaymentsConnectStripe),
            ),
          );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const StripeIcon(size: 36),
                    const Spacer(),
                    Tooltip(
                      message: l10n.onlinePaymentsSyncingStatus,
                      child: AnimatedOpacity(
                        opacity: widget.syncing ? 1 : 0,
                        duration: const Duration(milliseconds: 160),
                        child: SizedBox.square(
                          dimension: 18,
                          child: widget.syncing
                              ? CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: scheme.primary,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (isConnected)
                      _StatusChip(label: _statusLabel(context, account)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _statusDescription(context, account, widget.syncing),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if ((account?.lastErrorMessage ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    account!.lastErrorMessage!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: scheme.error),
                  ),
                ],
                const SizedBox(height: 16),
                Align(alignment: Alignment.centerLeft, child: ctaButton),
                if (isConnected) ...[
                  const SizedBox(height: 16),
                  _ProviderEnableControl(
                    isEnabled: isEnabled,
                    isBusy: isBusy || widget.syncing,
                    onChanged: (value) => _setEnabled(context, value),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _scheduleOnboardingUrlFetch() {
    if (_onboardingUrl != null ||
        _loadingOnboardingUrl ||
        _onboardingUrlFailed) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fetchOnboardingUrl();
    });
  }

  Future<void> _fetchOnboardingUrl() async {
    if (_loadingOnboardingUrl ||
        _onboardingUrl != null ||
        _onboardingUrlFailed) {
      return;
    }
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId <= 0) return;
    setState(() => _loadingOnboardingUrl = true);
    try {
      final repository = ref.read(onlinePaymentAccountsRepositoryProvider);
      final url = await repository.createOnboardingLink(
        businessId: businessId,
        providerCode: widget.providerCode,
      );
      if (!mounted) return;
      if (url.isNotEmpty) {
        setState(() => _onboardingUrl = url);
      }
    } catch (error) {
      if (mounted) setState(() => _onboardingUrlFailed = true);
      if (context.mounted) {
        await FeedbackDialog.showError(
          context,
          title: context.l10n.onlinePaymentsTitle,
          message: error.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingOnboardingUrl = false);
    }
  }

  String _statusLabel(BuildContext context, OnlinePaymentAccount? account) {
    final l10n = context.l10n;
    if (account != null &&
        account.isActive &&
        account.chargesEnabled &&
        account.detailsSubmitted &&
        !account.isEnabled) {
      return l10n.onlinePaymentsStatusConnectedPaused;
    }
    final status = account?.onboardingStatus ?? 'not_configured';
    return switch (status) {
      'active' => l10n.onlinePaymentsStatusActive,
      'disabled' => l10n.onlinePaymentsStatusDisabled,
      'pending' => l10n.onlinePaymentsStatusIncomplete,
      'restricted' => l10n.onlinePaymentsStatusRequiresVerification,
      _ => l10n.onlinePaymentsStatusDisabled,
    };
  }

  String _statusDescription(
    BuildContext context,
    OnlinePaymentAccount? account,
    bool syncing,
  ) {
    final l10n = context.l10n;
    if (syncing) return l10n.onlinePaymentsSyncingStatus;
    if (account == null) return l10n.onlinePaymentsNoApiKeys;
    if (account.isActive &&
        account.chargesEnabled &&
        account.detailsSubmitted) {
      return l10n.onlinePaymentsProviderConnected;
    }
    return l10n.onlinePaymentsProviderNeedsOnboarding;
  }

  Future<void> _disable(BuildContext context) async {
    await _run(context, () async {
      final businessId = ref.read(currentBusinessIdProvider);
      await ref
          .read(onlinePaymentAccountsRepositoryProvider)
          .disable(businessId: businessId, providerCode: widget.providerCode);
      ref.invalidate(onlinePaymentAccountsProvider);
    });
  }

  Future<void> _setEnabled(BuildContext context, bool value) async {
    await _run(context, () async {
      final businessId = ref.read(currentBusinessIdProvider);
      await ref
          .read(onlinePaymentAccountsRepositoryProvider)
          .setEnabled(
            businessId: businessId,
            providerCode: widget.providerCode,
            isEnabled: value,
          );
      ref.invalidate(onlinePaymentAccountsProvider);
    });
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (context.mounted) {
        await FeedbackDialog.showError(
          context,
          title: context.l10n.onlinePaymentsTitle,
          message: error.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _ProviderEnableControl extends StatelessWidget {
  const _ProviderEnableControl({
    required this.isEnabled,
    required this.isBusy,
    required this.onChanged,
  });

  final bool isEnabled;
  final bool isBusy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x1F000000)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEnabled
                        ? l10n.onlinePaymentsAcceptanceEnabled
                        : l10n.onlinePaymentsAcceptanceDisabled,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isEnabled
                        ? l10n.onlinePaymentsAcceptanceEnabledDescription
                        : l10n.onlinePaymentsAcceptanceDisabledDescription,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AppSwitch(value: isEnabled, onChanged: isBusy ? null : onChanged),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
