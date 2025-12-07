import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/availability_exception.dart';
import '../../providers/availability_exceptions_provider.dart';
import '../dialogs/add_exception_dialog.dart';

/// Widget per visualizzare e gestire le eccezioni alla disponibilità
/// in una vista calendario mensile.
class ExceptionCalendarView extends ConsumerStatefulWidget {
  const ExceptionCalendarView({super.key, required this.staffId});

  final int staffId;

  @override
  ConsumerState<ExceptionCalendarView> createState() =>
      _ExceptionCalendarViewState();
}

class _ExceptionCalendarViewState extends ConsumerState<ExceptionCalendarView> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _loadExceptions();
  }

  Future<void> _loadExceptions() async {
    // Carica eccezioni per un range di 3 mesi (mese corrente ± 1)
    final from = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    final to = DateTime(_currentMonth.year, _currentMonth.month + 2, 0);
    await ref
        .read(availabilityExceptionsProvider.notifier)
        .loadExceptionsForStaff(widget.staffId, fromDate: from, toDate: to);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
    _loadExceptions();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
    _loadExceptions();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final exceptions = ref.watch(allExceptionsForStaffProvider(widget.staffId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con titolo e navigazione mese
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.exceptionsTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () => showAddExceptionDialog(
                  context,
                  ref,
                  staffId: widget.staffId,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.exceptionsAdd),
              ),
            ],
          ),
        ),

        // Navigazione mese
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                _formatMonth(_currentMonth),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Griglia calendario
        _CalendarGrid(
          month: _currentMonth,
          exceptions: exceptions,
          staffId: widget.staffId,
          onDayTap: (date) => _onDayTap(date, exceptions),
        ),

        const SizedBox(height: 16),

        // Lista eccezioni del mese
        _ExceptionsList(
          exceptions: _filterExceptionsForMonth(exceptions),
          staffId: widget.staffId,
        ),
      ],
    );
  }

  String _formatMonth(DateTime date) {
    final months = [
      'Gennaio',
      'Febbraio',
      'Marzo',
      'Aprile',
      'Maggio',
      'Giugno',
      'Luglio',
      'Agosto',
      'Settembre',
      'Ottobre',
      'Novembre',
      'Dicembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  List<AvailabilityException> _filterExceptionsForMonth(
    List<AvailabilityException> exceptions,
  ) {
    return exceptions.where((e) {
      return e.date.year == _currentMonth.year &&
          e.date.month == _currentMonth.month;
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  void _onDayTap(DateTime date, List<AvailabilityException> exceptions) {
    final dayExceptions = exceptions.where((e) => e.isOnDate(date)).toList();

    if (dayExceptions.isEmpty) {
      // Nessuna eccezione: apri dialog per crearne una nuova
      showAddExceptionDialog(context, ref, staffId: widget.staffId, date: date);
    } else if (dayExceptions.length == 1) {
      // Una sola eccezione: apri dialog per modificarla
      showAddExceptionDialog(
        context,
        ref,
        staffId: widget.staffId,
        initial: dayExceptions.first,
      );
    } else {
      // Più eccezioni: mostra bottom sheet con lista
      _showExceptionsForDay(date, dayExceptions);
    }
  }

  void _showExceptionsForDay(
    DateTime date,
    List<AvailabilityException> exceptions,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${date.day}/${date.month}/${date.year}',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            ...exceptions.map(
              (e) => ListTile(
                leading: Icon(
                  e.type == AvailabilityExceptionType.available
                      ? Icons.check_circle
                      : Icons.block,
                  color: e.type == AvailabilityExceptionType.available
                      ? Colors.green
                      : Theme.of(ctx).colorScheme.error,
                ),
                title: Text(e.reason ?? _getDefaultReason(e.type)),
                subtitle: Text(
                  e.isAllDay ? 'Giornata intera' : _formatTimeRange(e),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  showAddExceptionDialog(
                    context,
                    ref,
                    staffId: widget.staffId,
                    initial: e,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getDefaultReason(AvailabilityExceptionType type) {
    return type == AvailabilityExceptionType.available
        ? 'Disponibile'
        : 'Non disponibile';
  }

  String _formatTimeRange(AvailabilityException e) {
    if (e.isAllDay) return 'Giornata intera';
    final start =
        '${e.startTime!.hour.toString().padLeft(2, '0')}:${e.startTime!.minute.toString().padLeft(2, '0')}';
    final end =
        '${e.endTime!.hour.toString().padLeft(2, '0')}:${e.endTime!.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }
}

/// Griglia calendario mensile.
class _CalendarGrid extends ConsumerWidget {
  const _CalendarGrid({
    required this.month,
    required this.exceptions,
    required this.staffId,
    required this.onDayTap,
  });

  final DateTime month;
  final List<AvailabilityException> exceptions;
  final int staffId;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calcola primo e ultimo giorno del mese
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = lastDay.day;

    // Giorno della settimana del primo giorno (1=lun, 7=dom)
    final firstWeekday = firstDay.weekday;

    // Celle vuote iniziali + giorni del mese
    final totalCells = ((firstWeekday - 1) + daysInMonth);
    final rows = (totalCells / 7).ceil();

    final today = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Header giorni settimana
          Row(
            children: ['L', 'M', 'M', 'G', 'V', 'S', 'D']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          // Griglia giorni
          ...List.generate(rows, (rowIndex) {
            return Row(
              children: List.generate(7, (colIndex) {
                final cellIndex = rowIndex * 7 + colIndex;
                final dayNumber = cellIndex - (firstWeekday - 1) + 1;

                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 44));
                }

                final date = DateTime(month.year, month.month, dayNumber);
                final isToday =
                    date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;

                // Trova eccezioni per questo giorno
                final dayExceptions = exceptions
                    .where((e) => e.isOnDate(date))
                    .toList();

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onDayTap(date),
                    child: Container(
                      height: 44,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isToday
                            ? colorScheme.primaryContainer.withOpacity(0.5)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        border: isToday
                            ? Border.all(color: colorScheme.primary, width: 2)
                            : null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            dayNumber.toString(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          // Indicatori eccezioni
                          if (dayExceptions.isNotEmpty)
                            Positioned(
                              bottom: 4,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: dayExceptions.take(3).map((e) {
                                  return Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          e.type ==
                                              AvailabilityExceptionType
                                                  .available
                                          ? Colors.green
                                          : colorScheme.error,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }
}

/// Lista delle eccezioni del mese.
class _ExceptionsList extends ConsumerWidget {
  const _ExceptionsList({required this.exceptions, required this.staffId});

  final List<AvailabilityException> exceptions;
  final int staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final colorScheme = theme.colorScheme;

    if (exceptions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            l10n.exceptionsEmpty,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        ...exceptions.map(
          (e) => _ExceptionTile(exception: e, staffId: staffId),
        ),
      ],
    );
  }
}

/// Tile per singola eccezione.
class _ExceptionTile extends ConsumerWidget {
  const _ExceptionTile({required this.exception, required this.staffId});

  final AvailabilityException exception;
  final int staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isAvailable = exception.type == AvailabilityExceptionType.available;
    final color = isAvailable ? Colors.green : colorScheme.error;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isAvailable ? Icons.check_circle_outline : Icons.block_outlined,
          color: color,
        ),
      ),
      title: Text(
        exception.reason ?? (isAvailable ? 'Disponibile' : 'Non disponibile'),
        style: theme.textTheme.bodyLarge,
      ),
      subtitle: Text(
        '${_formatDate(exception.date)} • ${_formatTimeRange(exception)}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.edit_outlined),
        onPressed: () => showAddExceptionDialog(
          context,
          ref,
          staffId: staffId,
          initial: exception,
        ),
      ),
      onTap: () => showAddExceptionDialog(
        context,
        ref,
        staffId: staffId,
        initial: exception,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
    return '${weekdays[date.weekday - 1]} ${date.day}/${date.month}';
  }

  String _formatTimeRange(AvailabilityException e) {
    if (e.isAllDay) return 'Giornata intera';
    final start =
        '${e.startTime!.hour.toString().padLeft(2, '0')}:${e.startTime!.minute.toString().padLeft(2, '0')}';
    final end =
        '${e.endTime!.hour.toString().padLeft(2, '0')}:${e.endTime!.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }
}
