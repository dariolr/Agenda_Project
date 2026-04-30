
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void redirectToNativeLoginImpl({
  required String slug,
  String? from,
  Map<String, String> redirectQueryParameters = const {},
}) {
  final queryParameters = <String, String>{
    'slug': slug,
    if (from != null && from.isNotEmpty) 'from': from,
    ...redirectQueryParameters,
  };
  final query = Uri(queryParameters: queryParameters).query;
  html.window.location.assign('/login.html?$query');
}

