import 'package:agenda_backend/core/l10n/l10_extension.dart';
import 'package:agenda_backend/core/models/appointment.dart';
import 'package:agenda_backend/core/models/staff.dart';
import 'package:agenda_backend/core/utils/color_utils.dart';
import 'package:agenda_backend/core/widgets/app_buttons.dart';
import 'package:agenda_backend/features/agenda/domain/staff_filter_mode.dart';
import 'package:agenda_backend/features/agenda/mappers/appointments_by_day.dart';
import 'package:agenda_backend/features/agenda/providers/appointment_providers.dart';
import 'package:agenda_backend/features/agenda/providers/business_providers.dart';
import 'package:agenda_backend/features/agenda/providers/date_range_provider.dart';
import 'package:agenda_backend/features/agenda/providers/layout_config_provider.dart';
import 'package:agenda_backend/features/agenda/providers/location_providers.dart';
import 'package:agenda_backend/features/agenda/providers/staff_filter_providers.dart';
import 'package:agenda_backend/features/agenda/providers/tenant_time_provider.dart';
import 'package:agenda_backend/features/agenda/providers/weekly_appointments_provider.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/widgets/appointment_card_base.dart';
import 'package:agenda_backend/features/agenda/presentation/widgets/appointment_dialog.dart';
import 'package:agenda_backend/features/agenda/utils/week_range.dart';
import 'package:agenda_backend/features/services/providers/services_provider.dart';
import 'package:agenda_backend/features/staff/providers/staff_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class WeeklyAppointmentsView extends ConsumerWidget {
  const WeeklyAppointmentsView({
    super.key,
    required this.staffList,
    required this.staffFilterMode,
  });

  final List<Staff> staffList;
  final StaffFilterMode staffFilterMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(currentLocationProvider);
    if (location.id <= 0) {
      return const SizedBox.shrink();
    }

    final business = ref.watch(currentBusinessProvider);
    if (business.id <= 0) {
      return const SizedBox.shrink();
    }

    final anchorDate = ref.watch(agendaDateProvider);
    final timezone = ref.watch(effectiveTenantTimezoneProvider);
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final weekRange = computeWeekRange(
      anchorDate,
      timezone,
      localeTag: localeTag,
    );
    final request = WeeklyAppointmentsRequest(
      weekStart: weekRange.start,
      locationId: location.id,
      businessId: business.id,
    );
    final weeklyAppointmentsAsync = ref.watch(
      weeklyAppointmentsProvider(request),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WeeklyHeader(weekRange: weekRange),
        const SizedBox(height: 12),
        Expanded(
          child: weeklyAppointmentsAsync.when(
            data: (result) => _WeeklyAppointmentsBody(
              weekRange: weekRange,
              appointments: result.appointments,
              staffList: staffList,
              staffFilterMode: staffFilterMode,
            ),
            loading: () => const _WeeklyAppointmentsLoading(),
            error: (_, __) => _WeeklyAppointmentsError(request: request),
          ),
        ),
      ],
    );
  }
}

class _WeeklyHeader extends ConsumerWidget {
  const _WeeklyHeader({required this.weekRange});

  final WeekRange weekRange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      runSpacing: 8,
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(weekRange.label, style: Theme.of(context).textTheme.titleMedium),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppOutlinedActionButton(
              onPressed: ref.read(agendaDateProvider.notifier).previousWeek,
              child: const Icon(Icons.chevron_left),
            ),
            AppOutlinedActionButton(
              onPressed: ref.read(agendaDateProvider.notifier).setToday,
              child: Text(context.l10n.agendaToday),
            ),
            AppOutlinedActionButton(
              onPressed: ref.read(agendaDateProvider.notifier).nextWeek,
              child: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }
}

class _WeeklyAppointmentsBody extends ConsumerWidget {
  const _WeeklyAppointmentsBody({
    required this.weekRange,
    required this.appointments,
    required this.staffList,
    required this.staffFilterMode,
  });

  final WeekRange weekRange;
  final List<Appointment> appointments;
  final List<Staff> staffList;
  final StaffFilterMode staffFilterMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowedStaffIds = staffList.map((staff) => staff.id).toSet();
    final filteredAppointments = [
      for (final appointment in appointments)
        if (allowedStaffIds.contains(appointment.staffId)) appointment,
    ];

