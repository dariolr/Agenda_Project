import 'dart:js_interop';

@JS('appVersion')
external JSString? get _appVersion;

/// Legge la versione dell'app definita in index.html.
/// Formato: YYYYMMDD-N (es. 20260117-1)
String getAppVersion() {
  try {
    final version = _appVersion;
    if (version != null) {
      return version.toDart;
    }
  } catch (_) {
    // Fallback se JS interop fallisce
  }
  return 'dev';
}
