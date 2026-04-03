import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10_extension.dart';
import '../../../core/models/business_payment_method.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/feedback_dialog.dart';
import '../../agenda/providers/business_providers.dart';
import '../../auth/providers/current_business_user_provider.dart';
import 'dialogs/payment_method_dialog.dart';
import '../providers/payment_methods_provider.dart';

class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() =>
      _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  bool _isPersistingOrder = false;

  @override
  Widget build(BuildContext context) {
    final methodsAsync = ref.watch(paymentMethodsProvider);
    final canManageSettings = ref.watch(canManageBusinessSettingsProvider);

    return methodsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          error.toString(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
      data: (methods) {
        final sortedMethods = methods.toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        return Column(
          children: [
            Expanded(
              child: sortedMethods.isEmpty
                  ? Center(
                      child: Text(
                        context.l10n.paymentMethodsEmpty,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : canManageSettings
                  ? ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      buildDefaultDragHandles: false,
                      // Evita il proxy Material di default che crea un artefatto
                      // (rettangolo/ombra) durante il trascinamento.
                      proxyDecorator: (child, index, animation) => child,
                      itemCount: sortedMethods.length,
                      onReorder: (oldIndex, newIndex) =>
                          _onReorder(sortedMethods, oldIndex, newIndex),
                      itemBuilder: (context, index) {
                        final method = sortedMethods[index];
                        return ReorderableDelayedDragStartListener(
                          key: ValueKey('payment-method-${method.id}'),
                          index: index,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _MethodTile(
                            method: method,
                            canManage: true,
                            onTap: () => showPaymentMethodDialog(
                              context,
                              ref,
                              existing: method,
                            ),
                              onDelete: () =>
                                  _confirmDelete(context, ref, method),
                              dragHandle: const Icon(Icons.drag_indicator),
                            ),
                          ),
                        );
                      },
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: sortedMethods.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final method = sortedMethods[index];
                        return _MethodTile(
                          method: method,
                          canManage: false,
                          onTap: null,
                          onDelete: null,
                          dragHandle: null,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onReorder(
    List<BusinessPaymentMethod> methods,
    int oldIndex,
    int newIndex,
  ) async {
    if (_isPersistingOrder) return;

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    if (oldIndex == newIndex) return;

    final reordered = methods.toList();
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    setState(() => _isPersistingOrder = true);

    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId <= 0) {
      if (mounted) setState(() => _isPersistingOrder = false);
      return;
    }

    try {
      final repository = ref.read(paymentMethodsRepositoryProvider);
      for (int i = 0; i < reordered.length; i++) {
        final method = reordered[i];
        final nextSortOrder = (i + 1) * 10;
        if (method.sortOrder == nextSortOrder) continue;
        await repository.update(
          businessId: businessId,
          methodId: method.id,
          name: method.name,
          sortOrder: nextSortOrder,
        );
      }

      ref.invalidate(paymentMethodsProvider);
      ref.invalidate(paymentMethodsWithInactiveProvider);
    } catch (e) {
      if (!mounted) return;
      await FeedbackDialog.showError(
        context,
        title: context.l10n.paymentMethodsTitle,
        message: e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _isPersistingOrder = false);
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    BusinessPaymentMethod method,
  ) async {
    await showAppConfirmDialog(
      context,
      title: Text(context.l10n.paymentMethodsDeleteTitle),
      content: Text(context.l10n.paymentMethodsDeleteMessage(method.name)),
      confirmLabel: context.l10n.actionDelete,
      cancelLabel: context.l10n.actionCancel,
      danger: true,
      onConfirm: () async {
        final businessId = ref.read(currentBusinessIdProvider);
        if (businessId <= 0) return;

        try {
          await ref
              .read(paymentMethodsRepositoryProvider)
              .delete(businessId: businessId, methodId: method.id);
          ref.invalidate(paymentMethodsProvider);
          ref.invalidate(paymentMethodsWithInactiveProvider);
        } catch (e) {
          if (!context.mounted) return;
          await FeedbackDialog.showError(
            context,
            title: context.l10n.paymentMethodsTitle,
            message: e.toString(),
          );
        }
      },
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.method,
    required this.canManage,
    required this.onTap,
    required this.onDelete,
    required this.dragHandle,
  });

  final BusinessPaymentMethod method;
  final bool canManage;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final Widget? dragHandle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.payments_outlined, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  method.code,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (canManage && onDelete != null)
            IconButton(
              tooltip: context.l10n.actionDelete,
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          if (canManage && dragHandle != null) dragHandle!,
        ],
      ),
    );

    if (!canManage || onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: content,
      ),
    );
  }
}
