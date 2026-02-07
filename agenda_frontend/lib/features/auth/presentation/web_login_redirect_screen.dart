import 'package:flutter/material.dart';

import '../../../core/navigation/native_login_redirect.dart';

class WebLoginRedirectScreen extends StatefulWidget {
  const WebLoginRedirectScreen({super.key, required this.slug, this.from});

  final String slug;
  final String? from;

  @override
  State<WebLoginRedirectScreen> createState() => _WebLoginRedirectScreenState();
}

class _WebLoginRedirectScreenState extends State<WebLoginRedirectScreen> {
  bool _redirectStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_redirectStarted) return;
    _redirectStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      redirectToNativeLogin(slug: widget.slug, from: widget.from);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
