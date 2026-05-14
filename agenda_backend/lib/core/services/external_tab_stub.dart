import 'package:url_launcher/url_launcher.dart';

Object? openPendingExternalTab() => null;

Future<void> navigatePendingExternalTab(Object? tab, String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
    throw StateError('Unable to open redirect URL.');
  }
}
