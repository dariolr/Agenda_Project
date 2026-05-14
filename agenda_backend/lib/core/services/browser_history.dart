import 'browser_history_stub.dart'
    if (dart.library.html) 'browser_history_web.dart'
    as impl;

void replaceBrowserUrl(String pathAndQuery) {
  impl.replaceBrowserUrl(pathAndQuery);
}
