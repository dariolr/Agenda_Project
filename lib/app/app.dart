import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      themeMode: ThemeMode.system,
      theme: buildTheme(themeConfig, Brightness.light),
      darkTheme: buildTheme(themeConfig, Brightness.light),
      routerConfig: appRouter,
    );
  }
}
