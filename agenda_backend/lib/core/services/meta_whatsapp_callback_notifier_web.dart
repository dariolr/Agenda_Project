// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

void notifyMetaWhatsappCallback() {
  final uri = Uri.base;
  final params = <String, String>{
    ...uri.queryParameters,
    ..._fragmentToParams(uri.fragment),
  };

  final message = jsonEncode({
    'type': 'meta_whatsapp_embedded_signup_callback',
    'code': (params['code'] ?? '').trim(),
    'state': (params['state'] ?? '').trim(),
    'error': (params['error'] ?? params['error_reason'] ?? '').trim(),
  });

  html.window.opener?.postMessage(message, html.window.location.origin);

  Timer(const Duration(milliseconds: 250), () {
    html.window.close();
  });
}

Map<String, String> _fragmentToParams(String fragment) {
  if (fragment.isEmpty) return const <String, String>{};
  final map = <String, String>{};
  for (final item in fragment.split('&')) {
    if (item.isEmpty) continue;
    final pair = item.split('=');
    final key = Uri.decodeQueryComponent(pair.first);
    final value = pair.length > 1
        ? Uri.decodeQueryComponent(pair.sublist(1).join('='))
        : '';
    map[key] = value;
  }
  return map;
}
