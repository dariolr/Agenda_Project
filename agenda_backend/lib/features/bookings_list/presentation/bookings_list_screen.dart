import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '/app/providers/form_factor_provider.dart';
import '/core/l10n/l10_extension.dart';
import '/core/models/booking_list_item.dart';
import '/core/network/network_providers.dart';
import '/core/widgets/feedback_dialog.dart';
import '/features/agenda/providers/date_range_provider.dart';
import '/features/agenda/providers/location_providers.dart';
import '/features/bookings_list/providers/bookings_list_provider.dart';
import '/features/services/providers/services_provider.dart';
import '/features/staff/providers/staff_providers.dart';

class BookingsListScreen extends ConsumerStatefulWidget {
  const BookingsListScreen({super.key});

  @override
  ConsumerState<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends ConsumerState<BookingsListScreen> {
  final _scrollController = ScrollController();
  final _clientSearchController = TextEditingController();
  bool _filtersExpanded = true;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Inizializza date dai filtri default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final filters = ref.read(bookingsListFiltersProvider);
      if (filters.startDate != null) {
        _startDate = DateTime.parse(filters.startDate!);
      }
      if (filters.endDate != null) {
        _endDate = DateTime.parse(filters.endDate!);
      }
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _clientSearchController.dispose();
    super.dispose();
  }

