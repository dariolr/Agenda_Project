import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/l10n.dart';
import '../core/widgets/app_loading_screen.dart';
import '../features/auth/domain/auth_state.dart';
import '../features/auth/providers/auth_provider.dart';
import 'router.dart';
import 'theme/theme.dart';
import 'theme/theme_provider.dart';

/// Timeout massimo per il loading iniziale (10 secondi)
/// Se l'auth non si risolve entro questo tempo, mostra comunque l'app
const _authTimeoutSeconds = 10;

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  bool _authTimedOut = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    // Timer di sicurezza: se l'auth non si risolve entro il timeout,
    // mostra comunque l'app per evitare loading infinito
    _timeoutTimer = Timer(const Duration(seconds: _authTimeoutSeconds), () {
      if (mounted) {
        debugPrint(
          'AUTH TIMEOUT: forcing loading dismissal after ${_authTimeoutSeconds}s',
        );
        setState(() => _authTimedOut = true);
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final router = ref.watch(routerProvider);
    final themeConfig = ref.watch(themeNotifierProvider);
    final theme = buildTheme(themeConfig, themeConfig.brightness);

    // Mostra loading globale finché auth non è risolto
    // (initial = primo avvio, loading = restore session o auto-login in corso)
    // Ma non oltre il timeout di sicurezza
    final authResolving =
        !_authTimedOut &&
        (authState.status == AuthStatus.initial ||
            authState.status == AuthStatus.loading);

    return MaterialApp.router(
      title: 'Agenda Booking',
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: router,
      localizationsDelegates: [
        L10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: L10n.delegate.supportedLocales,
      locale: const Locale('it'),
      builder: (context, child) {
        // Se auth ancora in risoluzione, mostra loading globale
        // che copre tutto (stessa grafica di index.html)
        if (authResolving) {
          return const AppLoadingScreen();
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
