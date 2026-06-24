import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/route_slug_provider.dart';
import '../../../core/network/network_providers.dart';
import '../domain/booking_direct_link.dart';
import 'locations_provider.dart';

class DirectLinkMissingLocationException implements Exception {
  const DirectLinkMissingLocationException();
}

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

  final urlLocationId = ref.watch(urlLocationIdProvider);

  final apiClient = ref.watch(apiClientProvider);
  final data = await apiClient.resolveBookingDirectLink(
    businessSlug: businessSlug,
    linkSlug: linkSlug,
    locationId: urlLocationId != null && urlLocationId > 0
        ? urlLocationId
        : null,
  );

  return BookingDirectLink.fromJson(data);
}, retry: (_, __) => null);

/// Provider che indica se c'è un errore bloccante per il direct link
final bookingDirectLinkBlockingErrorProvider = Provider<bool>((ref) {
  final linkSlug = ref.watch(bookingDirectLinkSlugProvider);
  if (linkSlug == null) return false;

  final directLinkAsync = ref.watch(bookingDirectLinkProvider);
  if (directLinkAsync.hasError) return true;

  final directLink = directLinkAsync.value;
  if (directLink == null) return false;

  final urlLocationId = ref.watch(urlLocationIdProvider);

  if (directLink.isLocationScoped &&
      (urlLocationId == null ||
          urlLocationId <= 0 ||
          directLink.locationId <= 0 ||
          urlLocationId != directLink.locationId)) {
    return true;
  }

  if (directLink.isBusinessScoped &&
      urlLocationId != null &&
      urlLocationId > 0 &&
      !directLink.compatibleLocationIds.contains(urlLocationId)) {
    return true;
  }

  if (directLink.isBusinessScoped && directLink.compatibleLocationIds.isEmpty) {
    return true;
  }

  return false;
});

/// Provider che indica se il direct link è in risoluzione
final bookingDirectLinkIsResolvingProvider = Provider<bool>((ref) {
  final linkSlug = ref.watch(bookingDirectLinkSlugProvider);
  if (linkSlug == null) return false;

  final directLinkAsync = ref.watch(bookingDirectLinkProvider);
  return directLinkAsync.isLoading;
});
