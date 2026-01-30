import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '/app/providers/form_factor_provider.dart';
import '/core/l10n/l10_extension.dart';
import '/core/models/booking_list_item.dart';
import '/core/models/service.dart';
import '/core/models/service_category.dart';
import '/core/models/staff.dart';
import '/core/network/network_providers.dart';
import '/core/widgets/feedback_dialog.dart';
import '/features/agenda/providers/date_range_provider.dart';
import '/features/agenda/providers/location_providers.dart';
import '/features/bookings_list/providers/bookings_list_filter_provider.dart';
import '/features/bookings_list/providers/bookings_list_provider.dart';
import '/features/bookings_list/widgets/bookings_list_header.dart';
import '/features/services/providers/service_categories_provider.dart';
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

  // Multi-select filters (like Reports)
  final Set<int> _selectedLocationIds = {};
  final Set<int> _selectedStaffIds = {};
  final Set<int> _selectedServiceIds = {};
  Set<String> _selectedStatuses = {'confirmed'};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    // Get filter state from provider (UI date range)
    final filterState = ref.read(bookingsListFilterProvider);
    // Get current API filters to preserve sortBy/sortOrder
    final currentFilters = ref.read(bookingsListFiltersProvider);

    // Update filters provider with current selections
    ref
        .read(bookingsListFiltersProvider.notifier)
        .updateFilters(
          BookingsListFilters(
            locationIds: _selectedLocationIds.isNotEmpty
                ? _selectedLocationIds.toList()
                : null,
            staffIds: _selectedStaffIds.isNotEmpty
                ? _selectedStaffIds.toList()
                : null,
            serviceIds: _selectedServiceIds.isNotEmpty
                ? _selectedServiceIds.toList()
                : null,
            clientSearch: _clientSearchController.text.isNotEmpty
                ? _clientSearchController.text
                : null,
            status: _selectedStatuses.toList(),
            startDate: _formatDate(filterState.startDate),
            endDate: _formatDate(filterState.endDate),
            includePast: true, // Always include past within range
            sortBy: currentFilters.sortBy,
            sortOrder: currentFilters.sortOrder,
          ),
        );
    await ref.read(bookingsListProvider.notifier).loadBookings(_businessId);
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
        final apiClient = ref.read(apiClientProvider);
        await apiClient.deleteBooking(
          locationId: booking.locationId,
          bookingId: booking.id,
        );
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
    if (booking.firstStartTime != null) {
      ref.read(agendaDateProvider.notifier).set(booking.firstStartTime!);
      context.go('/agenda');
    }
  }

  void _showLocationFilter(BuildContext context) async {
    final locations = ref.read(locationsProvider);
    if (locations.isEmpty) return;

    final selected = await showDialog<Set<int>>(
      context: context,
      builder: (ctx) => _LocationFilterDialog(
        locations: locations,
        selected: _selectedLocationIds,
      ),
    );

    if (selected != null) {
      setState(
        () => _selectedLocationIds
          ..clear()
          ..addAll(selected),
      );
      _loadInitialData();
    }
  }

  void _showStaffFilter(BuildContext context) async {
    final staff = ref.read(allStaffProvider).value ?? [];
    if (staff.isEmpty) return;

    final selected = await showDialog<Set<int>>(
      context: context,
      builder: (ctx) =>
          _StaffFilterDialog(staff: staff, selected: _selectedStaffIds),
    );

    if (selected != null) {
      setState(
        () => _selectedStaffIds
          ..clear()
          ..addAll(selected),
      );
      _loadInitialData();
    }
  }

  void _showServiceFilter(BuildContext context) async {
    final services = ref.read(servicesProvider).value ?? [];
    final categories = ref.read(serviceCategoriesProvider);
    if (services.isEmpty) return;

    final selected = await showDialog<Set<int>>(
      context: context,
      builder: (ctx) => _ServiceFilterDialog(
        services: services,
        categories: categories,
        selected: _selectedServiceIds,
      ),
    );

    if (selected != null) {
      setState(
        () => _selectedServiceIds
          ..clear()
          ..addAll(selected),
      );
      _loadInitialData();
    }
  }

  void _showStatusFilter(BuildContext context) async {
    final l10n = context.l10n;
    // Solo confirmed e cancelled (rimosso completed e no_show)
    final allStatuses = {
      'confirmed': l10n.bookingsListStatusConfirmed,
      'cancelled': l10n.bookingsListStatusCancelled,
    };

    final selected = await showDialog<Set<String>>(
      context: context,
      builder: (ctx) => _MultiSelectDialog<String>(
        title: l10n.bookingsListFilterStatus,
        items: allStatuses,
        selected: _selectedStatuses,
      ),
    );

    if (selected != null && selected.isNotEmpty) {
      setState(() => _selectedStatuses = selected);
      _loadInitialData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final listState = ref.watch(bookingsListProvider);
    final formFactor = ref.watch(formFactorProvider);
    final isDesktop = formFactor == AppFormFactor.desktop;

    ref.listen<BookingsListState>(bookingsListProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        FeedbackDialog.showError(
          context,
          title: l10n.errorTitle,
          message: next.error!,
        );
      }
    });

    // Listen for filter changes to reload data
    ref.listen(bookingsListFilterProvider, (prev, next) {
      if (prev != null &&
          (prev.startDate != next.startDate ||
              prev.endDate != next.endDate ||
              prev.selectedPreset != next.selectedPreset)) {
        _loadInitialData();
      }
    });

    // Note: This screen is displayed inside ScaffoldWithNavigation,
    // so it should NOT have its own Scaffold/AppBar.
    // Material wrapper needed for FilterChip widgets.
    return Material(
      child: Column(
        children: [
          // Header with period controls
          const BookingsListHeader(),

          // Filters section (only chips, no date controls)
          _buildFiltersSection(context),

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
                _SortControls(
                  filters: ref.watch(bookingsListFiltersProvider),
                  onChanged: _loadInitialData,
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            indent: 0,
            endIndent: 0,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),

          // Content
          Expanded(child: _buildContent(listState, isDesktop)),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: Builder(
        builder: (context) {
          final locations = ref.watch(locationsProvider);
          final staff = ref.watch(allStaffProvider).value ?? [];
          final services = ref.watch(servicesProvider).value ?? [];

          final hasMultipleLocations = locations.length > 1;
          final hasMultipleStaff = staff.length > 1;
          final hasMultipleServices = services.length > 1;

          return Wrap(
            alignment: WrapAlignment.start,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (hasMultipleLocations)
                _buildFilterChip(
                  context,
                  label: _selectedLocationIds.isEmpty
                      ? l10n.reportsFilterLocations
                      : '${l10n.reportsFilterLocations} (${_selectedLocationIds.length})',
                  selected: _selectedLocationIds.isNotEmpty,
                  onTap: () => _showLocationFilter(context),
                ),
              if (hasMultipleStaff)
                _buildFilterChip(
                  context,
                  label: _selectedStaffIds.isEmpty
                      ? l10n.reportsFilterStaff
                      : '${l10n.reportsFilterStaff} (${_selectedStaffIds.length})',
                  selected: _selectedStaffIds.isNotEmpty,
                  onTap: () => _showStaffFilter(context),
                ),
              if (hasMultipleServices)
                _buildFilterChip(
                  context,
                  label: _selectedServiceIds.isEmpty
                      ? l10n.reportsFilterServices
                      : '${l10n.reportsFilterServices} (${_selectedServiceIds.length})',
                  selected: _selectedServiceIds.isNotEmpty,
                  onTap: () => _showServiceFilter(context),
                ),
              _buildFilterChip(
                context,
                label: l10n.reportsFilterStatus,
                selected: _selectedStatuses.length < 2,
                onTap: () => _showStatusFilter(context),
              ),
              // Client search chip
              _buildSearchChip(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.onPrimaryContainer,
    );
  }

  Widget _buildSearchChip(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final hasSearch = _clientSearchController.text.isNotEmpty;

    return ActionChip(
      avatar: Icon(
        Icons.search,
        size: 18,
        color: hasSearch ? colorScheme.onPrimaryContainer : null,
      ),
      label: Text(
        hasSearch
            ? '${l10n.bookingsListFilterClient}: ${_clientSearchController.text}'
            : l10n.bookingsListFilterClient,
      ),
      labelStyle: hasSearch
          ? TextStyle(color: colorScheme.onPrimaryContainer)
          : null,
      backgroundColor: hasSearch ? colorScheme.primaryContainer : null,
      onPressed: () => _showClientSearchDialog(context),
    );
  }

  void _showClientSearchDialog(BuildContext context) async {
    final l10n = context.l10n;
    final controller = TextEditingController(
      text: _clientSearchController.text,
    );

    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.bookingsListFilterClient),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.bookingsListFilterClientHint,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => controller.clear(),
            ),
          ),
          onSubmitted: (value) => Navigator.of(ctx).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: Text(l10n.actionApply),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _clientSearchController.text = result;
      });
      _loadInitialData();
    }
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
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: colorScheme.outline.withOpacity(0.2)),
              child: DataTable(
                dividerThickness: 0.2,
                horizontalMargin: 16,
                headingRowColor: WidgetStateProperty.all(
                  colorScheme.surfaceContainerHighest,
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
        DataCell(
          Text(
            booking.firstStartTime != null
                ? dateFormat.format(booking.firstStartTime!)
                : '-',
          ),
        ),
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
        DataCell(Text(booking.staffNames ?? '-')),
        DataCell(_StatusChip(status: booking.status)),
        DataCell(
          Text(
            '€ ${booking.totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
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
          showStatus: _selectedStatuses.length > 1,
        );
      },
    );
  }
}

