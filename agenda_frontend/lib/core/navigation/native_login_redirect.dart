
import 'native_login_redirect_stub.dart'
    if (dart.library.html) 'native_login_redirect_web.dart';

void redirectToNativeLogin({
  required String slug,
  String? from,
  Map<String, String> redirectQueryParameters = const {},
}) {
  redirectToNativeLoginImpl(
    slug: slug,
    from: from,
    redirectQueryParameters: redirectQueryParameters,
  );
}

