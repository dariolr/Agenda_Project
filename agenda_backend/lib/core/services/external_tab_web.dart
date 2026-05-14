// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;

Object? openPendingExternalTab() {
  return html.window.open('', '_blank');
}

Future<void> navigatePendingExternalTab(Object? tab, String url) async {
  if (tab is html.WindowBase) {
    tab.location.href = url;
    return;
  }
  html.window.open(url, '_blank');
}