// ============================================================================
// Filter Dialogs (copied from Reports for consistency)
// ============================================================================

class _LocationFilterDialog extends StatefulWidget {
  const _LocationFilterDialog({
    required this.locations,
    required this.selected,
  });

  final List<dynamic> locations;
  final Set<int> selected;

  @override
  State<_LocationFilterDialog> createState() => _LocationFilterDialogState();
}

class _LocationFilterDialogState extends State<_LocationFilterDialog> {
  late Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<int>.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.reportsFilterLocations),
      content: SizedBox(
        width: 300,
        height: 400,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selected = widget.locations
                          .map((l) => l.id as int)
                          .toSet();
                    });
                  },
                  child: Text(l10n.actionSelectAll),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _selected.clear());
                  },
                  child: Text(l10n.actionDeselectAll),
                ),
              ],
            ),
            Divider(
              indent: 0,
              endIndent: 0,
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.locations.length,
                itemBuilder: (context, index) {
                  final location = widget.locations[index];
                  final isSelected = _selected.contains(location.id);

                  return CheckboxListTile(
                    title: Text(location.name),
                    value: isSelected,
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selected.add(location.id);
                        } else {
                          _selected.remove(location.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: Text(l10n.actionApply),
        ),
      ],
    );
  }
}

class _StaffFilterDialog extends StatefulWidget {
  const _StaffFilterDialog({required this.staff, required this.selected});

