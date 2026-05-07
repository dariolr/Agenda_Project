// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;

Future<void> redirectInCurrentTab(String url) async {
  html.window.location.assign(url);
}
