import 'package:flutter/foundation.dart';

import 'billing_external_navigation_stub.dart'
    if (dart.library.html) 'billing_external_navigation_web.dart'
    as impl;

void markBillingExternalNavigation({String? route}) {
  impl.markBillingExternalNavigation(route: route);
}

bool consumeBillingExternalNavigation() {
  return impl.consumeBillingExternalNavigation();
}

void resetBillingExternalNavigationViewport() {
  impl.resetBillingExternalNavigationViewport();
}

VoidCallback listenBillingExternalNavigationReturn(VoidCallback onReturn) {
  return impl.listenBillingExternalNavigationReturn(onReturn);
}
