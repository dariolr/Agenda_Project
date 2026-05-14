// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;

void replaceBrowserUrl(String pathAndQuery) {
  html.window.history.replaceState(null, html.document.title, pathAndQuery);
}
