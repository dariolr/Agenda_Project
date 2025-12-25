import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/staff.dart';
import '../../providers/booking_provider.dart';

class StaffStep extends ConsumerWidget {
  const StaffStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final staffAsync = ref.watch(staffProvider);
    final bookingState = ref.watch(bookingFlowProvider);
    final selectedStaff = bookingState.request.selectedStaff;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.staffTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.staffSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),

        // Lista staff
        Expanded(
          child: staffAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(l10n.errorLoadingStaff)),
            data: (staffList) => ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Opzione "Qualsiasi operatore"
                _StaffTile(
                  staff: null,
                  isSelected: selectedStaff == null,
                  onTap: () {
                    ref.read(bookingFlowProvider.notifier).selectStaff(null);
                  },
                ),
                const SizedBox(height: 8),
                // Lista operatori
                ...staffList
                    .where((s) => s.isBookableOnline)
                    .map(
                      (staff) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _StaffTile(
                          staff: staff,
                          isSelected: selectedStaff?.id == staff.id,
                          onTap: () {
                            ref
                                .read(bookingFlowProvider.notifier)
                                .selectStaff(staff);
                          },
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),

        // Footer con bottone
        _buildFooter(context, ref),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () => ref.read(bookingFlowProvider.notifier).nextStep(),
          child: Text(l10n.actionNext),
        ),
      ),
    );
  }
}

class _StaffTile extends StatelessWidget {
  final Staff? staff;
  final bool isSelected;
  final VoidCallback onTap;

  const _StaffTile({
    required this.staff,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: staff == null
                    ? theme.colorScheme.primary.withOpacity(0.1)
                    : theme.colorScheme.secondary.withOpacity(0.1),
                child: staff == null
                    ? Icon(Icons.groups, color: theme.colorScheme.primary)
                    : Text(
                        staff!.initials,
                        style: TextStyle(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff?.displayName ?? l10n.staffAnyOperator,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (staff == null) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.staffAnyOperatorSubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Radio
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
