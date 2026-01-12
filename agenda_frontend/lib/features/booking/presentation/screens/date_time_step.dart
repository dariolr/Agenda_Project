import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/models/time_slot.dart';
import '../../providers/booking_provider.dart';

class DateTimeStep extends ConsumerStatefulWidget {
  const DateTimeStep({super.key});

  @override
  ConsumerState<DateTimeStep> createState() => _DateTimeStepState();
}

class _DateTimeStepState extends ConsumerState<DateTimeStep> {
  bool _hasInitialized = false;
  List<int>? _lastServiceIds;
  int? _lastStaffId;

  @override
  void initState() {
    super.initState();
  }

  void _tryInitializeSelectedDate(AsyncValue<DateTime> firstDateAsync) {
    // Controlla se servizi o staff sono cambiati → reset
    final bookingState = ref.read(bookingFlowProvider);
    final currentServiceIds = bookingState.request.services
        .map((s) => s.id)
        .toList();
    final currentStaffId = bookingState.request.singleStaffId;

    bool selectionChanged = false;
    if (_lastServiceIds != null &&
        !_listEquals(_lastServiceIds!, currentServiceIds)) {
      selectionChanged = true;
    }
    if (_lastStaffId != currentStaffId) {
      selectionChanged = true;
    }

    if (selectionChanged) {
      _hasInitialized = false;
      // Resetta anche la data selezionata
      Future(() {
        if (!mounted) return;
        ref.read(selectedDateProvider.notifier).state = null;
      });
    }

    _lastServiceIds = currentServiceIds;
    _lastStaffId = currentStaffId;

    if (_hasInitialized) return;

    // Se già selezionata una data e non è cambiata la selezione, non fare nulla
    final currentDate = ref.read(selectedDateProvider);
    if (currentDate != null && !selectionChanged) {
      _hasInitialized = true;
      return;
    }

    // Se la prima data è disponibile, impostala
    firstDateAsync.whenData((date) {
      _hasInitialized = true;
      // Usa Future per evitare di modificare lo stato durante il build
      Future(() {
        if (!mounted) return;
        // Imposta la data selezionata
        ref.read(selectedDateProvider.notifier).state = date;
        // Aggiorna il mese focalizzato se necessario
        final focusedMonth = ref.read(focusedMonthProvider);
        if (focusedMonth.year != date.year ||
            focusedMonth.month != date.month) {
          ref.read(focusedMonthProvider.notifier).state = DateTime(
            date.year,
            date.month,
            1,
          );
        }
      });
    });
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
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
    final isLoading = availableDatesAsync.isLoading || slotsAsync.isLoading;

    // Imposta automaticamente la prima data disponibile all'ingresso nello step
    _tryInitializeSelectedDate(firstDateAsync);

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
                      isLoading: availableDatesAsync.isLoading,
                      l10n: l10n,
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(height: 2, color: theme.dividerColor),
                    ),

