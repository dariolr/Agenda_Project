// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void redirectSameTabImpl(String url) {
  html.window.location.assign(url);
}
