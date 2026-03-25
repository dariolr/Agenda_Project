import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '/app/providers/form_factor_provider.dart';
import '/core/l10n/l10_extension.dart';
import '/core/models/business.dart';
import '/core/models/booking_notification_item.dart';
import '/core/services/tenant_time_service.dart';
import '/core/widgets/app_bottom_sheet.dart';
import '/core/widgets/feedback_dialog.dart';
import '/features/agenda/providers/business_providers.dart';
import '/features/agenda/providers/location_providers.dart';
import '/features/agenda/providers/tenant_time_provider.dart';
import '/features/auth/providers/auth_provider.dart';
import '/features/booking_notifications/providers/booking_notifications_provider.dart';
import '/features/booking_notifications/providers/whatsapp_integration_provider.dart';
import '/features/booking_notifications/presentation/whatsapp_management_panel.dart';

class BookingNotificationsScreen extends ConsumerStatefulWidget {
  const BookingNotificationsScreen({
    super.key,
    this.enableBusinessSelectorForSuperadmin = false,
    this.showStandaloneAppBar = false,
  });

  final bool enableBusinessSelectorForSuperadmin;
  final bool showStandaloneAppBar;

  @override
  ConsumerState<BookingNotificationsScreen> createState() =>
      _BookingNotificationsScreenState();
}

