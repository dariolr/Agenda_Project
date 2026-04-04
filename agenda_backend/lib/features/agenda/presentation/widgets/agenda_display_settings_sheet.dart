import 'package:agenda_backend/app/providers/form_factor_provider.dart';
import 'package:agenda_backend/core/l10n/l10_extension.dart';
import 'package:agenda_backend/core/models/appointment.dart';
import 'package:agenda_backend/core/widgets/app_buttons.dart';
import 'package:agenda_backend/core/widgets/app_dialogs.dart';
import 'package:agenda_backend/core/widgets/app_form.dart';
import 'package:agenda_backend/features/agenda/providers/appointment_providers.dart';
import 'package:agenda_backend/features/agenda/providers/agenda_display_settings_provider.dart';
import 'package:agenda_backend/features/agenda/providers/business_providers.dart';
import 'package:agenda_backend/features/agenda/providers/calendar_view_mode_provider.dart';
import 'package:agenda_backend/features/agenda/providers/date_range_provider.dart';
import 'package:agenda_backend/features/agenda/providers/location_providers.dart';
import 'package:agenda_backend/features/agenda/providers/weekly_appointments_provider.dart';
import 'package:agenda_backend/features/services/providers/services_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showAgendaDisplaySettingsSheet(BuildContext context) async {
  final formFactor = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(formFactorProvider);
  final isDesktop = formFactor == AppFormFactor.desktop;
  await showAppFormDialog<void>(
    context,
    useRootNavigator: true,
    bottomSheetHeightFactor: null,
    bottomSheetMaxHeightFactor: isDesktop ? null : 0.78,
    builder: (_) => const _AgendaDisplaySettingsSheetContent(),
  );
}

