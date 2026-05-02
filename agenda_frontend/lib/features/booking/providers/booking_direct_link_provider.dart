import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/route_slug_provider.dart';
import '../../../core/network/network_providers.dart';
import '../domain/booking_direct_link.dart';

final bookingDirectLinkSlugProvider =
    NotifierProvider<BookingDirectLinkSlugNotifier, String?>(
      BookingDirectLinkSlugNotifier.new,
    );

class BookingDirectLinkSlugNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setFromQueryParam(String? value) {
    final normalized = value?.trim();
    state = normalized == null || normalized.isEmpty ? null : normalized;
  }
}

final bookingDirectLinkProvider = FutureProvider<BookingDirectLink?>((
  ref,
) async {
  final businessSlug = ref.watch(routeSlugProvider);
  final linkSlug = ref.watch(bookingDirectLinkSlugProvider);

  if (businessSlug == null || linkSlug == null) {
    return null;
  }

  final apiClient = ref.watch(apiClientProvider);
  final data = await apiClient.resolveBookingDirectLink(
    businessSlug: businessSlug,
    linkSlug: linkSlug,
  );

  return BookingDirectLink.fromJson(data);
}, retry: null);

/// Provider che indica se c'è un errore bloccante per il direct link
final bookingDirectLinkBlockingErrorProvider = Provider<bool>((ref) {
  final linkSlug = ref.watch(bookingDirectLinkSlugProvider);
  if (linkSlug == null) return false;

  final directLinkAsync = ref.watch(bookingDirectLinkProvider);
  return directLinkAsync.hasError;
});

/// Provider che indica se il direct link è in risoluzione
final bookingDirectLinkIsResolvingProvider = Provider<bool>((ref) {
  final linkSlug = ref.watch(bookingDirectLinkSlugProvider);
  if (linkSlug == null) return false;

  final directLinkAsync = ref.watch(bookingDirectLinkProvider);
  return directLinkAsync.isLoading;
});
