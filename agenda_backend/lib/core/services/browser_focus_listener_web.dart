// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;

typedef BrowserFocusSubscription = void Function();

BrowserFocusSubscription addBrowserFocusListener(void Function() onFocus) {
  final subscriptions = <StreamSubscription<dynamic>>[
    html.window.onFocus.listen((_) => onFocus()),
    html.document.onVisibilityChange.listen((_) {
      if (html.document.visibilityState == 'visible') {
        onFocus();
      }
    }),
  ];

  return () {
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
  };
}
