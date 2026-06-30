import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/models/time_slot.dart';
import '../../../../core/widgets/centered_error_view.dart';
import '../../providers/booking_provider.dart';
import '../../providers/locations_provider.dart';
import '../booking_step_layout.dart';

class DateTimeStep extends ConsumerStatefulWidget {
  const DateTimeStep({super.key});

  @override
  ConsumerState<DateTimeStep> createState() => _DateTimeStepState();
}

class _DateTimeStepState extends ConsumerState<DateTimeStep> {
  bool _hasInitialized = false;
  List<int>? _lastServiceIds;
  int? _lastStaffId;
  int? _lastLocationId;

  @override
  void initState() {
    super.initState();
  }

  void _tryInitializeSelectedDate() {
    // Controlla se servizi o staff sono cambiati → reset
    final bookingState = ref.read(bookingFlowProvider);
    final currentServiceIds = bookingState.request.services
        .map((s) => s.id)
        .toList();
    final currentStaffId = bookingState.request.singleStaffId;
    final currentLocationId = ref.read(effectiveLocationIdProvider);

    bool selectionChanged = false;
    if (_lastServiceIds != null &&
        !_listEquals(_lastServiceIds!, currentServiceIds)) {
      selectionChanged = true;
    }
    if (_lastStaffId != currentStaffId) {
      selectionChanged = true;
    }
    if (_lastLocationId != currentLocationId) {
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
    _lastLocationId = currentLocationId;

    if (_hasInitialized) return;

    // Se già selezionata una data e non è cambiata la selezione, non fare nulla
    final currentDate = ref.read(selectedDateProvider);
    if (currentDate != null && !selectionChanged) {
      _hasInitialized = true;
      return;
    }

    // Si parte sempre da OGGI: l'utente deve percepire che per la data odierna
    // non c'è disponibilità e scegliere esplicitamente di andare alla prima
    // data disponibile tramite l'apposito pulsante.
    _hasInitialized = true;
    // Usa Future per evitare di modificare lo stato durante il build
    Future(() {
      if (!mounted) return;
      final today = ref.read(locationTodayProvider);
      ref.read(selectedDateProvider.notifier).state = today;
      final focusedMonth = ref.read(focusedMonthProvider);
      if (focusedMonth.year != today.year ||
          focusedMonth.month != today.month) {
        ref.read(focusedMonthProvider.notifier).state = DateTime(
          today.year,
          today.month,
          1,
        );
      }
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
    // Prima data con disponibilità (null finché in caricamento o se non ce n'è
    // entro il limite di prenotazione): usata per il pulsante "Vai alla prima
    // data disponibile" quando oggi non ha posto. Durante un ricalcolo (es.
    // dopo aver cambiato i servizi) NON usare il valore precedente, che sarebbe
    // relativo alla vecchia selezione.
    final firstAvailableDate = firstDateAsync.isLoading
        ? null
        : firstDateAsync.value;

    if (availableDatesAsync.hasError || slotsAsync.hasError) {
      return CenteredErrorView(
        title: l10n.errorLoadingAvailability,
        onRetry: () {
          ref.read(availableDatesProvider.notifier).resetForNewSelection();
          ref.invalidate(availableSlotsProvider);
          ref.invalidate(firstAvailableDateProvider);
        },
        retryLabel: l10n.actionRetry,
      );
    }

    // Inizializza la data selezionata (parte da oggi)
    _tryInitializeSelectedDate();

    return Stack(
      children: [
        Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                kBookingStepHorizontalMargin,
                12,
                kBookingStepHorizontalMargin,
                8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.dateTimeTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: l10n.dateTimeJumpToDate,
                    child: OutlinedButton(
                      onPressed: () => _pickSpecificDate(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        side: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 1.5,
                        ),
                        // Pillola orizzontale (ovale) invece del cerchio.
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Icon(Icons.event),
                    ),
                  ),
                ],
              ),
            ),

            // Contenuto scrollabile
            Expanded(
              child: SingleChildScrollView(
                // Aggiunge padding bottom per footer fisso (~72px) +
                // gesture bar Android + eventuale tastiera.
                padding: EdgeInsets.only(
                  bottom:
                      MediaQuery.of(context).viewPadding.bottom +
                      MediaQuery.of(context).viewInsets.bottom +
                      72 +
                      24,
                ),
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
                      // La disponibilità della data selezionata è già nota dagli
                      // slot caricati on-demand: serve per mostrare subito il
                      // pallino (invece dello spinner) quando si salta a una
                      // data lontana non ancora coperta dal loader sequenziale.
                      selectedDateSlotsLoading: slotsAsync.isLoading,
                      selectedDateHasSlots:
                          slotsAsync.value?.isNotEmpty ?? false,
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kBookingStepHorizontalMargin,
                      ),
                      child: Container(height: 2, color: theme.dividerColor),
                    ),

                    // Slot orari
                    if (!isLoading)
                      slotsAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (e, _) => const SizedBox.shrink(),
                        data: (slots) => slots.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.event_busy,
                                          size: 32,
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.3),
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            l10n.dateTimeNoSlots,
                                            textAlign: TextAlign.center,
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.6),
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 36),
                                    _buildGoToAvailableDateButton(
                                      context,
                                      ref,
                                      selectedDate,
                                      availableDates,
                                      firstAvailableDate,
                                      focusedMonth,
                                      l10n,
                                      theme,
                                      // La prima data disponibile è ancora in
                                      // ricerca.
                                      firstDateLoading:
                                          firstDateAsync.isLoading,
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

  /// Apre un date picker per saltare a una data specifica (anche lontana)
  Future<void> _pickSpecificDate(BuildContext context, WidgetRef ref) async {
    final today = ref.read(locationTodayProvider);
    final daysToShow = ref.read(maxBookingAdvanceDaysProvider);
    final firstDate = DateTime(today.year, today.month, today.day);
    final lastDate = DateTime(
      firstDate.year,
      firstDate.month,
      firstDate.day + daysToShow - 1,
    );

    final current = ref.read(selectedDateProvider);
    DateTime initialDate = current ?? firstDate;
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    // Usa CalendarDatePicker dentro un dialog (invece di showDatePicker) così
    // la scelta viene confermata al tap sul giorno, senza dover premere OK.
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) {
        return Dialog(
          child: SizedBox(
            width: 360,
            height: 420,
            child: CalendarDatePicker(
              initialDate: initialDate,
              firstDate: firstDate,
              lastDate: lastDate,
              onDateChanged: (date) => Navigator.of(ctx).pop(date),
            ),
          ),
        );
      },
    );

    if (picked == null) return;

    // Aggiorna il mese focalizzato e la data selezionata: la lista
    // orizzontale scrollerà automaticamente fino alla data scelta.
    final focusedMonth = ref.read(focusedMonthProvider);
    if (focusedMonth.year != picked.year ||
        focusedMonth.month != picked.month) {
      ref.read(focusedMonthProvider.notifier).state = DateTime(
        picked.year,
        picked.month,
        1,
      );
    }
    ref.read(selectedDateProvider.notifier).state = picked;
  }

  /// Costruisce il pulsante per andare alla prima o prossima data disponibile
  Widget _buildGoToAvailableDateButton(
    BuildContext context,
    WidgetRef ref,
    DateTime? selectedDate,
    Set<DateTime> availableDates,
    DateTime? firstAvailableDate,
    DateTime focusedMonth,
    L10n l10n,
    ThemeData theme, {
    required bool firstDateLoading,
  }) {
    if (selectedDate == null) {
      return const SizedBox.shrink();
    }

    // Ordina le date già caricate dal loader sequenziale
    final sortedDates = availableDates.toList()..sort((a, b) => a.compareTo(b));

    // Prima data disponibile in assoluto: se il loader sequenziale non l'ha
    // ancora raggiunta (disponibilità lontana), usa quella trovata dalla
    // ricerca dedicata (firstAvailableDate).
    final DateTime? firstAvailable = sortedDates.isNotEmpty
        ? sortedDates.first
        : firstAvailableDate;

    if (firstAvailable == null) {
      // Non ancora nota: se la ricerca è in corso mostra il pulsante
      // disabilitato con il loading, altrimenti non c'è disponibilità.
      if (firstDateLoading) {
        return _buildAvailableDateButton(
          ref,
          theme,
          focusedMonth,
          date: null,
          text: l10n.dateTimeGoToFirst,
          icon: Icons.fast_forward,
          loading: true,
        );
      }
      return const SizedBox.shrink();
    }

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

    if (selectedDate.isBefore(firstAvailable)) {
      // Caso 1: Data selezionata è prima della prima disponibile
      return _buildAvailableDateButton(
        ref,
        theme,
        focusedMonth,
        date: firstAvailable,
        text: l10n.dateTimeGoToFirst,
        icon: Icons.fast_forward,
      );
    } else {
      // Caso 2: Data selezionata è dopo la prima disponibile
      // Mostra "Vai alla prima" + eventualmente "Vai alla prossima"
      final buttons = <Widget>[
        _buildAvailableDateButton(
          ref,
          theme,
          focusedMonth,
          date: firstAvailable,
          text: l10n.dateTimeGoToFirst,
          icon: Icons.fast_rewind,
        ),
      ];

      // Cerca la prossima data disponibile tra quelle già caricate.
      final nextAvailable = sortedDates
          .where((d) => d.isAfter(selectedDate))
          .toList();
      if (nextAvailable.isNotEmpty) {
        buttons.add(const SizedBox(height: 32));
        buttons.add(
          _buildAvailableDateButton(
            ref,
            theme,
            focusedMonth,
            date: nextAvailable.first,
            text: l10n.dateTimeGoToNext,
            icon: Icons.fast_forward,
          ),
        );
      } else {
        // Non trovata nel set già caricato: la cerca oltre (anche dopo un buco
        // di disponibilità tipo ferie) tramite nextAvailableDateProvider, che
        // effettivamente conclude la ricerca (niente loading eterno).
        final nextAsync = ref.watch(nextAvailableDateProvider);
        if (nextAsync.isLoading) {
          buttons.add(const SizedBox(height: 32));
          buttons.add(
            _buildAvailableDateButton(
              ref,
              theme,
              focusedMonth,
              date: null,
              text: l10n.dateTimeGoToNext,
              icon: Icons.fast_forward,
              loading: true,
            ),
          );
        } else if (nextAsync.value != null) {
          buttons.add(const SizedBox(height: 32));
          buttons.add(
            _buildAvailableDateButton(
              ref,
              theme,
              focusedMonth,
              date: nextAsync.value,
              text: l10n.dateTimeGoToNext,
              icon: Icons.fast_forward,
            ),
          );
        }
        // Se value == null e non in loading → nessuna disponibilità successiva.
      }

      return Column(mainAxisSize: MainAxisSize.min, children: buttons);
    }
  }

  /// Pulsante "vai a data disponibile". Se [loading] è true (o [date] è null)
  /// viene mostrato disabilitato con un indicatore di caricamento accanto.
  Widget _buildAvailableDateButton(
    WidgetRef ref,
    ThemeData theme,
    DateTime focusedMonth, {
    required DateTime? date,
    required String text,
    required IconData icon,
    bool loading = false,
  }) {
    final disabled = loading || date == null;
    final color = disabled
        ? theme.colorScheme.onSurface.withOpacity(0.38)
        : theme.colorScheme.primary;
    return TextButton.icon(
      onPressed: disabled
          ? null
          : () {
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
      icon: loading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : Icon(icon, size: 18, color: color),
      label: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: color,
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

  Widget _buildCalendar(
    BuildContext context,
    DateTime? selectedDate,
    DateTime focusedMonth,
    Set<DateTime> availableDates, {
    required bool isLoading,
    required L10n l10n,
    required bool selectedDateSlotsLoading,
    required bool selectedDateHasSlots,
  }) {
    final today = ref.watch(locationTodayProvider);

    // Usa maxBookingAdvanceDays dalla location
    final daysToShow = ref.watch(maxBookingAdvanceDaysProvider);
    // Genera i giorni per data di calendario (non sommando Duration di 24h),
    // così il cambio ora legale/solare non duplica né salta un giorno.
    final days = List.generate(
      daysToShow,
      (i) => DateTime(today.year, today.month, today.day + i),
    );

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
              selectedDateSlotsLoading: selectedDateSlotsLoading,
              selectedDateHasSlots: selectedDateHasSlots,
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
      final now = ref.watch(locationNowProvider);
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
      padding: const EdgeInsets.symmetric(
        horizontal: kBookingStepHorizontalMargin,
        vertical: 16,
      ),
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
    required this.selectedDateSlotsLoading,
    required this.selectedDateHasSlots,
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

  /// Stato degli slot della data attualmente selezionata: usato per mostrare
  /// subito la disponibilità di una data lontana scelta col picker, senza
  /// attendere il loader sequenziale dei pallini.
  final bool selectedDateSlotsLoading;
  final bool selectedDateHasSlots;

  @override
  State<_HorizontalDateList> createState() => _HorizontalDateListState();
}

class _HorizontalDateListState extends State<_HorizontalDateList> {
  late ScrollController _scrollController;
  static const double _itemWidth = 56.0;
  // Estensione reale occupata da ogni giorno = larghezza + margini (2+2).
  // Va usata per la matematica dello scroll e impostata come itemExtent sulla
  // ListView, così maxScrollExtent è esatto e l'animateTo raggiunge anche le
  // date lontane (altrimenti viene clampato a una stima troppo piccola).
  static const double _itemExtent = _itemWidth + 4.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: widget.initialScrollIndex * _itemExtent,
    );
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    _maybeLoadMore();
  }

  void _maybeLoadMore() {
    // Carica più date quando si avvicina alla fine dei giorni caricati
    final currentDay = (_scrollController.offset / _itemExtent).floor();
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
            (idx * _itemExtent) - (screenWidth / 2) + (_itemExtent / 2);
        final clamped = targetOffset.clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );
        // Prima inizializzazione (da nessuna data alla prima disponibile):
        // posiziona istantaneamente per evitare il "salto" animato. Le
        // selezioni successive (navigazione utente) restano animate.
        if (oldWidget.selectedDate == null) {
          _scrollController.jumpTo(clamped);
        } else {
          _scrollController.animateTo(
            clamped,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
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

    return ScrollConfiguration(
      behavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.stylus,
          PointerDeviceKind.invertedStylus,
          PointerDeviceKind.unknown,
        },
      ),
      child: Listener(
        onPointerSignal: (event) {
          if (event is! PointerScrollEvent || !_scrollController.hasClients) {
            return;
          }
          final delta = event.scrollDelta.dy == 0
              ? event.scrollDelta.dx
              : event.scrollDelta.dy;
          final position = _scrollController.position;
          final target = (_scrollController.offset + delta).clamp(
            position.minScrollExtent,
            position.maxScrollExtent,
          );
          _scrollController.jumpTo(target);
        },
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: kBookingStepHorizontalMargin,
          ),
          itemExtent: _itemExtent,
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
                        color: isSelected ? theme.colorScheme.primary : null,
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
                    if (index >= widget.loadedDays &&
                        !(isSelected && !widget.selectedDateSlotsLoading))
                      // Ancora in caricamento per questa data
                      SizedBox(
                        width: 6,
                        height: 6,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: theme.colorScheme.outline.withOpacity(0.5),
                        ),
                      )
                    else if (isAvailable ||
                        (isSelected &&
                            index >= widget.loadedDays &&
                            widget.selectedDateHasSlots))
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
                    // Indicatore mese su ogni giorno
                    Text(
                      DateFormat('MMM', 'it').format(date).toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