  int get _businessId => ref.read(currentLocationProvider).businessId;

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(bookingsListProvider.notifier).loadMore(_businessId);
    }
  }

  Future<void> _loadInitialData() async {
    await ref.read(bookingsListProvider.notifier).loadBookings(_businessId);
  }

  void _applyFilters() {
    _loadInitialData();
  }

  void _resetFilters() {
    _clientSearchController.clear();
    ref.read(bookingsListFiltersProvider.notifier).reset();
    final filters = ref.read(bookingsListFiltersProvider);
    if (filters.startDate != null) {
      _startDate = DateTime.parse(filters.startDate!);
    } else {
      _startDate = null;
    }
    if (filters.endDate != null) {
      _endDate = DateTime.parse(filters.endDate!);
    } else {
      _endDate = null;
    }
    setState(() {});
    _loadInitialData();
  }

  Future<void> _selectDateRange() async {
    final initialRange = DateTimeRange(
      start: _startDate ?? DateTime.now().subtract(const Duration(days: 3)),
      end: _endDate ?? DateTime.now().add(const Duration(days: 1)),
    );

    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: initialRange,
      locale: const Locale('it', 'IT'),
    );

    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
      ref
          .read(bookingsListFiltersProvider.notifier)
          .setDateRange(_formatDate(range.start), _formatDate(range.end));
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _cancelBooking(BookingListItem booking) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.bookingsListCancelConfirmTitle),
        content: Text(l10n.bookingsListCancelConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.actionConfirm),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // Cancella via API
        final apiClient = ref.read(apiClientProvider);
        await apiClient.deleteBooking(
          locationId: booking.locationId,
          bookingId: booking.id,
        );
        // Aggiorna stato locale
        ref.read(bookingsListProvider.notifier).removeBooking(booking.id);
        if (mounted) {
          await FeedbackDialog.showSuccess(
            context,
            title: l10n.bookingsListCancelSuccess,
            message: '',
          );
        }
      } catch (e) {
        if (mounted) {
          await FeedbackDialog.showError(
            context,
            title: l10n.errorTitle,
            message: e.toString(),
          );
        }
      }
    }
  }

  void _viewBookingDetails(BookingListItem booking) {
    // Vai all'agenda alla data dell'appuntamento
    if (booking.firstStartTime != null) {
      // Imposta la data nell'agenda e naviga
      ref.read(agendaDateProvider.notifier).set(booking.firstStartTime!);
      context.go('/agenda');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final listState = ref.watch(bookingsListProvider);
    final filters = ref.watch(bookingsListFiltersProvider);
    final formFactor = ref.watch(formFactorProvider);
    final isDesktop = formFactor == AppFormFactor.desktop;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bookingsListTitle),
        actions: [
          IconButton(
            icon: Icon(
              _filtersExpanded ? Icons.filter_alt_off : Icons.filter_alt,
            ),
            onPressed: () =>
                setState(() => _filtersExpanded = !_filtersExpanded),
            tooltip: l10n.bookingsListFilterTitle,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters panel
          if (_filtersExpanded)
            _FiltersPanel(
              filters: filters,
              clientSearchController: _clientSearchController,
              startDate: _startDate,
              endDate: _endDate,
              onSelectDateRange: _selectDateRange,
              onApply: _applyFilters,
              onReset: _resetFilters,
              isDesktop: isDesktop,
            ),

          // Results info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  l10n.bookingsListTotalCount(listState.total),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                // Sort controls
                _SortControls(filters: filters),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(child: _buildContent(listState, isDesktop)),
        ],
      ),
    );
  }

  Widget _buildContent(BookingsListState state, bool isDesktop) {
    final l10n = context.l10n;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(state.error!),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadInitialData,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.actionRetry),
            ),
          ],
        ),
      );
    }

    if (state.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              l10n.bookingsListEmpty,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.bookingsListEmptyHint,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (isDesktop) {
      return _buildDataTable(state);
    } else {
      return _buildCardList(state);
    }
  }

  Widget _buildDataTable(BookingsListState state) {
    final l10n = context.l10n;

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              columns: [
                DataColumn(label: Text(l10n.bookingsListColumnDateTime)),
                DataColumn(label: Text(l10n.bookingsListColumnClient)),
                DataColumn(label: Text(l10n.bookingsListColumnServices)),
                DataColumn(label: Text(l10n.bookingsListColumnStaff)),
                DataColumn(label: Text(l10n.bookingsListColumnStatus)),
                DataColumn(
                  label: Text(l10n.bookingsListColumnPrice),
                  numeric: true,
                ),
                DataColumn(label: Text(l10n.bookingsListColumnCreatedAt)),
                DataColumn(label: Text(l10n.bookingsListColumnActions)),
              ],
              rows: state.bookings
                  .map((booking) => _buildDataRow(booking))
                  .toList(),
            ),
          ),
          if (state.isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          if (state.hasMore && !state.isLoadingMore)
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton(
                onPressed: () {
                  ref.read(bookingsListProvider.notifier).loadMore(_businessId);
                },
                child: Text(l10n.bookingsListLoadMore),
              ),
            ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(BookingListItem booking) {
    final l10n = context.l10n;
    final dateFormat = DateFormat('dd/MM/yy HH:mm');
    final dateOnlyFormat = DateFormat('dd/MM/yy');

    return DataRow(
      cells: [
        // DateTime
        DataCell(
          Text(
            booking.firstStartTime != null
                ? dateFormat.format(booking.firstStartTime!)
                : '-',
          ),
        ),
        // Client
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                booking.clientName ?? l10n.bookingsListNoClient,
                style: TextStyle(
                  fontStyle: booking.clientName == null
                      ? FontStyle.italic
                      : null,
                ),
              ),
              if (booking.clientPhone != null)
                Text(
                  booking.clientPhone!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        // Services
        DataCell(
          SizedBox(
            width: 200,
            child: Text(
              booking.serviceNames ?? '-',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        // Staff
        DataCell(Text(booking.staffNames ?? '-')),
        // Status
        DataCell(_StatusChip(status: booking.status)),
        // Price
        DataCell(
          Text(
            '€ ${booking.totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        // Created at
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                booking.createdAt != null
                    ? dateOnlyFormat.format(booking.createdAt!)
                    : '-',
              ),
              if (booking.creatorName != null)
                Text(
                  booking.creatorName!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        // Actions
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, size: 20),
                onPressed: () => _viewBookingDetails(booking),
                tooltip: l10n.bookingsListActionView,
              ),
              if (booking.status != 'cancelled')
                IconButton(
                  icon: Icon(
                    Icons.cancel,
                    size: 20,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () => _cancelBooking(booking),
                  tooltip: l10n.bookingsListActionCancel,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardList(BookingsListState state) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: state.bookings.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.bookings.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return _BookingCard(
          booking: state.bookings[index],
          onView: () => _viewBookingDetails(state.bookings[index]),
          onCancel: () => _cancelBooking(state.bookings[index]),
        );
      },
    );
  }
}

class _FiltersPanel extends ConsumerWidget {
  final BookingsListFilters filters;
  final TextEditingController clientSearchController;
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onSelectDateRange;
  final VoidCallback onApply;
  final VoidCallback onReset;
  final bool isDesktop;

  const _FiltersPanel({
    required this.filters,
    required this.clientSearchController,
    required this.startDate,
    required this.endDate,
    required this.onSelectDateRange,
    required this.onApply,
    required this.onReset,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locations = ref.watch(locationsProvider);
    final staff = ref.watch(allStaffProvider).value ?? [];
    final services = ref.watch(servicesProvider).value ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              // Location filter
              SizedBox(
                width: isDesktop ? 180 : double.infinity,
                child: DropdownButtonFormField<int?>(
                  decoration: InputDecoration(
                    labelText: l10n.bookingsListFilterLocation,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  value: filters.locationId,
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.bookingsListAllLocations),
                    ),
                    ...locations.map(
                      (loc) => DropdownMenuItem(
                        value: loc.id,
                        child: Text(loc.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    ref
                        .read(bookingsListFiltersProvider.notifier)
                        .setLocationId(value);
                  },
                ),
              ),

              // Staff filter
              SizedBox(
                width: isDesktop ? 180 : double.infinity,
                child: DropdownButtonFormField<int?>(
                  decoration: InputDecoration(
                    labelText: l10n.bookingsListFilterStaff,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  value: filters.staffId,
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.bookingsListAllStaff),
                    ),
                    ...staff.map(
                      (s) => DropdownMenuItem(value: s.id, child: Text(s.name)),
                    ),
                  ],
                  onChanged: (value) {
                    ref
                        .read(bookingsListFiltersProvider.notifier)
                        .setStaffId(value);
                  },
                ),
              ),

              // Service filter
              SizedBox(
                width: isDesktop ? 200 : double.infinity,
                child: DropdownButtonFormField<int?>(
                  decoration: InputDecoration(
                    labelText: l10n.bookingsListFilterService,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  value: filters.serviceId,
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.bookingsListAllServices),
                    ),
                    ...services.map(
                      (svc) => DropdownMenuItem(
                        value: svc.id,
                        child: Text(svc.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    ref
                        .read(bookingsListFiltersProvider.notifier)
                        .setServiceId(value);
                  },
                ),
              ),

              // Status filter
              SizedBox(
                width: isDesktop ? 180 : double.infinity,
                child: DropdownButtonFormField<String?>(
                  decoration: InputDecoration(
                    labelText: l10n.bookingsListFilterStatus,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  value: filters.status?.isNotEmpty == true
                      ? filters.status!.first
                      : null,
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.bookingsListAllStatus),
                    ),
                    DropdownMenuItem(
                      value: 'confirmed',
                      child: Text(l10n.bookingsListStatusConfirmed),
                    ),
                    DropdownMenuItem(
                      value: 'cancelled',
                      child: Text(l10n.bookingsListStatusCancelled),
                    ),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text(l10n.bookingsListStatusCompleted),
                    ),
                    DropdownMenuItem(
                      value: 'no_show',
                      child: Text(l10n.bookingsListStatusNoShow),
                    ),
                  ],
                  onChanged: (value) {
                    ref
                        .read(bookingsListFiltersProvider.notifier)
                        .setStatus(value != null ? [value] : null);
                  },
                ),
              ),

              // Client search
              SizedBox(
                width: isDesktop ? 200 : double.infinity,
                child: TextField(
                  controller: clientSearchController,
                  decoration: InputDecoration(
                    labelText: l10n.bookingsListFilterClient,
                    hintText: l10n.bookingsListFilterClientHint,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                    prefixIcon: const Icon(Icons.search, size: 20),
                  ),
                  onChanged: (value) {
                    ref
                        .read(bookingsListFiltersProvider.notifier)
                        .setClientSearch(value);
                  },
                ),
              ),

              // Date range
              SizedBox(
                width: isDesktop ? 220 : double.infinity,
                child: InkWell(
                  onTap: onSelectDateRange,
                  borderRadius: BorderRadius.circular(4),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.bookingsListFilterPeriod,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      isDense: true,
                      suffixIcon: const Icon(Icons.calendar_month, size: 20),
                    ),
                    child: Text(
                      startDate != null && endDate != null
                          ? '${DateFormat('dd/MM').format(startDate!)} - ${DateFormat('dd/MM').format(endDate!)}'
                          : '-',
                    ),
                  ),
                ),
              ),

              // Include past toggle
              SizedBox(
                width: isDesktop ? 180 : double.infinity,
                child: SwitchListTile(
                  title: Text(
                    filters.includePast
                        ? l10n.bookingsListFilterIncludePast
                        : l10n.bookingsListFilterFutureOnly,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  value: filters.includePast,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) {
                    ref
                        .read(bookingsListFiltersProvider.notifier)
                        .setIncludePast(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.clear),
                label: Text(l10n.bookingsListResetFilters),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: onApply,
                icon: const Icon(Icons.search),
                label: Text(l10n.actionApply),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SortControls extends ConsumerWidget {
  final BookingsListFilters filters;

  const _SortControls({required this.filters});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButton<String>(
          value: filters.sortBy,
          underline: const SizedBox(),
          items: [
            DropdownMenuItem(
              value: 'appointment',
              child: Text(l10n.bookingsListSortByAppointment),
            ),
            DropdownMenuItem(
              value: 'created',
              child: Text(l10n.bookingsListSortByCreated),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              ref.read(bookingsListFiltersProvider.notifier).setSortBy(value);
            }
          },
        ),
        IconButton(
          icon: Icon(
            filters.sortOrder == 'asc'
                ? Icons.arrow_upward
                : Icons.arrow_downward,
            size: 20,
          ),
          tooltip: filters.sortOrder == 'asc'
              ? l10n.bookingsListSortAsc
              : l10n.bookingsListSortDesc,
          onPressed: () {
            ref.read(bookingsListFiltersProvider.notifier).toggleSortOrder();
          },
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case 'confirmed':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
      case 'cancelled':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
      case 'completed':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
      case 'no_show':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
      case 'pending':
        backgroundColor = Colors.amber.shade100;
        textColor = Colors.amber.shade800;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
    }

    String label;
    switch (status) {
      case 'confirmed':
        label = context.l10n.bookingsListStatusConfirmed;
      case 'cancelled':
        label = context.l10n.bookingsListStatusCancelled;
      case 'completed':
        label = context.l10n.bookingsListStatusCompleted;
      case 'no_show':
        label = context.l10n.bookingsListStatusNoShow;
      case 'pending':
        label = context.l10n.bookingsListStatusPending;
      default:
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingListItem booking;
  final VoidCallback onView;
  final VoidCallback onCancel;

  const _BookingCard({
    required this.booking,
    required this.onView,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dateFormat = DateFormat('EEE dd/MM HH:mm', 'it_IT');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.firstStartTime != null
                          ? dateFormat.format(booking.firstStartTime!)
                          : '-',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _StatusChip(status: booking.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      booking.clientName ?? l10n.bookingsListNoClient,
                      style: TextStyle(
                        fontStyle: booking.clientName == null
                            ? FontStyle.italic
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              if (booking.serviceNames != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.cut, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        booking.serviceNames!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
              if (booking.staffNames != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_pin, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        booking.staffNames!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '€ ${booking.totalPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: onView,
                        tooltip: l10n.bookingsListActionView,
                        iconSize: 20,
                      ),
                      if (booking.status != 'cancelled')
                        IconButton(
                          icon: Icon(
                            Icons.cancel,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          onPressed: onCancel,
                          tooltip: l10n.bookingsListActionCancel,
                          iconSize: 20,
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
