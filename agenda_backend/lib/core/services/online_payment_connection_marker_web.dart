// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;

const _markerTtl = Duration(minutes: 15);

String _key(int businessId) {
  return 'agenda_online_payments_connection_started_$businessId';
}

void markOnlinePaymentConnectionStarted(int businessId) {
  html.window.localStorage[_key(businessId)] = DateTime.now()
      .millisecondsSinceEpoch
      .toString();
}

bool hasOnlinePaymentConnectionStarted(int businessId) {
  final rawValue = html.window.localStorage[_key(businessId)];
  if (rawValue == null) return false;

  final createdAt = int.tryParse(rawValue);
  if (createdAt == null) {
    clearOnlinePaymentConnectionStarted(businessId);
    return false;
  }

  final age = DateTime.now().difference(
    DateTime.fromMillisecondsSinceEpoch(createdAt),
  );
  if (age > _markerTtl) {
    clearOnlinePaymentConnectionStarted(businessId);
    return false;
  }

  return true;
}

void clearOnlinePaymentConnectionStarted(int businessId) {
  html.window.localStorage.remove(_key(businessId));
}