class _BookingNotificationsScreenState
    extends ConsumerState<BookingNotificationsScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  String? _selectedStatus;
  String? _selectedChannel;
  int? _selectedBusinessId;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (_canSelectBusiness) {
      _selectedStatus = 'failed';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (_canSelectBusiness) {
        ref.read(bookingNotificationsFiltersProvider.notifier).setStatus(const [
          'failed',
        ]);
      }
      await _loadInitialData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  bool get _isSuperadmin => ref.read(authProvider).user?.isSuperadmin ?? false;

  bool get _canSelectBusiness =>
      widget.enableBusinessSelectorForSuperadmin && _isSuperadmin;

  int get _fallbackBusinessId => ref.read(currentLocationProvider).businessId;

  List<int> _activeBusinessIds(List<Business> businesses) {
    if (_canSelectBusiness) {
      if (_selectedBusinessId == null) {
        return businesses.map((b) => b.id).toList();
      }
      return [_selectedBusinessId!];
    }
    return [_fallbackBusinessId];
  }

  List<Business> _readBusinesses() {
    return ref
        .read(businessesProvider)
        .maybeWhen(
          data: (businesses) => businesses,
          orElse: () => const <Business>[],
        );
  }

  String _formatDateTime(BuildContext context, DateTime? dateTime) {
    if (dateTime == null) return context.l10n.bookingNotificationsNotAvailable;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final timezone = ref.read(effectiveTenantTimezoneProvider);
    final tenantDateTime = dateTime.isUtc
        ? TenantTimeService.fromUtcToTenant(dateTime, timezone)
        : TenantTimeService.assumeTenantLocal(dateTime, timezone);
    return DateFormat('dd/MM/yyyy HH:mm', locale).format(tenantDateTime);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    final businesses = _readBusinesses();
    final ids = _activeBusinessIds(businesses);
    await ref
        .read(bookingNotificationsProvider.notifier)
        .loadMoreForBusinesses(ids);
  }

  Future<void> _loadInitialData() async {
    final businesses = _readBusinesses();
    final ids = _activeBusinessIds(businesses);
    await ref
        .read(bookingNotificationsProvider.notifier)
        .loadNotificationsForBusinesses(ids);
  }

  int? get _selectedBusinessForWhatsapp =>
      _canSelectBusiness ? _selectedBusinessId : _fallbackBusinessId;

  Future<void> _loadWhatsappDataIfPossible() async {
    final businessId = _selectedBusinessForWhatsapp;
    if (businessId == null || businessId <= 0) return;
    await ref
        .read(whatsappIntegrationProvider.notifier)
        .loadBusinessWhatsappData(businessId);
  }

  void _onSearchChanged(String value) {
    ref.read(bookingNotificationsFiltersProvider.notifier).setSearch(value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      ref
          .read(bookingNotificationsProvider.notifier)
          .loadNotificationsForBusinesses(
            _activeBusinessIds(_readBusinesses()),
          );
    });
  }

  void _onStatusChanged(String? value) {
    setState(() => _selectedStatus = value);
    ref
        .read(bookingNotificationsFiltersProvider.notifier)
        .setStatus(value == null ? null : [value]);
    ref
        .read(bookingNotificationsProvider.notifier)
        .loadNotificationsForBusinesses(_activeBusinessIds(_readBusinesses()));
  }

  void _onChannelChanged(String? value) {
    setState(() => _selectedChannel = value);
    ref
        .read(bookingNotificationsFiltersProvider.notifier)
        .setChannels(value == null ? null : [value]);
    ref
        .read(bookingNotificationsProvider.notifier)
        .loadNotificationsForBusinesses(_activeBusinessIds(_readBusinesses()));
  }

  void _onBusinessChanged(int? value) {
    setState(() => _selectedBusinessId = value);
    ref
        .read(bookingNotificationsProvider.notifier)
        .loadNotificationsForBusinesses(_activeBusinessIds(_readBusinesses()));
    _loadWhatsappDataIfPossible();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(bookingNotificationsProvider);
    final formFactor = ref.watch(formFactorProvider);
    final isDesktop = formFactor == AppFormFactor.desktop;
    final businesses = ref
        .watch(businessesProvider)
        .maybeWhen(
          data: (businesses) => businesses,
          orElse: () => const <Business>[],
        );

    ref.listen<BookingNotificationsState>(bookingNotificationsProvider, (
      prev,
      next,
    ) async {
      if (prev?.error != next.error && next.error != null && mounted) {
        await FeedbackDialog.showError(
          context,
          title: l10n.errorTitle,
          message: next.error!,
        );
      }
    });
    ref.listen<WhatsappIntegrationState>(whatsappIntegrationProvider, (
      prev,
      next,
    ) async {
      if (prev?.error != next.error && next.error != null && mounted) {
        await FeedbackDialog.showError(
          context,
          title: l10n.errorTitle,
          message: next.error!,
        );
      }
    });

    return Scaffold(
      appBar: widget.showStandaloneAppBar
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/businesses'),
              ),
              title: Text(l10n.bookingNotificationsTitle),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<int>(
                    segments: <ButtonSegment<int>>[
                      ButtonSegment<int>(
                        value: 0,
                        icon: const Icon(Icons.history_rounded),
                        label: Text(l10n.bookingNotificationsTitle),
                      ),
                      ButtonSegment<int>(
                        value: 1,
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: Text(l10n.whatsappTabTitle),
                      ),
                    ],
                    selected: <int>{_selectedTabIndex},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) {
                      final next = selection.first;
                      setState(() => _selectedTabIndex = next);
                      if (next == 1) {
                        _loadWhatsappDataIfPossible();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_selectedTabIndex == 0) ...[
            _FiltersBar(
              searchController: _searchController,
              selectedStatus: _selectedStatus,
              selectedChannel: _selectedChannel,
              showBusinessFilter: _canSelectBusiness,
              selectedBusinessId: _selectedBusinessId,
              businesses: businesses,
              onSearchChanged: _onSearchChanged,
              onStatusChanged: _onStatusChanged,
              onChannelChanged: _onChannelChanged,
              onBusinessChanged: _onBusinessChanged,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Text(
                    l10n.bookingNotificationsTotalCount(state.total),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Expanded(child: _buildContent(state, isDesktop: isDesktop)),
          ] else ...[
            Expanded(
              child: WhatsappManagementPanel(
                businessId: _selectedBusinessForWhatsapp,
                requireBusinessSelection: _canSelectBusiness,
                businesses: businesses,
                selectedBusinessId: _selectedBusinessId,
                onBusinessChanged: _onBusinessChanged,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(
    BookingNotificationsState state, {
    required bool isDesktop,
  }) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
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
            const Icon(Icons.notifications_off_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              l10n.bookingNotificationsEmpty,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.bookingNotificationsEmptyHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (isDesktop) {
      return _buildDataTable(state);
    }
    return _buildCardList(state);
  }

  Widget _buildDataTable(BookingNotificationsState state) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final showLastAttemptColumn = _canSelectBusiness;
    final filters = ref.watch(bookingNotificationsFiltersProvider);
    final sortBy = filters.sortBy;
    final sortAscending = filters.sortOrder == 'asc';
    final sortColumnIndex = switch (sortBy) {
      'created' => 0,
      'last_attempt' => showLastAttemptColumn ? 1 : null,
      'sent' => showLastAttemptColumn ? 2 : 1,
      'appointment' => showLastAttemptColumn ? 6 : 5,
      _ => null,
    };

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: SingleChildScrollView(
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
                  showCheckboxColumn: false,
                  dividerThickness: 0.2,
                  horizontalMargin: 16,
                  sortColumnIndex: sortColumnIndex,
                  sortAscending: sortAscending,
                  headingRowColor: WidgetStateProperty.all(
                    colorScheme.surfaceContainerHighest,
                  ),
                  columns: [
                    DataColumn(
                      label: Text(l10n.bookingNotificationsFieldCreatedAt),
                      onSort: (_, ascending) =>
                          _onSortChanged('created', ascending),
                    ),
                    if (showLastAttemptColumn)
                      DataColumn(
                        label: Text(
                          l10n.bookingNotificationsFieldLastAttemptAt,
                        ),
                        onSort: (_, ascending) =>
                            _onSortChanged('last_attempt', ascending),
                      ),
                    DataColumn(
                      label: Text(l10n.bookingNotificationsFieldSentAt),
                      onSort: (_, ascending) =>
                          _onSortChanged('sent', ascending),
                    ),
                    DataColumn(
                      label: Text(l10n.bookingNotificationsFieldClient),
                    ),
                    DataColumn(label: Text(l10n.bookingNotificationsFieldType)),
                    DataColumn(
                      label: Text(l10n.bookingNotificationsFieldRecipient),
                    ),
                    DataColumn(
                      label: Text(l10n.bookingNotificationsFilterStatus),
                    ),
                    DataColumn(
                      label: Text(l10n.bookingNotificationsFieldAppointment),
                      onSort: (_, ascending) =>
                          _onSortChanged('appointment', ascending),
                    ),
                    DataColumn(
                      label: Text(l10n.bookingNotificationsFieldLocation),
                    ),
                    DataColumn(
                      label: Text(l10n.bookingNotificationsFieldError),
                    ),
                  ],
                  rows: state.notifications.map(_buildDataRow).toList(),
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
                  onPressed: () => ref
                      .read(bookingNotificationsProvider.notifier)
                      .loadMoreForBusinesses(
                        _activeBusinessIds(_readBusinesses()),
                      ),
                  child: Text(l10n.bookingNotificationsLoadMore),
                ),
              ),
          ],
        ),
      ),
    );
  }

  DataRow _buildDataRow(BookingNotificationItem item) {
    final showLastAttemptColumn = _canSelectBusiness;
    return DataRow(
      onSelectChanged: (_) => _showNotificationBody(item),
      cells: [
        _tappableDataCell(item, Text(_formatDateTime(context, item.createdAt))),
        if (showLastAttemptColumn)
          _tappableDataCell(
            item,
            Text(
              item.lastAttemptAt != null
                  ? _formatDateTime(context, item.lastAttemptAt)
                  : '',
            ),
          ),
        _tappableDataCell(
          item,
          Text(
            item.sentAt != null ? _formatDateTime(context, item.sentAt) : '',
          ),
        ),
        _tappableDataCell(
          item,
          SizedBox(
            width: 180,
            child: Text(
              item.clientName ?? context.l10n.bookingNotificationsNotAvailable,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        _tappableDataCell(
          item,
          SizedBox(
            width: 170,
            child: Text(
              item.channelLabel(context),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        _tappableDataCell(
          item,
          SizedBox(
            width: 220,
            child: Text(
              item.recipientEmail ??
                  context.l10n.bookingNotificationsNotAvailable,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        _tappableDataCell(item, _NotificationStatusChip(item: item)),
        _tappableDataCell(
          item,
          Text(_formatDateTime(context, item.firstStartTime)),
        ),
        _tappableDataCell(
          item,
          SizedBox(
            width: 150,
            child: Text(
              item.locationName ??
                  context.l10n.bookingNotificationsNotAvailable,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        _tappableDataCell(
          item,
          SizedBox(
            width: 240,
            child: Text(
              item.errorMessage ?? '-',
              overflow: TextOverflow.ellipsis,
              style: item.errorMessage != null
                  ? TextStyle(color: Theme.of(context).colorScheme.error)
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  DataCell _tappableDataCell(BookingNotificationItem item, Widget child) {
    return DataCell(child, onTap: () => _showNotificationBody(item));
  }

  void _onSortChanged(String sortBy, bool ascending) {
    ref.read(bookingNotificationsFiltersProvider.notifier).setSortBy(sortBy);
    ref
        .read(bookingNotificationsFiltersProvider.notifier)
        .setSortOrder(ascending ? 'asc' : 'desc');
    ref
        .read(bookingNotificationsProvider.notifier)
        .loadNotificationsForBusinesses(_activeBusinessIds(_readBusinesses()));
  }

  bool _shouldShowNotificationError(BookingNotificationItem item) {
    final error = item.errorMessage?.trim();
    return error != null && error.isNotEmpty;
  }

  String _notificationBodyContent(BookingNotificationItem item) {
    if (_shouldShowNotificationError(item)) {
      final error = item.errorMessage?.trim();
      return error ?? '';
    }

    final body = item.body?.trim();
    if (body != null && body.isNotEmpty) {
      return body;
    }
    return '';
  }

  String _notificationTitle(BookingNotificationItem item) {
    if (_shouldShowNotificationError(item)) {
      return context.l10n.bookingNotificationsFieldError;
    }

    final subject = item.subject?.trim();
    if (subject != null && subject.isNotEmpty) {
      return subject;
    }
    return context.l10n.bookingNotificationsBodyDialogTitle;
  }

  String _notificationEmptyLabel(BookingNotificationItem item) {
    if (_shouldShowNotificationError(item)) {
      return context.l10n.bookingNotificationsNotAvailable;
    }
    return context.l10n.bookingNotificationsBodyUnavailable;
  }

  Future<void> _showNotificationBody(BookingNotificationItem item) async {
    final body = _notificationBodyContent(item);
    final title = _notificationTitle(item);
    final emptyLabel = _notificationEmptyLabel(item);
    final l10n = context.l10n;
    final isDesktop = ref.read(formFactorProvider) == AppFormFactor.desktop;

    if (isDesktop) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 760,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 560),
              child: SingleChildScrollView(
                child: _NotificationBodyViewer(
                  body: body,
                  emptyLabel: emptyLabel,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.actionClose),
            ),
          ],
        ),
      );
      return;
    }

    await AppBottomSheet.show<void>(
      context: context,
      heightFactor: AppBottomSheet.defaultHeightFactor,
      builder: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: _NotificationBodyViewer(
                body: body,
                emptyLabel: emptyLabel,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardList(BookingNotificationsState state) {
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        itemCount: state.notifications.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.notifications.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final item = state.notifications[index];
          return _NotificationCard(
            notification: item,
            onOpenBody: () => _showNotificationBody(item),
          );
        },
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.searchController,
    required this.selectedStatus,
    required this.selectedChannel,
    required this.showBusinessFilter,
    required this.selectedBusinessId,
    required this.businesses,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onChannelChanged,
    required this.onBusinessChanged,
  });

  final TextEditingController searchController;
  final String? selectedStatus;
  final String? selectedChannel;
  final bool showBusinessFilter;
  final int? selectedBusinessId;
  final List<Business> businesses;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onChannelChanged;
  final ValueChanged<int?> onBusinessChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final searchWidth = availableWidth < 340 ? availableWidth : 320.0;
          final businessWidth = availableWidth < 280 ? availableWidth : 260.0;
          final statusWidth = availableWidth < 240 ? availableWidth : 220.0;
          final typeWidth = availableWidth < 270 ? availableWidth : 250.0;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: searchWidth,
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    labelText: l10n.bookingNotificationsSearchLabel,
                    hintText: l10n.bookingNotificationsSearchHint,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              if (showBusinessFilter)
                SizedBox(
                  width: businessWidth,
                  child: DropdownButtonFormField<int?>(
                    value: selectedBusinessId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.profileSwitchBusiness,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(
                          l10n.filterAll,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ...businesses.map(
                        (business) => DropdownMenuItem<int?>(
                          value: business.id,
                          child: Text(
                            business.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: onBusinessChanged,
                  ),
                ),
              SizedBox(
                width: statusWidth,
                child: DropdownButtonFormField<String?>(
                  value: selectedStatus,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.bookingNotificationsFilterStatus,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        l10n.bookingNotificationsStatusAll,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'pending',
                      child: Text(
                        l10n.bookingNotificationsStatusPending,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'processing',
                      child: Text(
                        l10n.bookingNotificationsStatusProcessing,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'sent',
                      child: Text(
                        l10n.bookingNotificationsStatusSent,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'failed',
                      child: Text(
                        l10n.bookingNotificationsStatusFailed,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: onStatusChanged,
                ),
              ),
              SizedBox(
                width: typeWidth,
                child: DropdownButtonFormField<String?>(
                  value: selectedChannel,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.bookingNotificationsFilterType,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        l10n.bookingNotificationsTypeAll,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'booking_confirmed',
                      child: Text(
                        l10n.bookingNotificationsChannelConfirmed,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'booking_rescheduled',
                      child: Text(
                        l10n.bookingNotificationsChannelRescheduled,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'booking_cancelled',
                      child: Text(
                        l10n.bookingNotificationsChannelCancelled,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'booking_reminder',
                      child: Text(
                        l10n.bookingNotificationsChannelReminder,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: onChannelChanged,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  const _NotificationCard({
    required this.notification,
    required this.onOpenBody,
  });

  final BookingNotificationItem notification;
  final VoidCallback onOpenBody;

  String _formatDateTime(
    WidgetRef ref,
    BuildContext context,
    DateTime? dateTime,
  ) {
    if (dateTime == null) return context.l10n.bookingNotificationsNotAvailable;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final timezone = ref.read(effectiveTenantTimezoneProvider);
    final tenantDateTime = dateTime.isUtc
        ? TenantTimeService.fromUtcToTenant(dateTime, timezone)
        : TenantTimeService.assumeTenantLocal(dateTime, timezone);
    return DateFormat('dd/MM/yyyy HH:mm', locale).format(tenantDateTime);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onOpenBody,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      notification.subject?.trim().isNotEmpty == true
                          ? notification.subject!
                          : l10n.bookingNotificationsNoSubject,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _NotificationStatusChip(item: notification),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${l10n.bookingNotificationsFieldType}: ${notification.channelLabel(context)}',
                style: theme.textTheme.bodyMedium,
              ),
              if ((notification.clientName ?? '').isNotEmpty)
                Text(
                  '${l10n.bookingNotificationsFieldClient}: ${notification.clientName}',
                  style: theme.textTheme.bodyMedium,
                ),
              if ((notification.locationName ?? '').isNotEmpty)
                Text(
                  '${l10n.bookingNotificationsFieldLocation}: ${notification.locationName}',
                  style: theme.textTheme.bodyMedium,
                ),
              if (notification.firstStartTime != null)
                Text(
                  '${l10n.bookingNotificationsFieldAppointment}: ${_formatDateTime(ref, context, notification.firstStartTime)}',
                  style: theme.textTheme.bodyMedium,
                ),
              Text(
                '${l10n.bookingNotificationsFieldRecipient}: ${notification.recipientEmail ?? l10n.bookingNotificationsNotAvailable}',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                '${l10n.bookingNotificationsFieldCreatedAt}: ${_formatDateTime(ref, context, notification.createdAt)}',
                style: theme.textTheme.bodySmall,
              ),
              if (notification.sentAt != null)
                Text(
                  '${l10n.bookingNotificationsFieldSentAt}: ${_formatDateTime(ref, context, notification.sentAt)}',
                  style: theme.textTheme.bodySmall,
                ),
              if ((notification.errorMessage ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${l10n.bookingNotificationsFieldError}: ${notification.errorMessage}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationBodyViewer extends StatelessWidget {
  const _NotificationBodyViewer({required this.body, required this.emptyLabel});

  final String body;
  final String emptyLabel;

  bool get _looksLikeHtml =>
      RegExp(r'<[a-zA-Z][\s\S]*>').hasMatch(body) ||
      body.toLowerCase().contains('<!doctype html');

  @override
  Widget build(BuildContext context) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return Text(emptyLabel, style: Theme.of(context).textTheme.bodyMedium);
    }

    if (_looksLikeHtml) {
      final plainText = _htmlToReadableText(trimmed);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Html(data: trimmed),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          SelectableText(
            plainText.isNotEmpty ? plainText : trimmed,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
    }

    return SelectableText(
      trimmed,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

String _htmlToReadableText(String html) {
  return html
      .replaceAll(
        RegExp(
          r'<script[^>]*>.*?</script>',
          caseSensitive: false,
          dotAll: true,
        ),
        ' ',
      )
      .replaceAll(
        RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false, dotAll: true),
        ' ',
      )
      .replaceAll(RegExp(r'<br\\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p\\s*>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r' *\n *'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

class _NotificationStatusChip extends StatelessWidget {
  const _NotificationStatusChip({required this.item});

  final BookingNotificationItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: item.statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        item.statusLabel(context),
        style: theme.textTheme.labelMedium?.copyWith(
          color: item.statusColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
