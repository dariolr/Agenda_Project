import 'browser_focus_listener_stub.dart'
    if (dart.library.html) 'browser_focus_listener_web.dart'
    as impl;

typedef BrowserFocusSubscription = void Function();

BrowserFocusSubscription addBrowserFocusListener(void Function() onFocus) {
  return impl.addBrowserFocusListener(onFocus);
}
