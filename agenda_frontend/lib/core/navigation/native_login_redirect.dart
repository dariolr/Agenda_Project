import 'native_login_redirect_stub.dart'
    if (dart.library.html) 'native_login_redirect_web.dart';

void redirectToNativeLogin({required String slug, String? from}) {
  redirectToNativeLoginImpl(slug: slug, from: from);
}
