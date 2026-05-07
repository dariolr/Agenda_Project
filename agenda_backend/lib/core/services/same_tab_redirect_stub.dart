import 'package:url_launcher/url_launcher.dart';

Future<void> redirectInCurrentTab(String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
    throw StateError('Unable to open redirect URL.');
  }
}
