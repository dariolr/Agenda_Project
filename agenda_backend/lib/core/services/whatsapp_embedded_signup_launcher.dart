import '/core/models/whatsapp_embedded_signup_launch_result.dart';
import 'whatsapp_embedded_signup_launcher_stub.dart'
    if (dart.library.html) 'whatsapp_embedded_signup_launcher_web.dart'
    as impl;

class WhatsappEmbeddedSignupLauncher {
  Future<WhatsappEmbeddedSignupLaunchResult> launch({
    required String expectedState,
  }) {
    return impl.launchWhatsappEmbeddedSignup(expectedState: expectedState);
  }
}
