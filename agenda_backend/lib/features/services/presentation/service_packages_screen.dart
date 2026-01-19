import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10_extension.dart';
import '../../../core/utils/price_utils.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/feedback_dialog.dart';
import '../providers/service_categories_provider.dart';
import '../providers/service_packages_provider.dart';
import '../providers/services_provider.dart';
import 'dialogs/service_package_dialog.dart';

class ServicePackagesScreen extends ConsumerWidget {
  const ServicePackagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packagesAsync = ref.watch(servicePackagesProvider);
    final servicesAsync = ref.watch(servicesProvider);
    final categories = ref.watch(serviceCategoriesProvider);
    final l10n = context.l10n;

    if (packagesAsync.isLoading || servicesAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final packages = packagesAsync.value ?? [];
    final services = servicesAsync.value ?? [];

    if (packages.isEmpty) {
      return Center(
        child: Text(
          l10n.servicePackagesEmptyState,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: packages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final pkg = packages[index];
        final currency = PriceFormatter.effectiveCurrency(ref);
        final price = PriceFormatter.format(
          context: context,
          amount: pkg.effectivePrice,
          currencyCode: currency,
        );
        final duration = pkg.effectiveDurationMinutes;

        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pkg.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (!pkg.isActive)
                      _StatusBadge(
                        label: l10n.servicePackageInactiveLabel,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    if (pkg.isBroken)
                      _StatusBadge(
                        label: l10n.servicePackageBrokenLabel,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: l10n.actionEdit,
                      onPressed: () => showServicePackageDialog(
                        context,
                        ref,
                        services: services,
                        categories: categories,
                        package: pkg,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: l10n.actionDelete,
                      onPressed: () async {
                        await showAppConfirmDialog(
                          context,
                          title: Text(l10n.servicePackageDeleteTitle),
                          content: Text(l10n.servicePackageDeleteMessage),
                          confirmLabel: l10n.actionDelete,
                          danger: true,
                          onConfirm: () async {
                            try {
                              await ref
                                  .read(servicePackagesProvider.notifier)
                                  .deletePackage(pkg.id);
                              if (!context.mounted) return;
                              FeedbackDialog.showSuccess(
                                context,
                                title: l10n.servicePackageDeletedTitle,
                                message: l10n.servicePackageDeletedMessage,
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              FeedbackDialog.showError(
                                context,
                                title: l10n.errorTitle,
                                message: l10n.servicePackageDeleteError,
                              );
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${pkg.serviceCount} ${l10n.servicesLabel} · $duration ${l10n.minutesLabel} · $price',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (pkg.description != null &&
                    pkg.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    pkg.description!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final item in pkg.items)
                      Chip(
                        label: Text(
                          item.name ?? '#${item.serviceId}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: AppOutlinedActionButton(
                    onPressed: () => showServicePackageDialog(
                      context,
                      ref,
                      services: services,
                      categories: categories,
                      package: pkg,
                    ),
                    child: Text(l10n.actionEdit),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
