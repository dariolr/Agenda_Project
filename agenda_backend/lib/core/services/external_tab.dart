import 'external_tab_stub.dart'
    if (dart.library.html) 'external_tab_web.dart'
    as impl;

Object? openPendingExternalTab() => impl.openPendingExternalTab();

Future<void> navigatePendingExternalTab(Object? tab, String url) {
  return impl.navigatePendingExternalTab(tab, url);
}
