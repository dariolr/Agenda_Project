import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/l10n.dart';
import '../core/utils/color_cache.dart';
import '../core/widgets/app_loading_screen.dart';
import '../core/widgets/environment_banner.dart';
import '../features/auth/domain/auth_state.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/booking/providers/business_provider.dart';
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
  Color? _lastBusinessColor;

  @override
  void initState() {
    super.initState();
    // Carica il colore dalla cache locale per evitare il flash al primo frame
    _lastBusinessColor = _loadCachedColor();
    // Timer di sicurezza: se l'auth non si risolve entro il timeout,
    // mostra comunque l'app per evitare loading infinito
    _timeoutTimer = Timer(const Duration(seconds: _authTimeoutSeconds), () {
      if (mounted) {
        setState(() => _authTimedOut = true);
      }
    });
  }

  Color? _loadCachedColor() {
    final segments = Uri.base.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;
    final slug = segments.first;
    if (_reservedPaths.contains(slug)) return null;
    return loadCachedBusinessColor(slug);
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
    final businessAsync = ref.watch(currentBusinessProvider);
    final businessColor = businessAsync.value?.primaryColor;
    if (businessColor != null && businessColor != _lastBusinessColor) {
      _lastBusinessColor = businessColor;
      // Persiste il colore per il prossimo caricamento
      final segments = Uri.base.pathSegments
          .where((s) => s.isNotEmpty)
          .toList();
      if (segments.isNotEmpty && !_reservedPaths.contains(segments.first)) {
        saveCachedBusinessColor(segments.first, businessColor);
      }
    }
    final effectiveConfig = _lastBusinessColor != null
        ? themeConfig.copyWith(seedColor: _lastBusinessColor!)
        : themeConfig;
    final theme = buildTheme(effectiveConfig, effectiveConfig.brightness);

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
        if (authResolving) {
          return const AppLoadingScreen();
        }
        return Column(
          children: [
            const EnvironmentBanner(),
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        );
      },
    );
  }
}

/// Path riservati che NON sono slug di business (stessa lista del router)
const _reservedPaths = {
  'reset-password',
  'login',
  'register',
  'booking',
  'my-bookings',
  'change-password',
  'profile',
  'privacy',
  'terms',
  'login.html',
};
