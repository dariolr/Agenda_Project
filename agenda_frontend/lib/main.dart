import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Usa path URL strategy invece di hash (#) per URL puliti
  // Es: /vamps/booking invece di /#/vamps/booking
  usePathUrlStrategy();

  runApp(const ProviderScope(child: App()));
}
