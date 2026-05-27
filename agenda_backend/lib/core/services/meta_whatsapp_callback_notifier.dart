import 'meta_whatsapp_callback_notifier_stub.dart'
    if (dart.library.html) 'meta_whatsapp_callback_notifier_web.dart'
    as impl;

void notifyMetaWhatsappCallback() {
  impl.notifyMetaWhatsappCallback();
}