  final List<Staff> staff;
  final Set<int> selected;

  @override
  State<_StaffFilterDialog> createState() => _StaffFilterDialogState();
}

class _StaffFilterDialogState extends State<_StaffFilterDialog> {
  late Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<int>.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.reportsFilterStaff),
      content: SizedBox(
        width: 300,
        height: 400,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selected = widget.staff.map((s) => s.id).toSet();
                    });
                  },
                  child: Text(l10n.actionSelectAll),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _selected.clear());
                  },
                  child: Text(l10n.actionDeselectAll),
                ),
              ],
            ),
            Divider(
              indent: 0,
              endIndent: 0,
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.staff.length,
                itemBuilder: (context, index) {
                  final staff = widget.staff[index];
                  final isSelected = _selected.contains(staff.id);

                  return CheckboxListTile(
                    title: Text(staff.name),
                    value: isSelected,
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selected.add(staff.id);
                        } else {
                          _selected.remove(staff.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: Text(l10n.actionApply),
        ),
      ],
    );
  }
}

class _ServiceFilterDialog extends StatefulWidget {
  const _ServiceFilterDialog({
    required this.services,
    required this.categories,
    required this.selected,
  });

  final List<Service> services;
  final List<ServiceCategory> categories;
  final Set<int> selected;

  @override
  State<_ServiceFilterDialog> createState() => _ServiceFilterDialogState();
}

