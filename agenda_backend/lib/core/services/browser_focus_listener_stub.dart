typedef BrowserFocusSubscription = void Function();

BrowserFocusSubscription addBrowserFocusListener(void Function() onFocus) {
  return () {};
}