    if (staffList.isEmpty) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.94),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                staffFilterMode == StaffFilterMode.onDutyTeam
                    ? context.l10n.agendaNoOnDutyTeamTitle
                    : context.l10n.agendaNoSelectedTeamTitle,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (staffFilterMode != StaffFilterMode.allTeam) ...[
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    ref
                        .read(staffFilterModeProvider.notifier)
                        .set(StaffFilterMode.allTeam);
                  },
                  child: Text(context.l10n.agendaShowAllTeamButton),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final appointmentsByDay = mapAppointmentsByDay(
      filteredAppointments,
      weekRange: weekRange,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final useHorizontalCards = constraints.maxWidth < 1040;
        if (useHorizontalCards) {
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: weekRange.days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final day = weekRange.days[index];
              return SizedBox(
                width: 280,
                child: _WeeklyDayColumn(
                  day: day,
                  appointments: appointmentsByDay[day] ?? const [],
                ),
              );
            },
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < weekRange.days.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: _WeeklyDayColumn(
                  day: weekRange.days[i],
                  appointments:
                      appointmentsByDay[weekRange.days[i]] ?? const [],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _WeeklyDayColumn extends ConsumerWidget {
  const _WeeklyDayColumn({required this.day, required this.appointments});

  final DateTime day;
  final List<Appointment> appointments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final label = DateFormat('EEE d', localeTag).format(day);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: appointments.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        context.l10n.clientAppointmentsEmpty,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: appointments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final appointment = appointments[index];
                      return _WeeklyAppointmentTile(
                        day: day,
                        appointment: appointment,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyAppointmentTile extends ConsumerWidget {
  const _WeeklyAppointmentTile({required this.day, required this.appointment});

  static const _tileHeight = 74.0;

  final DateTime day;
  final Appointment appointment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _resolveAppointmentColor(context, ref, appointment);
    final dayEndExclusive = DateUtils.dateOnly(
      day,
    ).add(const Duration(days: 1));
    final spansNextDay = appointment.endTime.isAfter(dayEndExclusive);

    return SizedBox(
      height: _tileHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AppointmentCard(appointment: appointment, color: color),
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _handleTap(context, ref),
            ),
          ),
          if (spansNextDay)
            Positioned(
              top: 6,
              right: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.2),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    '+1g',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _resolveAppointmentColor(
    BuildContext context,
    WidgetRef ref,
    Appointment currentAppointment,
  ) {
    final staff = ref
        .watch(staffForCurrentLocationProvider)
        .cast<Staff?>()
        .firstWhere(
          (entry) => entry?.id == currentAppointment.staffId,
          orElse: () => null,
        );
    final fallbackColor =
        staff?.color ?? Theme.of(context).colorScheme.primary.withOpacity(0.8);

    final layoutConfig = ref.watch(layoutConfigProvider);
    if (!layoutConfig.useServiceColorsForAppointments) {
      return fallbackColor;
    }

    final variantsAsync = ref.watch(serviceVariantsProvider);
    if (variantsAsync.isLoading && !variantsAsync.hasValue) {
      return Theme.of(context).colorScheme.primary;
    }

    final variants = variantsAsync.value ?? const [];
    final serviceColorMap = <int, Color>{};
    for (final variant in variants) {
      final colorHex = variant.colorHex;
      if (colorHex == null || colorHex.isEmpty) continue;
      serviceColorMap[variant.serviceId] = ColorUtils.fromHex(colorHex);
    }

    return serviceColorMap[currentAppointment.serviceId] ?? fallbackColor;
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    await showAppointmentDialog(context, ref, initial: appointment);
    if (!context.mounted) return;

    ref.invalidate(appointmentsProvider);

    final location = ref.read(currentLocationProvider);
    final business = ref.read(currentBusinessProvider);
    if (location.id <= 0 || business.id <= 0) return;

    final anchorDate = ref.read(agendaDateProvider);
    final timezone = ref.read(effectiveTenantTimezoneProvider);
    final weekRange = computeWeekRange(anchorDate, timezone);
    ref.invalidate(
      weeklyAppointmentsProvider(
        WeeklyAppointmentsRequest(
          weekStart: weekRange.start,
          locationId: location.id,
          businessId: business.id,
        ),
      ),
    );
  }
}

class _WeeklyAppointmentsLoading extends StatelessWidget {
  const _WeeklyAppointmentsLoading();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useHorizontalCards = constraints.maxWidth < 1040;
        final cards = List<Widget>.generate(
          7,
          (_) => DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.16),
              ),
            ),
            child: const SizedBox.expand(),
          ),
        );

        if (useHorizontalCards) {
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, index) =>
                SizedBox(width: 280, child: cards[index]),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: cards[i]),
            ],
          ],
        );
      },
    );
  }
}

class _WeeklyAppointmentsError extends ConsumerWidget {
  const _WeeklyAppointmentsError({required this.request});

  final WeeklyAppointmentsRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.agendaWeeklyLoadError, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          AppOutlinedActionButton(
            onPressed: () =>
                ref.invalidate(weeklyAppointmentsProvider(request)),
            child: Text(context.l10n.actionRetry),
          ),
        ],
      ),
    );
  }
}
