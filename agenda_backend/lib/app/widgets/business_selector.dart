import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/business.dart';
import '../../features/agenda/providers/business_providers.dart';
import '../../features/business/providers/superadmin_selected_business_provider.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Selettore business per superadmin.
/// Mostra nel leading della NavigationRail.
class BusinessSelector extends ConsumerWidget {
  const BusinessSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isSuperadmin = authState.user?.isSuperadmin ?? false;

    // Solo superadmin vede il selettore
    if (!isSuperadmin) return const SizedBox.shrink();

    final businessesAsync = ref.watch(businessesProvider);
    final currentBusinessId = ref.watch(currentBusinessIdProvider);

    return businessesAsync.when(
      data: (businesses) => _BusinessDropdown(
        businesses: businesses,
        currentBusinessId: currentBusinessId,
        onChanged: (id) {
          ref.read(currentBusinessIdProvider.notifier).set(id);
          ref.read(superadminSelectedBusinessProvider.notifier).select(id);
        },
      ),
      loading: () => const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _BusinessDropdown extends StatelessWidget {
  const _BusinessDropdown({
    required this.businesses,
    required this.currentBusinessId,
    required this.onChanged,
  });

  final List<Business> businesses;
  final int currentBusinessId;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (businesses.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentBusiness = businesses.firstWhere(
      (b) => b.id == currentBusinessId,
      orElse: () => businesses.first,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: PopupMenuButton<int>(
        offset: const Offset(56, 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tooltip: 'Seleziona business',
        onSelected: onChanged,
        itemBuilder: (context) => businesses.map((b) {
          final isSelected = b.id == currentBusinessId;
          return PopupMenuItem<int>(
            value: b.id,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: isSelected
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  child: Text(
                    b.name.isNotEmpty ? b.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    b.name,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check, size: 18, color: colorScheme.primary),
              ],
            ),
          );
        }).toList(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              currentBusiness.name.isNotEmpty
                  ? currentBusiness.name[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
