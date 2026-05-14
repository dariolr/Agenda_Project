import 'online_payment_connection_marker_stub.dart'
    if (dart.library.html) 'online_payment_connection_marker_web.dart'
    as impl;

void markOnlinePaymentConnectionStarted(int businessId) {
  impl.markOnlinePaymentConnectionStarted(businessId);
}

bool hasOnlinePaymentConnectionStarted(int businessId) {
  return impl.hasOnlinePaymentConnectionStarted(businessId);
}

void clearOnlinePaymentConnectionStarted(int businessId) {
  impl.clearOnlinePaymentConnectionStarted(businessId);
}
