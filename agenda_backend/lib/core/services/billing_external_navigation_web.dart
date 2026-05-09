// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';

const _flagKey = 'billingExternalNavigationInProgress';
const _timestampKey = 'billingExternalNavigationStartedAt';
const _routeKey = 'billingExternalNavigationRoute';

void markBillingExternalNavigation({String? route}) {
  final storage = html.window.localStorage;
  storage[_flagKey] = 'true';
  storage[_timestampKey] = DateTime.now().millisecondsSinceEpoch.toString();
  if (route != null) {
    storage[_routeKey] = route;
  }
}

bool consumeBillingExternalNavigation() {
  final storage = html.window.localStorage;
  if (storage[_flagKey] != 'true') {
    return false;
  }

  storage.remove(_flagKey);
  storage.remove(_timestampKey);
  storage.remove(_routeKey);
  return true;
}

void resetBillingExternalNavigationViewport() {
  _resetViewport();
  if (_isStandaloneIosPwa()) {
    Future<void>.delayed(const Duration(milliseconds: 150), _resetViewport);
    Future<void>.delayed(const Duration(milliseconds: 300), _resetViewport);
  }
}

VoidCallback listenBillingExternalNavigationReturn(VoidCallback onReturn) {
  final subscriptions = <StreamSubscription<dynamic>>[
    html.window.onFocus.listen((_) => onReturn()),
    html.window.onPageShow.listen((_) => onReturn()),
    html.document.onVisibilityChange.listen((_) {
      if (html.document.visibilityState == 'visible') {
        onReturn();
      }
    }),
  ];

  return () {
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
  };
}

void _resetViewport() {
  html.window.scrollTo(0, 0);
  html.document.documentElement?.scrollTop = 0;
  html.document.body?.scrollTop = 0;

  // Force WebKit/Chromium PWA to recalculate viewport metrics after returning
  // from an external page without changing global app layout.
  final height = html.window.visualViewport?.height;
  if (height != null) {
    html.document.documentElement?.style.setProperty(
      '--billing-viewport-height',
      '${height}px',
    );
  }
  html.window.dispatchEvent(html.Event('resize'));
}

bool _isStandaloneIosPwa() {
  final userAgent = html.window.navigator.userAgent.toLowerCase();
  final isIos =
      userAgent.contains('iphone') ||
      userAgent.contains('ipad') ||
      userAgent.contains('ipod');
  final isStandalone = html.window
      .matchMedia('(display-mode: standalone)')
      .matches;

  return isIos && isStandalone;
}
