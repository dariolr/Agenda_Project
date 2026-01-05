import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/time_slot.dart';
import '../../providers/booking_provider.dart';

class DateTimeStep extends ConsumerStatefulWidget {
  const DateTimeStep({super.key});

  @override
  ConsumerState<DateTimeStep> createState() => _DateTimeStepState();
}

class _DateTimeStepState extends ConsumerState<DateTimeStep> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final selectedDate = ref.watch(selectedDateProvider);
    final slotsAsync = ref.watch(availableSlotsProvider);
    final bookingState = ref.watch(bookingFlowProvider);
    final firstDateAsync = ref.watch(firstAvailableDateProvider);
    final focusedMonth = ref.watch(focusedMonthProvider);
    final availableDatesAsync = ref.watch(availableDatesProvider);
    final availableDates = availableDatesAsync.value ?? <DateTime>{};

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.dateTimeTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Contenuto scrollabile
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Calendario
                _buildCalendar(
                  context,
                  selectedDate,
                  focusedMonth,
                  availableDates,
                ),

                const Divider(),

                // Slot orari
                slotsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Center(child: Text(l10n.errorLoadingAvailability)),
                  data: (slots) => slots.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 48,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.3,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.dateTimeNoSlots,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 12),
                              firstDateAsync.when(
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                                data: (date) {
                                  final isAlreadyOnFirstDate =
                                      selectedDate != null &&
                                      selectedDate.year == date.year &&
                                      selectedDate.month == date.month &&
                                      selectedDate.day == date.day;
                                  if (isAlreadyOnFirstDate) {
                                    return const SizedBox.shrink();
                                  }
                                  return TextButton.icon(
                                    onPressed: () {
                                      ref
                                          .read(
                                            focusedMonthProvider.notifier,
                                          )
                                          .state = DateTime(
                                        date.year,
                                        date.month,
                                        1,
                                      );
                                      ref
                                          .read(
                                            selectedDateProvider.notifier,
                                          )
                                          .state = date;
                                    },
                                    icon: Icon(
                                      Icons.fast_forward,
                                      size: 18,
                                      color: theme.colorScheme.primary,
                                    ),
                                    label: Text(
                                      l10n.dateTimeGoToFirst,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        )
                      : _buildTimeSlots(context, ref, slots),
                ),
              ],
            ),
          ),
        ),

        // Footer
        _buildFooter(context, ref, bookingState),
      ],
    );
  }

  Widget _buildCalendar(
    BuildContext context,
    DateTime? selectedDate,
    DateTime focusedMonth,
    Set<DateTime> availableDates,
  ) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(
      focusedMonth.year,
      focusedMonth.month + 1,
      0,
    );
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Header mese
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  ref.read(focusedMonthProvider.notifier).state = DateTime(
                    focusedMonth.year,
                    focusedMonth.month - 1,
                    1,
                  );
                },
              ),
              Text(
                DateFormat('MMMM yyyy', 'it').format(focusedMonth),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  ref.read(focusedMonthProvider.notifier).state = DateTime(
                    focusedMonth.year,
                    focusedMonth.month + 1,
                    1,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Giorni della settimana
          Row(
            children: ['L', 'M', 'M', 'G', 'V', 'S', 'D']
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          // Griglia giorni
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              final dayOffset = index - (firstWeekday - 1) + 1;
              if (dayOffset < 1 || dayOffset > daysInMonth) {
                return const SizedBox.shrink();
              }

              final date = DateTime(
                focusedMonth.year,
                focusedMonth.month,
                dayOffset,
              );
              final isToday =
                  date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day;
              final isPast = date.isBefore(
                DateTime(now.year, now.month, now.day),
              );
              final isAvailable = _containsDate(availableDates, date);
              final isDisabled = isPast || !isAvailable;
              final isSelected =
                  selectedDate != null &&
                  date.year == selectedDate.year &&
                  date.month == selectedDate.month &&
                  date.day == selectedDate.day;

              return GestureDetector(
                onTap: isDisabled
                    ? null
                    : () {
                        ref.read(selectedDateProvider.notifier).state = date;
                      },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : isToday
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$dayOffset',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : isDisabled
                            ? theme.colorScheme.onSurface.withOpacity(0.3)
                            : theme.colorScheme.onSurface,
                        fontWeight: isToday || isSelected
                            ? FontWeight.bold
                            : null,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlots(
    BuildContext context,
    WidgetRef ref,
    List<TimeSlot> slots,
  ) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final bookingState = ref.watch(bookingFlowProvider);
    final selectedSlot = bookingState.request.selectedSlot;

    // Raggruppa per fascia oraria
    final morningSlots = slots.where((s) => s.startTime.hour < 12).toList();
    final afternoonSlots = slots
        .where((s) => s.startTime.hour >= 12 && s.startTime.hour < 18)
        .toList();
    final eveningSlots = slots.where((s) => s.startTime.hour >= 18).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (morningSlots.isNotEmpty) ...[
            Text(l10n.dateTimeMorning, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _buildSlotGrid(context, ref, morningSlots, selectedSlot),
            const SizedBox(height: 16),
          ],
          if (afternoonSlots.isNotEmpty) ...[
            Text(l10n.dateTimeAfternoon, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _buildSlotGrid(context, ref, afternoonSlots, selectedSlot),
            const SizedBox(height: 16),
          ],
          if (eveningSlots.isNotEmpty) ...[
            Text(l10n.dateTimeEvening, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _buildSlotGrid(context, ref, eveningSlots, selectedSlot),
          ],
        ],
      ),
    );
  }

  Widget _buildSlotGrid(
    BuildContext context,
    WidgetRef ref,
    List<TimeSlot> slots,
    TimeSlot? selectedSlot,
  ) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: slots.map((slot) {
        final isSelected = selectedSlot?.startTime == slot.startTime;
        return GestureDetector(
          onTap: () {
            ref.read(bookingFlowProvider.notifier).selectTimeSlot(slot);
            ref.read(bookingFlowProvider.notifier).nextStep();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.dividerColor,
              ),
            ),
            child: Text(
              slot.formattedTime,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    WidgetRef ref,
    BookingFlowState state,
  ) {
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
          onPressed: state.canGoNext
              ? () => ref.read(bookingFlowProvider.notifier).nextStep()
              : null,
          child: Text(l10n.actionNext),
        ),
      ),
    );
  }

  bool _containsDate(Set<DateTime> dates, DateTime date) {
    return dates.any(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );
  }
}
