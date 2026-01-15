import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/staff.dart';
import '../../providers/booking_provider.dart';

class StaffStep extends ConsumerStatefulWidget {
  const StaffStep({super.key});

  @override
  ConsumerState<StaffStep> createState() => _StaffStepState();
}

class _StaffStepState extends ConsumerState<StaffStep> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final staffAsync = ref.watch(staffProvider);
    final bookingState = ref.watch(bookingFlowProvider);
    final bookingConfig = ref.watch(bookingConfigProvider);
    final selectedStaff = bookingState.request.selectedStaff;
    final services = bookingState.request.services;
    final selectedStaffByService = bookingState.request.selectedStaffByService;
    final anyOperatorSelected = bookingState.request.anyOperatorSelected;
    // Multi-staff UI solo se abilitata E più servizi selezionati
    final showMultiStaffUI =
        bookingConfig.allowMultiStaffBooking && services.length > 1;
    final isLoading = staffAsync.isLoading || bookingState.isLoading;

    return Stack(
      children: [
        Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.staffTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
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
                loading: () => const SizedBox.shrink(),
                error: (e, _) => Center(child: Text(l10n.errorLoadingStaff)),
                data: (staffList) {
                  if (staffList.isEmpty) {
                    return Center(child: Text(l10n.staffEmpty));
                  }

                  // UI multi-staff: permette di selezionare staff diversi per servizi diversi
                  // NOTA: Temporaneamente disabilitata (allowMultiStaffBooking = false)
                  if (showMultiStaffUI) {
                    final staffByService = <int, List<Staff>>{};
                    for (final service in services) {
                      final eligible =
                          staffList
                              .where((s) => s.serviceIds.contains(service.id))
                              .toList()
                            ..sort(
                              (a, b) => a.sortOrder.compareTo(b.sortOrder),
                            );
                      staffByService[service.id] = eligible;
                    }

                    final hasEmpty = staffByService.values.any(
                      (list) => list.isEmpty,
                    );
                    if (hasEmpty) {
                      return Center(child: Text(l10n.staffEmpty));
                    }

                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _StaffTile(
                          staff: null,
                          isSelected: anyOperatorSelected,
                          onTap: () {
                            ref
                                .read(bookingFlowProvider.notifier)
                                .selectAnyOperatorForAllServices(
                                  staffByService,
                                );
                          },
                        ),
                        const SizedBox(height: 16),
                        for (final service in services) ...[
                          Text(
                            service.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...staffByService[service.id]!.map(
                            (staff) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _StaffTile(
                                staff: staff,
                                isSelected:
                                    selectedStaffByService[service.id]?.id ==
                                    staff.id,
                                onTap: () {
                                  ref
                                      .read(bookingFlowProvider.notifier)
                                      .selectStaffForService(service, staff);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    );
                  }

                  // UI standard: un solo staff per tutti i servizi
                  // Filtra solo staff che possono fare TUTTI i servizi selezionati
                  final eligibleStaff = services.length > 1
                      ? staffList
                            .where(
                              (staff) => services.every(
                                (s) => staff.serviceIds.contains(s.id),
                              ),
                            )
                            .toList()
                      : staffList;

                  if (eligibleStaff.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.noStaffForAllServices,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    );
                  }

                  // Se c'è un solo staff idoneo, auto-selezionalo
                  if (eligibleStaff.length == 1 && selectedStaff == null) {
                    // Auto-selezione differita per evitare rebuild durante build
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ref
                          .read(bookingFlowProvider.notifier)
                          .autoSelectStaff(eligibleStaff.first);
                    });
                  }

                  // Se c'è un solo staff, mostra solo quello (già selezionato)
                  if (eligibleStaff.length == 1) {
                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _StaffTile(
                          staff: eligibleStaff.first,
                          isSelected:
                              true, // Sempre selezionato quando è l'unico
                          onTap: null, // Non cliccabile, è l'unica opzione
                        ),
                      ],
                    );
                  }

                  // Più staff disponibili: mostra "Qualsiasi" + lista
                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // Opzione "Qualsiasi operatore"
                      _StaffTile(
                        staff: null,
                        isSelected: anyOperatorSelected,
                        onTap: () {
                          ref
                              .read(bookingFlowProvider.notifier)
                              .selectAnyOperator();
                        },
                      ),
                      const SizedBox(height: 8),
                      // Lista operatori
                      ...eligibleStaff.map(
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
                  );
                },
              ),
            ),

            // Footer con bottone
            _buildFooter(context, ref),
          ],
        ),
        if (isLoading)
          Positioned.fill(
            child: ColoredBox(
              color: theme.colorScheme.surface.withOpacity(0.6),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final bookingState = ref.watch(bookingFlowProvider);
    final staffAsync = ref.watch(staffProvider);

    // Logica semplificata: il pulsante è abilitato se:
    // 1. "Qualsiasi operatore" è selezionato (selectedStaff == null e anyOperatorSelected == true)
    // 2. Uno staff specifico è selezionato (selectedStaff != null)
    // 3. C'è un solo staff disponibile (auto-selezionato)
    final selectedStaff = bookingState.request.selectedStaff;
    final anyOperatorSelected = bookingState.request.anyOperatorSelected;

    // Conta gli staff idonei
    final eligibleStaffCount = staffAsync.maybeWhen(
      data: (staffList) {
        final services = bookingState.request.services;
        if (services.length > 1) {
          return staffList
              .where(
                (staff) =>
                    services.every((s) => staff.serviceIds.contains(s.id)),
              )
              .length;
        }
        return staffList.length;
      },
      orElse: () => 0,
    );

    // canProceed: staff selezionato OPPURE "qualsiasi" OPPURE un solo staff (auto)
    final canProceed =
        selectedStaff != null || anyOperatorSelected || eligibleStaffCount == 1;

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
          onPressed: canProceed
              ? () => ref.read(bookingFlowProvider.notifier).nextStep()
              : null,
          child: Text(l10n.actionNext),
        ),
      ),
    );
  }
}

class _StaffTile extends StatelessWidget {
  final Staff? staff;
  final bool isSelected;
  final VoidCallback? onTap;

  const _StaffTile({required this.staff, required this.isSelected, this.onTap});

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
