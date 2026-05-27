// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import '/core/environment/app_environment_config.dart';
import '/core/models/whatsapp_embedded_signup_launch_result.dart';

Future<WhatsappEmbeddedSignupLaunchResult> launchWhatsappEmbeddedSignup({
  required String expectedState,
}) async {
  final env = AppEnvironmentConfig.current;
  final appId = env.metaAppId.trim();
  final redirectUri = env.metaEmbeddedSignupRedirectUri.trim();
  final graphVersion = env.metaGraphVersion.trim();
  final scopes = env.metaEmbeddedSignupScopes.trim();

  if (appId.isEmpty || redirectUri.isEmpty) {
    throw StateError(
      'META_APP_ID o META_EMBEDDED_SIGNUP_REDIRECT_URI non configurati nel frontend.',
    );
  }

  final oauthUri =
      Uri.https('www.facebook.com', '/$graphVersion/dialog/oauth', {
        'client_id': appId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': scopes,
        'state': expectedState,
      });

  final popup =
      html.window.open(
            oauthUri.toString(),
            'meta_whatsapp_embedded_signup',
            'width=640,height=760',
          )
          as html.WindowBase?;

  if (popup == null) {
    throw StateError(
      'Impossibile aprire la finestra Meta (popup bloccato dal browser).',
    );
  }

  final completer = Completer<WhatsappEmbeddedSignupLaunchResult>();
  Timer? timer;
  Timer? timeout;
  StreamSubscription<html.MessageEvent>? messageSubscription;
  final expectedOrigin = Uri.parse(redirectUri).origin;

  void cleanup() {
    timer?.cancel();
    timeout?.cancel();
    messageSubscription?.cancel();
  }

  void completeFromParams(Map<String, String> params) {
    if (completer.isCompleted) return;

    final error = params['error'] ?? params['error_reason'];
    if (error != null && error.isNotEmpty) {
      cleanup();
      popup.close();
      completer.completeError(
        StateError('Meta ha restituito un errore: $error'),
      );
      return;
    }

    final code = (params['code'] ?? '').trim();
    final returnedState = (params['state'] ?? '').trim();
    if (code.isEmpty) {
      cleanup();
      popup.close();
      completer.completeError(
        StateError('Code non presente nel callback Meta.'),
      );
      return;
    }
    if (returnedState.isEmpty || returnedState != expectedState) {
      cleanup();
      popup.close();
      completer.completeError(
        StateError('State non valido nel callback Meta.'),
      );
      return;
    }

    cleanup();
    popup.close();
    completer.complete(
      WhatsappEmbeddedSignupLaunchResult(code: code, state: returnedState),
    );
  }

  messageSubscription = html.window.onMessage.listen((event) {
    if (event.origin != expectedOrigin) return;

    final data = event.data;
    if (data is! String) return;

    final decoded = jsonDecode(data);
    if (decoded is! Map) return;
    if (decoded['type'] != 'meta_whatsapp_embedded_signup_callback') return;

    completeFromParams({
      'code': decoded['code']?.toString() ?? '',
      'state': decoded['state']?.toString() ?? '',
      'error': decoded['error']?.toString() ?? '',
    });
  });

  timeout = Timer(const Duration(minutes: 10), () {
    if (completer.isCompleted) return;
    cleanup();
    try {
      popup.close();
    } catch (_) {}
    completer.completeError(
      StateError('Timeout durante il completamento della connessione Meta.'),
    );
  });

  timer = Timer.periodic(const Duration(milliseconds: 400), (_) {
    if (completer.isCompleted) return;

    try {
      if (popup.closed == true) {
        cleanup();
        completer.completeError(
          StateError('Popup chiuso prima del completamento.'),
        );
        return;
      }

      final href = popup.location.toString();
      if (href.isEmpty) {
        return;
      }

      if (!href.startsWith(redirectUri)) {
        return;
      }

      final uri = Uri.parse(href);
      final params = <String, String>{
        ...uri.queryParameters,
        ..._fragmentToParams(uri.fragment),
      };

      completeFromParams(params);
    } catch (_) {
      // Cross-origin while in Meta flow is expected.
      // If popup has been closed, terminate immediately instead of waiting timeout.
      try {
        if (popup.closed == true) {
          cleanup();
          completer.completeError(
            StateError('Popup chiuso prima del completamento.'),
          );
        }
      } catch (_) {}
    }
  });

  return completer.future;
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