class _ServiceFilterDialogState extends State<_ServiceFilterDialog> {
  late Set<int> _selected;
  final Set<int> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    _selected = Set<int>.from(widget.selected);
    for (final service in widget.services) {
      if (_selected.contains(service.id)) {
        _expandedCategories.add(service.categoryId);
      }
    }
  }

  Map<int, List<Service>> _groupServicesByCategory() {
    final grouped = <int, List<Service>>{};
    for (final service in widget.services) {
      grouped.putIfAbsent(service.categoryId, () => []).add(service);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final groupedServices = _groupServicesByCategory();

    final sortedCategories = widget.categories.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final categoryIdsWithServices = groupedServices.keys.toSet();

    final displayItems = <_CategoryDisplayItem>[];
    for (final cat in sortedCategories) {
      if (categoryIdsWithServices.contains(cat.id)) {
        displayItems.add(_CategoryDisplayItem(id: cat.id, name: cat.name));
      }
    }
    if (categoryIdsWithServices.contains(0)) {
      displayItems.add(const _CategoryDisplayItem(id: 0, name: 'Altro'));
    }

    return AlertDialog(
      title: Text(l10n.reportsFilterServices),
      content: SizedBox(
        width: 400,
        height: 500,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selected = widget.services.map((s) => s.id).toSet();
                    });
                  },
                  child: Text(l10n.actionSelectAll),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _selected.clear());
                  },
                  child: Text(l10n.actionDeselectAll),
                ),
              ],
            ),
            Divider(
              indent: 0,
              endIndent: 0,
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: displayItems.length,
                itemBuilder: (context, index) {
                  final categoryItem = displayItems[index];
                  final categoryId = categoryItem.id;
                  final categoryName = categoryItem.name;
                  final services = groupedServices[categoryId] ?? [];

                  if (services.isEmpty) return const SizedBox.shrink();

                  final isExpanded = _expandedCategories.contains(categoryId);
                  final selectedInCategory = services
                      .where((s) => _selected.contains(s.id))
                      .length;
                  final allSelectedInCategory =
                      selectedInCategory == services.length;
                  final someSelectedInCategory =
                      selectedInCategory > 0 && !allSelectedInCategory;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedCategories.remove(categoryId);
                            } else {
                              _expandedCategories.add(categoryId);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          color: colorScheme.surfaceContainerHighest
                              .withOpacity(0.5),
                          child: Row(
                            children: [
                              Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  categoryName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '$selectedInCategory/${services.length}',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Checkbox(
                                value: allSelectedInCategory
                                    ? true
                                    : someSelectedInCategory
                                    ? null
                                    : false,
                                tristate: true,
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true || checked == null) {
                                      for (final s in services) {
                                        _selected.add(s.id);
                                      }
                                    } else {
                                      for (final s in services) {
                                        _selected.remove(s.id);
                                      }
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isExpanded)
                        ...services.map((service) {
                          final isSelected = _selected.contains(service.id);
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.only(
                              left: 40,
                              right: 16,
                            ),
                            title: Text(service.name),
                            subtitle: service.price != null
                                ? Text(
                                    '€${service.price!.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  )
                                : null,
                            trailing: Checkbox(
                              value: isSelected,
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selected.add(service.id);
                                  } else {
                                    _selected.remove(service.id);
                                  }
                                });
                              },
                            ),
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selected.remove(service.id);
                                } else {
                                  _selected.add(service.id);
                                }
                              });
                            },
                          );
                        }),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: Text(l10n.actionApply),
        ),
      ],
    );
  }
}

class _CategoryDisplayItem {
  final int id;
  final String name;
  const _CategoryDisplayItem({required this.id, required this.name});
}

class _MultiSelectDialog<T> extends StatefulWidget {
  const _MultiSelectDialog({
    super.key,
    required this.title,
    required this.items,
    required this.selected,
  });

  final String title;
  final Map<T, String> items;
  final Set<T> selected;

  @override
  State<_MultiSelectDialog<T>> createState() => _MultiSelectDialogState<T>();
}

class _MultiSelectDialogState<T> extends State<_MultiSelectDialog<T>> {
  late Set<T> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<T>.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.items.entries.map((entry) {
            final isSelected = _selected.contains(entry.key);
            return CheckboxListTile(
              title: Text(entry.value),
              value: isSelected,
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _selected.add(entry.key);
                  } else {
                    _selected.remove(entry.key);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: Text(l10n.actionApply),
        ),
      ],
    );
  }
}

// ============================================================================
// Sort Controls
// ============================================================================

class _SortControls extends ConsumerWidget {
  final BookingsListFilters filters;
  final VoidCallback onChanged;

  const _SortControls({required this.filters, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {},
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: filters.sortBy,
                  isDense: true,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
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
                      ref
                          .read(bookingsListFiltersProvider.notifier)
                          .setSortBy(value);
                      onChanged();
                    }
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              ref.read(bookingsListFiltersProvider.notifier).toggleSortOrder();
              onChanged();
            },
            child: Tooltip(
              message: filters.sortOrder == 'asc'
                  ? l10n.bookingsListSortAsc
                  : l10n.bookingsListSortDesc,
              child: Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  filters.sortOrder == 'asc'
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Status Chip
// ============================================================================

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

// ============================================================================
// Booking Card (Mobile)
// ============================================================================

class _BookingCard extends StatelessWidget {
  final BookingListItem booking;
  final VoidCallback onView;
  final VoidCallback onCancel;
  final bool showStatus;

  const _BookingCard({
    required this.booking,
    required this.onView,
    required this.onCancel,
    this.showStatus = true,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
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
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (showStatus) _StatusChip(status: booking.status),
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
                ],
              ),
            ),
            Divider(
              height: 16,
              indent: 0,
              endIndent: 0,
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
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
            ),
          ],
        ),
      ),
    );
  }
}
