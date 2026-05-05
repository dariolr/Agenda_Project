/// Centralized builder for booking URLs used by "Prenota di nuovo" CTAs.
///
/// Rules:
/// - Booking from Direct Link → preserves `location` and `link` query params
/// - Regular booking → preserves only `location` query param
/// - Preserves `lang` if provided
library;

/// Builds a booking URL for the "Prenota di nuovo" action.
///
/// [slug] is the business slug (e.g., "rlab").
/// [locationId] is the location ID.
/// [bookingDirectLinkSlug] if non-null, the booking was created via direct link.
/// [lang] optional language override.
String buildBookingUrl({
  required String slug,
  required int locationId,
  String? bookingDirectLinkSlug,
  String? lang,
}) {
  final params = StringBuffer('?location=$locationId');

  if (bookingDirectLinkSlug != null &&
      bookingDirectLinkSlug.trim().isNotEmpty) {
    params.write(
      '&link=${Uri.encodeQueryComponent(bookingDirectLinkSlug.trim())}',
    );
  }

  if (lang != null && lang.trim().isNotEmpty) {
    params.write('&lang=${Uri.encodeQueryComponent(lang.trim())}');
  }

  return '/$slug/booking$params';
}