                    // Slot orari
                    slotsAsync.when(
                      loading: () => const SizedBox.shrink(),
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
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.3),
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
                                  const SizedBox(height: 36),
                                  _buildGoToAvailableDateButton(
                                    context,
                                    ref,
                                    selectedDate,
                                    availableDates,
                                    focusedMonth,
                                    l10n,
                                    theme,
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
        ),
        if (isLoading)
          Positioned.fill(
            child: ColoredBox(
              color: theme.colorScheme.surface,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  /// Costruisce il pulsante per andare alla prima o prossima data disponibile
  Widget _buildGoToAvailableDateButton(
    BuildContext context,
    WidgetRef ref,
    DateTime? selectedDate,
    Set<DateTime> availableDates,
    DateTime focusedMonth,
    L10n l10n,
    ThemeData theme,
  ) {
    if (selectedDate == null || availableDates.isEmpty) {
      return const SizedBox.shrink();
    }

    // Ordina le date disponibili
    final sortedDates = availableDates.toList()..sort((a, b) => a.compareTo(b));

    // Trova la prima data disponibile in assoluto
    final firstAvailable = sortedDates.first;

    // Verifica se siamo già su una data disponibile
    final isOnAvailableDate = sortedDates.any(
      (d) =>
          d.year == selectedDate.year &&
          d.month == selectedDate.month &&
          d.day == selectedDate.day,
    );

    if (isOnAvailableDate) {
      return const SizedBox.shrink();
    }

    // Helper per creare un pulsante
    Widget buildButton(DateTime date, String text, IconData icon) {
      return TextButton.icon(
        onPressed: () {
          if (focusedMonth.year != date.year ||
              focusedMonth.month != date.month) {
            ref.read(focusedMonthProvider.notifier).state = DateTime(
              date.year,
              date.month,
              1,
            );
          }
          ref.read(selectedDateProvider.notifier).state = date;
        },
        icon: Icon(icon, size: 18, color: theme.colorScheme.primary),
        label: Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

    if (selectedDate.isBefore(firstAvailable)) {
      // Caso 1: Data selezionata è prima della prima disponibile
      return buildButton(
        firstAvailable,
        l10n.dateTimeGoToFirst,
        Icons.fast_forward,
      );
    } else {
      // Caso 2: Data selezionata è dopo la prima disponibile
      // Mostra "Vai alla prima" + eventualmente "Vai alla prossima"
      final buttons = <Widget>[
        buildButton(firstAvailable, l10n.dateTimeGoToFirst, Icons.fast_rewind),
      ];

      // Cerca la prossima data disponibile
      final nextAvailable = sortedDates
          .where((d) => d.isAfter(selectedDate))
          .toList();
      if (nextAvailable.isNotEmpty) {
        buttons.add(const SizedBox(height: 32));
        buttons.add(
          buildButton(
            nextAvailable.first,
            l10n.dateTimeGoToNext,
            Icons.fast_forward,
          ),
        );
      }

      return Column(mainAxisSize: MainAxisSize.min, children: buttons);
    }
  }

  Widget _buildCalendar(
    BuildContext context,
    DateTime? selectedDate,
    DateTime focusedMonth,
    Set<DateTime> availableDates, {
    required bool isLoading,
    required L10n l10n,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Usa maxBookingAdvanceDays dalla location
    final daysToShow = ref.watch(maxBookingAdvanceDaysProvider);
    final days = List.generate(daysToShow, (i) => today.add(Duration(days: i)));

    // Calcola il numero della settimana per ogni giorno (per alternare sfondo)
    int getWeekNumber(DateTime date) {
      // Settimana ISO: Lunedì è il primo giorno
      final firstDayOfYear = DateTime(date.year, 1, 1);
      final dayOfYear = date.difference(firstDayOfYear).inDays;
      return ((dayOfYear + firstDayOfYear.weekday - 1) / 7).floor();
    }

    // Abbreviazione giorno della settimana
    String getWeekdayAbbr(DateTime date) {
      const weekdays = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];
      return weekdays[date.weekday - 1];
    }

    // Trova indice del giorno selezionato per lo scroll iniziale
    int initialScrollIndex = 0;
    if (selectedDate != null) {
      final idx = days.indexWhere(
        (d) =>
            d.year == selectedDate.year &&
            d.month == selectedDate.month &&
            d.day == selectedDate.day,
      );
      if (idx >= 0) initialScrollIndex = idx;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lista orizzontale scrollabile
          SizedBox(
            height: 90,
            child: _HorizontalDateList(
              days: days,
              selectedDate: selectedDate,
              availableDates: availableDates,
              initialScrollIndex: initialScrollIndex,
              getWeekNumber: getWeekNumber,
              getWeekdayAbbr: getWeekdayAbbr,
              today: today,
              loadedDays: ref.watch(availableDatesProvider.notifier).loadedDays,
              onLoadMore: (dayIndex) {
                ref
                    .read(availableDatesProvider.notifier)
                    .loadUntilDay(dayIndex);
              },
              onDateSelected: (date) {
                ref.read(selectedDateProvider.notifier).state = date;
                // Aggiorna anche il mese focalizzato se cambia
                final currentFocused = ref.read(focusedMonthProvider);
                if (currentFocused.year != date.year ||
                    currentFocused.month != date.month) {
                  ref.read(focusedMonthProvider.notifier).state = DateTime(
                    date.year,
                    date.month,
                    1,
                  );
                }
              },
            ),
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
    final selectedDate = ref.watch(selectedDateProvider);

    // Raggruppa per fascia oraria
    final morningSlots = slots.where((s) => s.startTime.hour < 12).toList();
    final afternoonSlots = slots
        .where((s) => s.startTime.hour >= 12 && s.startTime.hour < 18)
        .toList();
    final eveningSlots = slots.where((s) => s.startTime.hour >= 18).toList();

    // Formatta la data in formato esteso localizzato
    String formattedDate = '';
    if (selectedDate != null) {
      final locale = Localizations.localeOf(context).toString();
      final now = DateTime.now();
      // Se l'anno è diverso dall'attuale, mostralo
      if (selectedDate.year != now.year) {
        formattedDate = DateFormat(
          'EEEE d MMMM yyyy',
          locale,
        ).format(selectedDate);
      } else {
        formattedDate = DateFormat('EEEE d MMMM', locale).format(selectedDate);
      }
      // Capitalizza la prima lettera
      formattedDate =
          formattedDate[0].toUpperCase() + formattedDate.substring(1);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Data selezionata in formato esteso
          if (formattedDate.isNotEmpty) ...[
            Text(
              formattedDate,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
          ],
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
}

/// Widget per la lista orizzontale scrollabile dei giorni
class _HorizontalDateList extends StatefulWidget {
  const _HorizontalDateList({
    required this.days,
    required this.selectedDate,
    required this.availableDates,
    required this.initialScrollIndex,
    required this.getWeekNumber,
    required this.getWeekdayAbbr,
    required this.today,
    required this.onDateSelected,
    required this.onLoadMore,
    required this.loadedDays,
  });

  final List<DateTime> days;
  final DateTime? selectedDate;
  final Set<DateTime> availableDates;
  final int initialScrollIndex;
  final int Function(DateTime) getWeekNumber;
  final String Function(DateTime) getWeekdayAbbr;
  final DateTime today;
  final void Function(DateTime) onDateSelected;
  final void Function(int dayIndex) onLoadMore;
  final int loadedDays;

  @override
  State<_HorizontalDateList> createState() => _HorizontalDateListState();
}

class _HorizontalDateListState extends State<_HorizontalDateList> {
  late ScrollController _scrollController;
  static const double _itemWidth = 56.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: widget.initialScrollIndex * _itemWidth,
    );
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    _maybeLoadMore();
  }

  void _maybeLoadMore() {
    // Carica più date quando si avvicina alla fine dei giorni caricati
    final currentDay = (_scrollController.offset / _itemWidth).floor();
    // Triggerare caricamento quando siamo a 5 giorni dalla fine dei giorni caricati
    if (currentDay >= widget.loadedDays - 5) {
      widget.onLoadMore(currentDay);
    }
  }

  @override
  void didUpdateWidget(_HorizontalDateList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se cambia la data selezionata, scrolla per renderla visibile
    if (widget.selectedDate != oldWidget.selectedDate &&
        widget.selectedDate != null) {
      final idx = widget.days.indexWhere(
        (d) =>
            d.year == widget.selectedDate!.year &&
            d.month == widget.selectedDate!.month &&
            d.day == widget.selectedDate!.day,
      );
      if (idx >= 0) {
        final screenWidth = MediaQuery.of(context).size.width;
        final targetOffset =
            (idx * _itemWidth) - (screenWidth / 2) + (_itemWidth / 2);
        _scrollController.animateTo(
          targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
    if (widget.loadedDays != oldWidget.loadedDays) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _maybeLoadMore();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  bool _containsDate(Set<DateTime> dates, DateTime date) {
    return dates.any(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: widget.days.length,
      itemBuilder: (context, index) {
        final date = widget.days[index];
        final isToday =
            date.year == widget.today.year &&
            date.month == widget.today.month &&
            date.day == widget.today.day;
        final isAvailable = _containsDate(widget.availableDates, date);
        final isSelected =
            widget.selectedDate != null &&
            date.year == widget.selectedDate!.year &&
            date.month == widget.selectedDate!.month &&
            date.day == widget.selectedDate!.day;
        final weekNumber = widget.getWeekNumber(date);
        final isOddWeek = weekNumber % 2 == 1;

        // Colore sfondo alternato per settimane
        final weekBgColor = isOddWeek
            ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5)
            : Colors.transparent;

        // Verifica se questa data è già stata caricata
        final isLoaded = index < widget.loadedDays;

        return GestureDetector(
          // Selezionabile se già caricata (anche se non disponibile)
          onTap: isLoaded ? () => widget.onDateSelected(date) : null,
          child: Container(
            width: _itemWidth,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: weekBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Giorno della settimana
                Text(
                  widget.getWeekdayAbbr(date),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isAvailable
                        ? theme.colorScheme.onSurface.withOpacity(0.6)
                        : theme.colorScheme.onSurface.withOpacity(0.3),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                // Pallino con numero giorno
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : isToday
                        ? theme.colorScheme.primary.withOpacity(0.15)
                        : null,
                    border: isToday && !isSelected
                        ? Border.all(
                            color: theme.colorScheme.primary,
                            width: 1.5,
                          )
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : isAvailable
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface.withOpacity(0.3),
                        fontWeight: isToday || isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Pallino indicatore disponibilità o loading
                if (index >= widget.loadedDays)
                  // Ancora in caricamento per questa data
                  SizedBox(
                    width: 6,
                    height: 6,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: theme.colorScheme.outline.withOpacity(0.5),
                    ),
                  )
                else if (isAvailable)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOddWeek
                          ? theme.colorScheme.primary
                          : theme.colorScheme.tertiary,
                    ),
                  )
                else
                  const SizedBox(height: 6),
                // Indicatore mese quando cambia
                if (date.day == 1 || index == 0)
                  Text(
                    DateFormat('MMM', 'it').format(date).toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  )
                else
                  const SizedBox(height: 11),
              ],
            ),
          ),
        );
      },
    );
  }
}
