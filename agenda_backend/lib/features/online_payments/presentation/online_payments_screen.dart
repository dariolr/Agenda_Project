import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10_extension.dart';
import '../../../core/models/online_payment_account.dart';
import '../../../core/services/same_tab_redirect.dart';
import '../../../core/widgets/feedback_dialog.dart';
import '../../agenda/providers/business_providers.dart';
import '../providers/online_payment_accounts_provider.dart';

class OnlinePaymentsScreen extends ConsumerWidget {
  const OnlinePaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(onlinePaymentAccountsProvider);

    return accountsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          error.toString(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
      data: (accounts) {
        final stripe = _find(accounts, 'stripe');
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [_ProviderCard(account: stripe, providerCode: 'stripe')],
        );
      },
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
}

class _ProviderCard extends ConsumerStatefulWidget {
  const _ProviderCard({required this.providerCode, this.account});

  final String providerCode;
  final OnlinePaymentAccount? account;

  @override
  ConsumerState<_ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends ConsumerState<_ProviderCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final account = widget.account;
    const providerName = 'Stripe';
    final status = account?.onboardingStatus ?? 'not_configured';
    final isActive = status == 'active';
    final isEnabled = account?.isEnabled ?? false;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.credit_card_outlined, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    providerName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StatusChip(label: _statusLabel(context, status)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _statusDescription(context, account),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: _busy ? null : () => _connect(context),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(l10n.onlinePaymentsConnectStripe),
                ),
                OutlinedButton.icon(
                  onPressed: _busy || account == null
                      ? null
                      : () => _sync(context),
                  icon: const Icon(Icons.sync),
                  label: Text(l10n.onlinePaymentsSync),
                ),
                OutlinedButton.icon(
                  onPressed: _busy || account == null
                      ? null
                      : () => _disable(context),
                  icon: const Icon(Icons.link_off),
                  label: Text(l10n.onlinePaymentsDisable),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.onlinePaymentsEnabled),
                    Switch(
                      value: isEnabled,
                      onChanged: _busy || !isActive
                          ? null
                          : (value) => _setEnabled(context, value),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(BuildContext context, String status) {
    final l10n = context.l10n;
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
  ) {
    final l10n = context.l10n;
    if (account == null) return l10n.onlinePaymentsNoApiKeys;
    if (account.isActive && account.isEnabled) {
      return l10n.onlinePaymentsProviderReady;
    }
    if (account.isActive) return l10n.onlinePaymentsProviderCanBeEnabled;
    return l10n.onlinePaymentsProviderNeedsOnboarding;
  }

  Future<void> _connect(BuildContext context) async {
    await _run(context, () async {
      final businessId = ref.read(currentBusinessIdProvider);
      final repository = ref.read(onlinePaymentAccountsRepositoryProvider);
      final url = await repository.createOnboardingLink(
        businessId: businessId,
        providerCode: widget.providerCode,
      );
      ref.invalidate(onlinePaymentAccountsProvider);
      if (url.isNotEmpty) {
        await redirectInCurrentTab(url);
      }
    });
  }

  Future<void> _sync(BuildContext context) async {
    await _run(context, () async {
      final businessId = ref.read(currentBusinessIdProvider);
      await ref
          .read(onlinePaymentAccountsRepositoryProvider)
          .sync(businessId: businessId, providerCode: widget.providerCode);
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

  Future<void> _disable(BuildContext context) async {
    await _run(context, () async {
      final businessId = ref.read(currentBusinessIdProvider);
      await ref
          .read(onlinePaymentAccountsRepositoryProvider)
          .disable(businessId: businessId, providerCode: widget.providerCode);
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: scheme.onSecondaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
