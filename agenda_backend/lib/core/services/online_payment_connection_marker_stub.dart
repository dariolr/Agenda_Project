final Set<int> _startedConnections = <int>{};

void markOnlinePaymentConnectionStarted(int businessId) {
  _startedConnections.add(businessId);
}

bool hasOnlinePaymentConnectionStarted(int businessId) {
  return _startedConnections.contains(businessId);
}

void clearOnlinePaymentConnectionStarted(int businessId) {
  _startedConnections.remove(businessId);
}
