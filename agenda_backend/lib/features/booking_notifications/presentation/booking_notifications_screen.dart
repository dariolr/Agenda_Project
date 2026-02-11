import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '/app/providers/form_factor_provider.dart';
import '/core/l10n/l10_extension.dart';
import '/core/models/booking_notification_item.dart';
import '/core/widgets/feedback_dialog.dart';
import '/features/agenda/providers/location_providers.dart';
import '/features/booking_notifications/providers/booking_notifications_provider.dart';

class BookingNotificationsScreen extends ConsumerStatefulWidget {
  const BookingNotificationsScreen({super.key});

  @override
  ConsumerState<BookingNotificationsScreen> createState() =>
      _BookingNotificationsScreenState();
}

class _BookingNotificationsScreenState
    extends ConsumerState<BookingNotificationsScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String? _selectedStatus;
  String? _selectedChannel;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  int get _businessId => ref.read(currentLocationProvider).businessId;

  String _formatDateTime(BuildContext context, DateTime? dateTime) {
    if (dateTime == null) return context.l10n.bookingNotificationsNotAvailable;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat('dd/MM/yyyy HH:mm', locale).format(dateTime.toLocal());
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(bookingNotificationsProvider.notifier).loadMore(_businessId);
    }
  }

  Future<void> _loadInitialData() async {
    await ref
        .read(bookingNotificationsProvider.notifier)
        .loadNotifications(_businessId);
  }

  void _onSearchChanged(String value) {
    ref.read(bookingNotificationsFiltersProvider.notifier).setSearch(value);
    ref
        .read(bookingNotificationsProvider.notifier)
        .loadNotifications(_businessId);
  }

  void _onStatusChanged(String? value) {
    setState(() => _selectedStatus = value);
    ref
        .read(bookingNotificationsFiltersProvider.notifier)
        .setStatus(value == null ? null : [value]);
    ref
        .read(bookingNotificationsProvider.notifier)
        .loadNotifications(_businessId);
  }

  void _onChannelChanged(String? value) {
    setState(() => _selectedChannel = value);
    ref
        .read(bookingNotificationsFiltersProvider.notifier)
        .setChannels(value == null ? null : [value]);
    ref
        .read(bookingNotificationsProvider.notifier)
        .loadNotifications(_businessId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(bookingNotificationsProvider);
    final formFactor = ref.watch(formFactorProvider);
    final isDesktop = formFactor == AppFormFactor.desktop;

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

    return Scaffold(
      body: Column(
        children: [
          _FiltersBar(
            searchController: _searchController,
            selectedStatus: _selectedStatus,
            selectedChannel: _selectedChannel,
            onSearchChanged: _onSearchChanged,
            onStatusChanged: _onStatusChanged,
            onChannelChanged: _onChannelChanged,
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
                  dividerThickness: 0.2,
                  horizontalMargin: 16,
                  headingRowColor: WidgetStateProperty.all(
                    colorScheme.surfaceContainerHighest,
                  ),
                  columns: [
                    DataColumn(
                      label: Text(l10n.bookingNotificationsFieldCreatedAt),
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
                      .loadMore(_businessId),
                  child: Text(l10n.bookingNotificationsLoadMore),
                ),
              ),
          ],
        ),
      ),
    );
  }

  DataRow _buildDataRow(BookingNotificationItem item) {
    return DataRow(
      cells: [
        DataCell(Text(_formatDateTime(context, item.createdAt))),
        DataCell(
          SizedBox(
            width: 180,
            child: Text(
              item.clientName ?? context.l10n.bookingNotificationsNotAvailable,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 170,
            child: Text(
              item.channelLabel(context),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 220,
            child: Text(
              item.recipientEmail ??
                  context.l10n.bookingNotificationsNotAvailable,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(_NotificationStatusChip(item: item)),
        DataCell(Text(_formatDateTime(context, item.firstStartTime))),
        DataCell(
          SizedBox(
            width: 150,
            child: Text(
              item.locationName ??
                  context.l10n.bookingNotificationsNotAvailable,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
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
          return _NotificationCard(notification: state.notifications[index]);
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
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onChannelChanged,
  });

  final TextEditingController searchController;
  final String? selectedStatus;
  final String? selectedChannel;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onChannelChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final searchWidth = availableWidth < 340 ? availableWidth : 320.0;
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

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification});

  final BookingNotificationItem notification;

  String _formatDateTime(BuildContext context, DateTime? dateTime) {
    if (dateTime == null) return context.l10n.bookingNotificationsNotAvailable;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat('dd/MM/yyyy HH:mm', locale).format(dateTime.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                '${l10n.bookingNotificationsFieldAppointment}: ${_formatDateTime(context, notification.firstStartTime)}',
                style: theme.textTheme.bodyMedium,
              ),
            Text(
              '${l10n.bookingNotificationsFieldRecipient}: ${notification.recipientEmail ?? l10n.bookingNotificationsNotAvailable}',
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              '${l10n.bookingNotificationsFieldCreatedAt}: ${_formatDateTime(context, notification.createdAt)}',
              style: theme.textTheme.bodySmall,
            ),
            if (notification.sentAt != null)
              Text(
                '${l10n.bookingNotificationsFieldSentAt}: ${_formatDateTime(context, notification.sentAt)}',
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
    );
  }
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
