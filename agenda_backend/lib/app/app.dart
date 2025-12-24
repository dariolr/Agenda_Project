import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/l10n/l10_extension.dart';
import '/core/l10n/l10n.dart';
// 1. Importa il listener dalla sua nuova posizione (se non l'hai già spostato)
// Assicurati che il percorso sia corretto.
import '../core/widgets/layout_config_auto_listener.dart';
import 'router.dart';
import 'theme/theme.dart';
import 'theme/theme_provider.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeConfig = ref.watch(themeNotifierProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Agenda Platform',
      routerConfig: appRouter,
      themeMode: ThemeMode.light,
      theme: buildTheme(themeConfig, Brightness.light),
      localizationsDelegates: const [
        L10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: L10n.delegate.supportedLocales,
      locale: const Locale('it'),

      // 2. SPOSTA IL LISTENER QUI
      builder: (context, child) {
        final localizedTitle = context.l10n.appTitle;
        return Title(
          title: localizedTitle,
          color: Theme.of(context).scaffoldBackgroundColor,
          // Questo widget ora aggiornerà i provider globali
          // prima che qualsiasi schermata venga costruita.
          child: LayoutConfigAutoListener(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
