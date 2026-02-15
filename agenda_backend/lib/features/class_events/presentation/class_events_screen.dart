import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/app/providers/form_factor_provider.dart';
import '/core/models/class_event.dart';
import '../../auth/providers/current_business_user_provider.dart';
import '../providers/class_events_providers.dart';

class ClassEventsScreen extends ConsumerWidget {
  const ClassEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(classEventsProvider);
    final formFactor = ref.watch(formFactorProvider);
    final canReadParticipants = ref.watch(
      currentUserCanReadClassParticipantsProvider,
    );
    final canBookClassEvents = ref.watch(currentUserCanBookClassEventsProvider);
    final isDesktop = formFactor == AppFormFactor.desktop;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Class events'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(classEventsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (events) {
          if (events.isEmpty) {
            return const Center(
              child: Text('No class events in selected day.'),
            );
          }
          return ListView.separated(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 24 : 12,
              vertical: 12,
            ),
            itemBuilder: (_, index) => _ClassEventTile(
              event: events[index],
              canReadParticipants: canReadParticipants,
              canBookClassEvents: canBookClassEvents,
            ),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: events.length,
          );
        },
      ),
    );
  }
}

class _ClassEventTile extends ConsumerWidget {
  const _ClassEventTile({
    required this.event,
    required this.canReadParticipants,
    required this.canBookClassEvents,
  });

  final ClassEvent event;
  final bool canReadParticipants;
  final bool canBookClassEvents;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingController = ref.watch(classEventBookingControllerProvider);
    final isWorking = bookingController.isLoading;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              '${event.startsAtUtc.toLocal()} - ${event.endsAtUtc.toLocal()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Confirmed: ${event.confirmedCount}/${event.capacityTotal} • Waitlist: ${event.waitlistCount}',
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: (!canBookClassEvents || isWorking)
                      ? null
                      : () => ref
                            .read(classEventBookingControllerProvider.notifier)
                            .book(classEventId: event.id),
                  icon: const Icon(Icons.how_to_reg),
                  label: const Text('Book'),
                ),
                OutlinedButton.icon(
                  onPressed: (!canBookClassEvents || isWorking)
                      ? null
                      : () => ref
                            .read(classEventBookingControllerProvider.notifier)
                            .cancel(classEventId: event.id),
                  icon: const Icon(Icons.event_busy_outlined),
                  label: const Text('Cancel booking'),
                ),
                TextButton(
                  onPressed: !canReadParticipants
                      ? null
                      : () {
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) =>
                                _ParticipantsSheet(classEventId: event.id),
                          );
                        },
                  child: const Text('Participants'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantsSheet extends ConsumerWidget {
  const _ParticipantsSheet({required this.classEventId});

  final int classEventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participantsAsync = ref.watch(
      classEventParticipantsProvider(classEventId),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: participantsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
          data: (participants) => ListView.builder(
            shrinkWrap: true,
            itemCount: participants.length,
            itemBuilder: (_, index) {
              final participant = participants[index];
              final waitlistSuffix = participant.waitlistPosition != null
                  ? ' (#${participant.waitlistPosition})'
                  : '';
              return ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text('Customer ${participant.customerId}'),
                subtitle: Text('${participant.status}$waitlistSuffix'),
              );
            },
          ),
        ),
      ),
    );
  }
}
