import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/route_slug_provider.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/network/network_providers.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/business_provider.dart';

/// Banner che appare quando l'utente è autenticato per un business diverso
/// da quello corrente (URL slug).
///
/// Mostra un avviso e permette all'utente di fare logout e login nel business
/// corrente.
class WrongBusinessAuthBanner extends ConsumerWidget {
  const WrongBusinessAuthBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    // Verifica se l'utente è autenticato per un business diverso
    final isWrongBusiness = ref.watch(
      isAuthenticatedForDifferentBusinessProvider,
    );
    final isAuthenticated = ref.watch(
      authProvider.select((state) => state.isAuthenticated),
    );
    final currentBusiness = ref.watch(currentBusinessProvider).value;
    final slug = ref.watch(routeSlugProvider);

    // Non mostrare se:
    // - Non è autenticato
    // - È autenticato per il business corretto
    // - Dati non ancora caricati
    if (!isAuthenticated ||
        !isWrongBusiness.hasValue ||
        isWrongBusiness.value != true) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withAlpha((0.3 * 255).round()),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: theme.colorScheme.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.wrongBusinessAuthTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.wrongBusinessAuthMessage(currentBusiness?.name ?? ''),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _handleLogoutAndLogin(context, ref, slug),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                    icon: const Icon(Icons.logout, size: 18),
                    label: Text(l10n.wrongBusinessAuthAction),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogoutAndLogin(
    BuildContext context,
    WidgetRef ref,
    String? slug,
  ) async {
    if (slug == null) return;

    // Ottieni il businessId corrente per il logout
    final currentBusinessId = ref.read(currentBusinessIdProvider);
    if (currentBusinessId != null) {
      await ref
          .read(authProvider.notifier)
          .logout(businessId: currentBusinessId);
    }

    // Invalida il provider per forzare il refresh dello stato auth
    ref.invalidate(authenticatedBusinessIdProvider);

    // Naviga al login
    if (context.mounted) {
      context.go('/$slug/login');
    }
  }
}
