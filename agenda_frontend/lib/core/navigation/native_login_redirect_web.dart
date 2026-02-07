// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void redirectToNativeLoginImpl({required String slug, String? from}) {
  final queryParameters = <String, String>{
    'slug': slug,
    if (from != null && from.isNotEmpty) 'from': from,
  };
  final query = Uri(queryParameters: queryParameters).query;
  html.window.location.assign('/login.html?$query');
}
