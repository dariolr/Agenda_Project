import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/l10n/l10_extension.dart';
import '/core/l10n/l10n.dart';
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

      // 💬 Titolo localizzato
      title: 'Agenda Platform',

      // 🧭 Navigazione
      routerConfig: appRouter,

      // 🎨 Tema dinamico
      themeMode: ThemeMode.system,
      theme: buildTheme(themeConfig, Brightness.light),
      darkTheme: buildTheme(themeConfig, Brightness.dark),

      // 🌍 Localizzazione
      localizationsDelegates: const [
        L10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: L10n.delegate.supportedLocales,

      // Lingua predefinita (puoi gestirla con Riverpod in futuro)
      locale: const Locale('it'),

      // 👁️ Imposta dinamicamente il titolo della finestra (Web/Desktop)
      builder: (context, child) {
        final localizedTitle = context.l10n.appTitle;
        return Title(
          title: localizedTitle,
          color: Colors.white,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
