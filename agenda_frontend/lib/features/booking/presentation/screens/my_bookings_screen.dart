import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '/app/providers/form_factor_provider.dart';
import '/core/l10n/l10_extension.dart';
import '/core/models/booking_item.dart';
import '/core/widgets/booking_app_bar.dart';
import '/core/widgets/feedback_dialog.dart';
import '/features/auth/domain/auth_state.dart';
import '/features/auth/providers/auth_provider.dart';
import '/features/booking/providers/locations_provider.dart';
import '/features/booking/providers/my_bookings_provider.dart';
import '../dialogs/booking_history_dialog.dart';
import '../dialogs/reschedule_booking_dialog.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isCancellingBooking = false;
  bool _hasRequestedLoad = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(
      authProvider,
      (previous, next) {
        if (!next.isAuthenticated) {
          _hasRequestedLoad = false;
          return;
        }
        if (_hasRequestedLoad) return;
        _hasRequestedLoad = true;
        ref.read(myBookingsProvider.notifier).loadBookings();
      },
    );

    final authState = ref.watch(authProvider);
    if (authState.isAuthenticated && !_hasRequestedLoad) {
      _hasRequestedLoad = true;
      Future.microtask(
        () => ref.read(myBookingsProvider.notifier).loadBookings(),
      );
    }

    final bookingsState = ref.watch(myBookingsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    return Scaffold(
      appBar: BookingAppBar(
        showBackButton: true,
        onBackPressed: () => context.pop(),
        showUserMenu: false,
        title: l10n.myBookings,
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: colorScheme.primary,
          indicatorWeight: 2,
          labelStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(text: context.l10n.upcomingBookings),
            Tab(text: context.l10n.pastBookings),
          ],
        ),
      ),
      body: Stack(
        children: [
          bookingsState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : bookingsState.error != null
              ? _ErrorView(error: bookingsState.error!)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _BookingsList(
                            bookings: bookingsState.upcoming,
                            isUpcoming: true,
                            onCancelLoadingChanged: _setCancelLoading,
                          ),
                          _BookingsList(
                            bookings: bookingsState.past,
                            isUpcoming: false,
                            onCancelLoadingChanged: _setCancelLoading,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          if (_isCancellingBooking)
            Positioned.fill(
              child: AbsorbPointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.6),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _setCancelLoading(bool value) {
    if (_isCancellingBooking == value) return;
    setState(() => _isCancellingBooking = value);
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              context.l10n.errorLoadingBookings,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingsList extends StatelessWidget {
  const _BookingsList({
    required this.bookings,
    required this.isUpcoming,
    required this.onCancelLoadingChanged,
  });

  final List<BookingItem> bookings;
  final bool isUpcoming;
  final ValueChanged<bool> onCancelLoadingChanged;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming ? Icons.event_busy : Icons.history,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming
                  ? context.l10n.noUpcomingBookings
                  : context.l10n.noPastBookings,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _BookingCard(
          booking: booking,
          isUpcoming: isUpcoming,
          onCancelLoadingChanged: onCancelLoadingChanged,
        );
      },
    );
  }
}

class _BookingCard extends ConsumerStatefulWidget {
  const _BookingCard({
    required this.booking,
    required this.isUpcoming,
    required this.onCancelLoadingChanged,
  });

  final BookingItem booking;
  final bool isUpcoming;
  final ValueChanged<bool> onCancelLoadingChanged;

  @override
  ConsumerState<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends ConsumerState<_BookingCard> {
  bool _isCancelling = false;

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final formFactor = ref.watch(formFactorProvider);
    final locationsAsync = ref.watch(locationsProvider);
    final showLocation = locationsAsync.maybeWhen(
      data: (locations) => locations.length > 1,
      orElse: () => true,
    );
    final dateFormat = DateFormat('dd/MM/yyyy', 'it');
    final timeFormat = DateFormat('HH:mm', 'it');
    final theme = Theme.of(context);
    const actionButtonPadding = EdgeInsets.symmetric(horizontal: 12);
    final modifyButtonStyle = ElevatedButton.styleFrom(
      minimumSize: const Size(0, 40),
      padding: actionButtonPadding,
    );
    final cancelButtonStyle = OutlinedButton.styleFrom(
      minimumSize: const Size(0, 40),
      padding: actionButtonPadding,
      foregroundColor: theme.colorScheme.error,
      side: BorderSide(color: theme.colorScheme.error),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intestazione con business e location
            Row(
              children: [
                const Icon(Icons.business, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.businessName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                // Badge CANCELLATO
                if (booking.isCancelled)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      context.l10n.cancelledBadge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                // Pulsante storico
                IconButton(
                  icon: const Icon(Icons.history, size: 20),
                  tooltip: context.l10n.bookingHistoryTitle,
                  onPressed: () => showBookingHistoryDialog(
                    context,
                    ref,
                    bookingId: booking.id,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (showLocation)
              Row(
                children: [
                  const Icon(Icons.location_on, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(booking.locationName, style: theme.textTheme.bodyMedium),
                ],
              ),
            const Divider(height: 24),

            // Servizi
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.list_alt, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: booking.serviceNames.length <= 1
                      ? Text(
                          booking.servicesDisplay,
                          style: theme.textTheme.bodyMedium,
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final service in booking.serviceNames)
                              Text(service, style: theme.textTheme.bodyMedium),
                          ],
                        ),
                ),
              ],
            ),

            // Staff (se presente)
            if (booking.staffName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    booking.staffName!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),

            // Data e ora
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18),
                const SizedBox(width: 8),
                Text(dateFormat.format(booking.startTime)),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${timeFormat.format(booking.startTime)} - ${timeFormat.format(booking.endTime)}',
                ),
              ],
            ),

            // Prezzo (se > 0)
            if (booking.totalPrice > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.euro, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    booking.totalPrice.toStringAsFixed(2),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],

            // Note (se presenti)
            if (booking.notes != null && booking.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.sticky_note_2_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking.notes!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],

            // Badge e azioni per prenotazioni future (non cancellate)
            if (widget.isUpcoming && !booking.isCancelled) ...[
              const SizedBox(height: 16),
              if (formFactor == AppFormFactor.mobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (booking.canModify && booking.canModifyUntil != null)
                      Text(
                        _formatTimeUntil(context, booking.canModifyUntil!),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (booking.canModify) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => _handleModify(context, ref),
                            style: modifyButtonStyle,
                            child: Text(context.l10n.modify),
                          ),
                          const Spacer(),
                          OutlinedButton(
                            onPressed: _isCancelling
                                ? null
                                : () => _handleCancel(context, ref),
                            style: cancelButtonStyle,
                            child: _isCancelling
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(context.l10n.actionDelete),
                          ),
                        ],
                      ),
                    ],
                  ],
                )
              else
                Row(
                  children: [
                    // Countdown se modificabile
                    if (booking.canModify && booking.canModifyUntil != null)
                      Text(
                        _formatTimeUntil(context, booking.canModifyUntil!),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),

                    const Spacer(),

                    // Pulsanti azione
                    if (booking.canModify) ...[
                      ElevatedButton(
                        onPressed: () => _handleModify(context, ref),
                        style: modifyButtonStyle,
                        child: Text(context.l10n.modify),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _isCancelling
                            ? null
                            : () => _handleCancel(context, ref),
                        style: cancelButtonStyle,
                        child: _isCancelling
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(context.l10n.actionDelete),
                      ),
                    ],
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimeUntil(BuildContext context, DateTime deadline) {
    final now = DateTime.now();
    final diff = deadline.difference(now);

    if (diff.inHours > 24) {
      final days = diff.inDays;
      return context.l10n.modifiableUntilDays(days);
    } else if (diff.inHours > 0) {
      return context.l10n.modifiableUntilHours(diff.inHours);
    } else {
      return context.l10n.modifiableUntilMinutes(diff.inMinutes);
    }
  }

  Future<void> _handleModify(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => RescheduleBookingDialog(booking: widget.booking),
    );

    if (result == true && context.mounted) {
      await FeedbackDialog.showSuccess(
        context,
        title: context.l10n.rescheduleBookingTitle,
        message: context.l10n.bookingRescheduled,
      );
    }
  }

  Future<void> _handleCancel(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.cancelBookingTitle),
        content: Text(context.l10n.cancelBookingConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      setState(() => _isCancelling = true);
      widget.onCancelLoadingChanged(true);
      final success = await ref
          .read(myBookingsProvider.notifier)
          .cancelBooking(widget.booking.locationId, widget.booking.id);
      if (mounted) {
        setState(() => _isCancelling = false);
        widget.onCancelLoadingChanged(false);
      }

      if (context.mounted) {
        if (success) {
          await FeedbackDialog.showSuccess(
            context,
            title: context.l10n.cancelBookingTitle,
            message: context.l10n.bookingCancelled,
          );
        } else {
          await FeedbackDialog.showError(
            context,
            title: context.l10n.errorTitle,
            message: context.l10n.bookingCancelFailed,
          );
        }
      }
    }
  }
}