class _AgendaDisplaySettingsSheetContent extends ConsumerWidget {
  const _AgendaDisplaySettingsSheetContent();
  static const double _titleToFirstSettingSpacing = 52;
  static const double _sectionSpacing = 30;
  static const double _radioGroupTopSpacing = 10;
  static const double _radioItemSpacing = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingLabelStyle = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600);
    final formFactor = ref.watch(formFactorProvider);
    final isDesktop = formFactor == AppFormFactor.desktop;
    final settings = ref.watch(agendaDisplaySettingsProvider);
    final showPrices = ref.watch(effectiveShowAppointmentPriceInCardProvider);
    // final showCancelled = ref.watch(effectiveShowCancelledAppointmentsProvider);
    final useServiceColors = ref.watch(
      effectiveUseServiceColorsForAppointmentsProvider,
    );
    final calendarViewMode = ref.watch(calendarViewModeProvider);
    final agendaDate = ref.watch(agendaDateProvider);
    final location = ref.watch(currentLocationProvider);
    final business = ref.watch(currentBusinessProvider);
    final services = ref.watch(servicesProvider).value ?? const [];
    final hasAnyServiceWithAdditionalTime = services.any(
      (service) => (service.processingTime ?? 0) > 0 || (service.blockedTime ?? 0) > 0,
    );
    final hasAnyAppointmentWithAdditionalTime = switch (calendarViewMode) {
      CalendarViewMode.day => _hasAnyAppointmentWithAdditionalTime(
          ref.watch(appointmentsProvider).value ?? const [],
        ),
      CalendarViewMode.week => () {
          if (location.id <= 0 || business.id <= 0) return false;
          final selectedDate = DateUtils.dateOnly(agendaDate);
          final weekStart = selectedDate.subtract(
            Duration(days: selectedDate.weekday - DateTime.monday),
          );
          final request = WeeklyAppointmentsRequest(
            weekStart: weekStart,
            locationId: location.id,
            businessId: business.id,
          );
          final weeklyAppointments = ref.watch(
            weeklyAppointmentsProvider(request),
          );
          return _hasAnyAppointmentWithAdditionalTime(
            weeklyAppointments.value?.appointments ?? const [],
          );
        }(),
    };
    final showExtraMinutesBandIntensitySetting =
        hasAnyServiceWithAdditionalTime ||
        hasAnyAppointmentWithAdditionalTime;
    final notifier = ref.read(agendaDisplaySettingsProvider.notifier);
    final hoverUnrelatedVisualIntensity =
        (1.0 - settings.hoverUnrelatedCardDimIntensity).clamp(0.0, 1.0);

    return AppFormScaffold(
      title: Text(context.l10n.agendaDisplaySettingsSuperadminTitle),
      dialogMinWidth: 0,
      dialogMaxWidth: 620,
      dialogInsetPadding: const EdgeInsets.symmetric(
        horizontal: 32,
        vertical: 24,
      ),
      dialogPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      mobileActionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: _titleToFirstSettingSpacing),
          Text(
            context.l10n.agendaDisplaySettingsCardTextZoomLabel,
            style: settingLabelStyle,
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  notifier.setCardTextScale(settings.cardTextScale - 0.05);
                },
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Slider(
                  min: 0.5,
                  max: 1.5,
                  divisions: 20,
                  value: settings.cardTextScale,
                  onChanged: notifier.setCardTextScale,
                ),
              ),
              IconButton(
                onPressed: () {
                  notifier.setCardTextScale(settings.cardTextScale + 0.05);
                },
                icon: const Icon(Icons.add),
              ),
              const SizedBox(width: 6),
              Text('${(settings.cardTextScale * 100).round()}%'),
            ],
          ),
          const SizedBox(height: _sectionSpacing),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              context.l10n.agendaDisplaySettingsShowPricesLabel,
              style: settingLabelStyle,
            ),
            value: showPrices,
            onChanged: notifier.setShowPricesOverride,
          ),
          // const SizedBox(height: _sectionSpacing),
          // SwitchListTile.adaptive(
          //   contentPadding: EdgeInsets.zero,
          //   title: Text(
          //     context.l10n.agendaDisplaySettingsShowCancelledLabel,
          //     style: settingLabelStyle,
          //   ),
          //   value: showCancelled,
          //   onChanged: notifier.setShowCancelledAppointments,
          // ),
          const SizedBox(height: _sectionSpacing),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              context.l10n.agendaDisplaySettingsServiceColorsLabel,
              style: settingLabelStyle,
            ),
          ),
          const SizedBox(height: _radioGroupTopSpacing),
          RadioListTile<bool>(
            contentPadding: EdgeInsets.zero,
            value: true,
            groupValue: useServiceColors,
            title: Text(
              context.l10n.servicesTabLabel,
              style: settingLabelStyle,
            ),
            onChanged: (value) => notifier.setUseServiceColorsOverride(value),
          ),
          const SizedBox(height: _radioItemSpacing),
          RadioListTile<bool>(
            contentPadding: EdgeInsets.zero,
            value: false,
            groupValue: useServiceColors,
            title: Text(context.l10n.teamStaffLabel, style: settingLabelStyle),
            onChanged: (value) => notifier.setUseServiceColorsOverride(value),
          ),
          const SizedBox(height: _sectionSpacing),
          Text(
            context.l10n.agendaDisplaySettingsCardColorOpacityLabel,
            style: settingLabelStyle,
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  notifier.setCardColorOpacity(
                    settings.cardColorOpacity - 0.05,
                  );
                },
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Slider(
                  min: 0.3,
                  max: 1.0,
                  divisions: 14,
                  value: settings.cardColorOpacity,
                  onChanged: notifier.setCardColorOpacity,
                ),
              ),
              IconButton(
                onPressed: () {
                  notifier.setCardColorOpacity(
                    settings.cardColorOpacity + 0.05,
                  );
                },
                icon: const Icon(Icons.add),
              ),
              const SizedBox(width: 6),
              Text('${(settings.cardColorOpacity * 100).round()}%'),
            ],
          ),
          if (showExtraMinutesBandIntensitySetting) ...[
            const SizedBox(height: _sectionSpacing),
            Text(
              context.l10n.agendaDisplaySettingsExtraMinutesBandIntensityLabel,
              style: settingLabelStyle,
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    notifier.setExtraMinutesBandIntensity(
                      settings.extraMinutesBandIntensity - 0.05,
                    );
                  },
                  icon: const Icon(Icons.remove),
                ),
                Expanded(
                  child: Slider(
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    value: settings.extraMinutesBandIntensity,
                    onChanged: notifier.setExtraMinutesBandIntensity,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    notifier.setExtraMinutesBandIntensity(
                      settings.extraMinutesBandIntensity + 0.05,
                    );
                  },
                  icon: const Icon(Icons.add),
                ),
                const SizedBox(width: 6),
                Text('${(settings.extraMinutesBandIntensity * 100).round()}%'),
              ],
            ),
          ],
          if (isDesktop) ...[
            const SizedBox(height: _sectionSpacing),
            Text(
              context.l10n.agendaDisplaySettingsHoverUnrelatedDimIntensityLabel,
              style: settingLabelStyle,
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    notifier.setHoverUnrelatedCardDimIntensity(
                      settings.hoverUnrelatedCardDimIntensity + 0.05,
                    );
                  },
                  icon: const Icon(Icons.remove),
                ),
                Expanded(
                  child: Slider(
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    value: hoverUnrelatedVisualIntensity,
                    onChanged: (value) {
                      notifier.setHoverUnrelatedCardDimIntensity(1.0 - value);
                    },
                  ),
                ),
                IconButton(
                  onPressed: () {
                    notifier.setHoverUnrelatedCardDimIntensity(
                      settings.hoverUnrelatedCardDimIntensity - 0.05,
                    );
                  },
                  icon: const Icon(Icons.add),
                ),
                const SizedBox(width: 6),
                Text(
                  '${(hoverUnrelatedVisualIntensity * 100).round()}%',
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        if (isDesktop)
          SizedBox(
            width: AppButtonStyles.dialogButtonWidth,
            child: AppOutlinedActionButton(
              onPressed: () => Navigator.of(context).pop(),
              borderColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.primary,
              padding: AppButtonStyles.dialogButtonPadding,
              child: Text(context.l10n.actionClose),
            ),
          ),
        SizedBox(
          width: AppButtonStyles.dialogButtonWidth + 30,
          child: AppFilledButton(
            onPressed: notifier.resetToDefaults,
            padding: AppButtonStyles.dialogButtonPadding,
            child: Text(context.l10n.agendaDisplaySettingsResetDefaultsAction),
          ),
        ),
      ],
    );
  }

  bool _hasAnyAppointmentWithAdditionalTime(List<Appointment> appointments) {
    return appointments.any(
      (appointment) =>
          appointment.blockedExtraMinutes > 0 ||
          appointment.processingExtraMinutes > 0 ||
          (appointment.extraMinutes ?? 0) > 0,
    );
  }
}
