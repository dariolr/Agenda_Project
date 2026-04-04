import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/l10n/l10_extension.dart';
import '/core/l10n/locale_resolution.dart';
import '/core/l10n/l10n.dart';
import '/core/widgets/environment_banner.dart';
import '../core/widgets/layout_config_auto_listener.dart';
import '../core/widgets/session_expired_listener.dart';
import 'providers/app_locale_provider.dart';
import 'router_provider.dart';
import 'theme/theme.dart';
import 'theme/theme_provider.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeConfig = ref.watch(themeNotifierProvider);
    final router = ref.watch(routerProvider);
    final appLocale = ref.watch(appLocaleProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Agenda Platform',
      routerConfig: router,
      themeMode: ThemeMode.light,
      theme: buildTheme(themeConfig, Brightness.light),
      localizationsDelegates: const [
        L10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: L10n.delegate.supportedLocales,
      locale: appLocale,
      localeResolutionCallback: (locale, supportedLocales) {
        return resolveSupportedLocale(
          locale,
          supportedLocales: supportedLocales,
        );
      },

      // 2. SPOSTA IL LISTENER QUI
      builder: (context, child) {
        final localizedTitle = context.l10n.appTitle;
        return Title(
          title: localizedTitle,
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Stack(
            children: [
              // Questo widget aggiorna i provider globali
              // prima che qualsiasi schermata venga costruita.
              SessionExpiredListener(
                child: LayoutConfigAutoListener(
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
              const EnvironmentBanner(),
            ],
          ),
        );
      },
    );
  }
}
