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
  final configId = env.metaEmbeddedSignupConfigId.trim();
  final graphVersion = env.metaGraphVersion.trim();
  final scopes = env.metaEmbeddedSignupScopes.trim();

  if (appId.isEmpty || redirectUri.isEmpty || configId.isEmpty) {
    throw StateError(
      'META_APP_ID, META_EMBEDDED_SIGNUP_REDIRECT_URI o '
      'META_EMBEDDED_SIGNUP_CONFIG_ID non configurati nel frontend.',
    );
  }

  final oauthUri = Uri.https(
    'www.facebook.com',
    '/$graphVersion/dialog/oauth',
    {
      'client_id': appId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'override_default_response_type': 'true',
      'config_id': configId,
      'extras': jsonEncode({
        'setup': <String, String>{},
        'featureType': '',
        'sessionInfoVersion': '3',
      }),
      'scope': scopes,
      'state': expectedState,
    },
  );

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
  int? sessionInfoVersion;
  String? wabaId;
  String? phoneNumberId;
  String? displayPhoneNumber;

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
      WhatsappEmbeddedSignupLaunchResult(
        code: code,
        state: returnedState,
        sessionInfoVersion: sessionInfoVersion,
        wabaId: wabaId,
        phoneNumberId: phoneNumberId,
        displayPhoneNumber: displayPhoneNumber,
      ),
    );
  }

  messageSubscription = html.window.onMessage.listen((event) {
    final data = event.data;
    if (data is! String) return;

    final dynamic decoded;
    try {
      decoded = jsonDecode(data);
    } catch (_) {
      return;
    }
    if (decoded is! Map) return;

    if (event.origin == expectedOrigin &&
        decoded['type'] == 'meta_whatsapp_embedded_signup_callback') {
      completeFromParams({
        'code': decoded['code']?.toString() ?? '',
        'state': decoded['state']?.toString() ?? '',
        'error': decoded['error']?.toString() ?? '',
      });
      return;
    }

    if (!_isMetaOrigin(event.origin) ||
        decoded['type'] != 'WA_EMBEDDED_SIGNUP' ||
        decoded['event'] != 'FINISH') {
      return;
    }

    final sessionData = decoded['data'];
    if (sessionData is! Map) return;

    wabaId = _nonEmptyString(sessionData['waba_id']);
    phoneNumberId = _nonEmptyString(sessionData['phone_number_id']);
    displayPhoneNumber = _nonEmptyString(sessionData['display_phone_number']);
    sessionInfoVersion = int.tryParse(
      (decoded['version'] ?? sessionData['version'] ?? '').toString(),
    );
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

bool _isMetaOrigin(String origin) {
  final host = Uri.tryParse(origin)?.host.toLowerCase() ?? '';
  return host == 'facebook.com' || host.endsWith('.facebook.com');
}

String? _nonEmptyString(Object? value) {
  final normalized = value?.toString().trim() ?? '';
  return normalized.isEmpty ? null : normalized;
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
