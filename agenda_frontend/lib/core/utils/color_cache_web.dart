// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

String? colorCacheGet(String key) {
  try { return html.window.localStorage[key]; } catch (_) { return null; }
}

void colorCacheSet(String key, String value) {
  try { html.window.localStorage[key] = value; } catch (_) {}
}
